#!env python3
import argparse
import base64
import botocore
import boto3
import copy
import json
from lxml import etree
from lxml.builder import E
import requests
import re
import sys
import time

import urllib3

urllib3.disable_warnings(urllib3.exceptions.InsecureRequestWarning)

region = 'eu-central-1'

base_params = {
    'key': '',
    'type': 'op',
}
pano_base_url = 'https://{}/api/'.format('dummy')


def formatClientError(e):
    s = ""
    s += " code: {}\n".format(e.response['Error']['Code'])
    s += " msg: {}\n".format(e.response['Error']['Message'])
    s += " request ID: {}".format(e.response['ResponseMetadata']['RequestId'])
    return s

def getDGMembers(dg):
    params = copy.copy(base_params)
    r = etree.Element('show')
    s = etree.SubElement(r, 'devicegroups')
    s = etree.SubElement(s, 'name')
    s.text = dg
    params['cmd'] = etree.tostring(r)
    serials = []
    devices = etree.fromstring(
        requests.get(pano_base_url, params=params, verify=False).content)
    for device in devices.findall('.//devices/'):
        serial = device.find('serial').text
        connected = device.find('connected').text
        if connected == "no":
            continue
        serials.append(serial)
    return serials


def getSysInfo(serials):
    params = copy.copy(base_params)
    r = etree.Element('show')
    s = etree.SubElement(r, 'system')
    s = etree.SubElement(s, 'info')
    params['cmd'] = etree.tostring(r)
    for s in serials:
        params['target'] = s
        print(requests.get(pano_base_url, params=params, verify=False).content)


def fixVpceId(vpceid):
    rm = re.match(r'vpce-([a-f0-9]+)', vpceid)
    vpce_no = int(rm.group(1), 16)
    vpcex = format(vpce_no, '#019x')
    vpce = 'vpce-' + vpcex[2:]
    return vpce


def parseShowPluginsVmseriesAwsGwlb(txt):
    sm = 0
    mappings = {}
    for l in txt.splitlines():
        if "GWLB enabled" in l:
            if not "True" in l:
                print("WARNING: GWLB not enabled, mappings cannot be verified")
                return None
            continue
        if "VPC endpoint" in l:
            sm = 1
            continue
        if sm != 1:
            continue
        rm = re.match(r'\s+(vpce-[a-f0-9]+)\s+(ethernet.*[0-9])\s*$', l)
        if rm:
            vpce = fixVpceId(rm.group(1))
            mappings[vpce] = rm.group(2)
    return mappings

def parseShowPluginsVmseriesAwsGwlbXML(xml):
    mappings = {}
    try:
        enabled = xml.findtext('enabled')
        if enabled!="True":
            print("WARNING: GWLB not enabled, mappings cannot be verified")
            return None
    except:
        print(etree.tostring(xml, pretty_print=True).decode())
        raise Exception("ERROR: GWLB status unknown")
    for v in xml.findall('./vpc-endpoints/vpc-endpoint'):
        eid = v.find('id').text
        interface = v.find('interface').text
        if 'vpce' in interface:
            # workaround as we can randomly swap vpce and interface
            interface,eid = eid,interface
        eid = fixVpceId(eid)
        mappings[eid] = interface
    return mappings


def getFirewallsExistingVpceMappings(serial):
    """
    Returns:
        - dictionary endpoint-interface pairs or None if gwlb is not enabled on firewall
    """
    params = copy.copy(base_params)
    r = etree.Element('show')
    s = etree.SubElement(r, 'plugins')
    s = etree.SubElement(s, 'vm_series')
    s = etree.SubElement(s, 'aws')
    s = etree.SubElement(s, 'gwlb')
    params['cmd'] = etree.tostring(r)
    params['target'] = serial
    resp = requests.get(pano_base_url, params=params, verify=False).content
    xml_resp = etree.fromstring(resp)
    if not xml_resp.attrib.get('status') == 'success':
        print(resp)
        raise Exception("Failed to get mappings from {}".format(serial))
    if xml_resp.find('./result/vm_series') is not None:
        #print("Firewall with newer panos version")
        m = parseShowPluginsVmseriesAwsGwlbXML(xml_resp.find('./result/vm_series/aws/gwlb'))
    else:
        m = parseShowPluginsVmseriesAwsGwlb(xml_resp.find('./result').text)
    return m


def endpointMappingXML(pvpce, pinterface, associate):
    r = etree.Element('request')
    s = etree.SubElement(r, 'plugins')
    s = etree.SubElement(s, 'vm_series')
    s = etree.SubElement(s, 'aws')
    s = etree.SubElement(s, 'gwlb')
    if associate:
        s = etree.SubElement(s, 'associate')
    else:
        s = etree.SubElement(s, 'disassociate')
    vpce = etree.SubElement(s, 'vpc-endpoint')
    vpce.text = pvpce
    interface = etree.SubElement(s, 'interface')
    interface.text = pinterface
    #print(etree.tostring(r, pretty_print=True).decode())
    return etree.tostring(r)


def addVpceMappingToFirewall(serial, vpce, interface):
    params = copy.copy(base_params)
    params['target'] = serial
    params['cmd'] = endpointMappingXML(vpce, interface, True)
    resp = requests.get(pano_base_url, params=params, verify=False).content
    xml_resp = etree.fromstring(resp)
    if not xml_resp.attrib.get('status') == 'success':
        print("Failed to create mapping {} {} on {}".format(
            vpce, interface, serial))
        print(resp)
        return False
    return True


def deleteVpceMappingFromFirewall(serial, vpce, interface):
    params = copy.copy(base_params)
    params['target'] = serial
    params['cmd'] = endpointMappingXML(vpce, interface, False)
    resp = requests.get(pano_base_url, params=params, verify=False).content
    xml_resp = etree.fromstring(resp)
    if not xml_resp.attrib.get('status') == 'success':
        print("Failed to delete mapping {} {} on {}".format(
            vpce, interface, serial))
        print(resp)
        return False
    return True


def manageVpceMappingsOnFirewall(serial, mappings):
    existing_mappings = getFirewallsExistingVpceMappings(serial)
    if existing_mappings is None:
        # we might have not gotten mappings if gwlb is not enabled
        return
    for v in mappings:
        if v in existing_mappings:
            if mappings[v] == existing_mappings[v]:
                continue
        if addVpceMappingToFirewall(serial, v, mappings[v]):
            print("Created mapping {} {}".format(v, mappings[v]))
    for v in existing_mappings:
        if v in mappings:
            continue
        print("Firewall has extra mapping {}, remove it".format(v))
        deleteVpceMappingFromFirewall(serial, v, existing_mappings[v])


def manageVpceMappingsOnActiveFirewalls(serials, mappings):
    if len(serials) == 0:
        print("No connected serials found")
        return
    for s in serials:
        print("Verifying vpce mappings on {}".format(s))
        manageVpceMappingsOnFirewall(s, mappings)
        print("Done with {}".format(s))


def prepareNewLaunchTemplateString(old_launch_template, new_mappings):
    # this assumes plugin-op-commands must exist - gwlb inspection is enabled via bootstrap
    new_launch_template = ''
    found_pocs = False
    for ol in old_launch_template.splitlines():
        m = re.match(r'^plugin-op-commands=(.*)', ol)
        if not m:
            new_launch_template+= ol + '\n'
            continue
        found_pocs = True
        pocs = m[1]
        nl = 'plugin-op-commands='
        nle = []
        for oc in pocs.split(','):
            m = re.match(r'^aws-gwlb-associate-vpce:(.*)@(.*)', oc)
            if not m:
                nle.append(oc)
        for v in sorted(new_mappings):
            nle.append('aws-gwlb-associate-vpce:{}@{}'.format(v, new_mappings[v]))
        nl+= ','.join(nle)
        new_launch_template+= nl + '\n'
    if not found_pocs:
        raise Exception('plugin-op-commands not found in launch template')
    return new_launch_template


def manageVpceMappingsInLaunchTemplate(launch_template_name, mappings):
    client = boto3.client('ec2', region_name=region)
    try:
        di = client.describe_launch_template_versions(LaunchTemplateName=launch_template_name,
                                                    Versions=['$Latest'])
    except botocore.exceptions.ClientError as e:
        if e.response['Error']['Code']=='InvalidLaunchTemplateName.NotFoundException':
            print("Launch template {} does not exist".format(launch_template_name))
            sys.exit(1)
        print("Error describing AWS launch template: {}".format(launch_template_name))
        print(formatClientError(e))
        sys.exit(1)
    for v in di.get('LaunchTemplateVersions'):
        latest_ver = v.get('VersionNumber')
        ud = v.get('LaunchTemplateData').get('UserData')
        olt = base64.b64decode(ud).decode()

    nlt = prepareNewLaunchTemplateString(olt, mappings)
    if nlt==olt:
        print("Existing mappings/launch template are correct, update is not needed")
        return
    di = client.create_launch_template_version(LaunchTemplateName=launch_template_name,
                                               LaunchTemplateData={
                                                   'UserData':
                                                   base64.b64encode(
                                                       nlt.encode()).decode()
                                               },
                                               SourceVersion=str(latest_ver))
    v = di.get('LaunchTemplateVersion').get('VersionNumber')
    print("set new version to: {}".format(v))
    client.modify_launch_template(LaunchTemplateName=launch_template_name,
                                  DefaultVersion=str(v))


def waitForVPCE(vpces, vpc):
    client = boto3.client('ec2', region_name=region)
    i = 0
    vpce_filters = []
    if vpces:
        vpce_list = vpces.split(',')
        vpce_filters.append({
            'Name': 'vpc-endpoint-id', 
            'Values': vpce_list
            })
    if vpc:
        vpce_filters.append({
            'Name': 'vpc-id', 
            'Values': [vpc]
            })
    vpce_filters.append({
        'Name': 'vpc-endpoint-type',
        'Values': ['GatewayLoadBalancer']
    })

    while True:
        dv = client.describe_vpc_endpoints(Filters=vpce_filters)
        states = []
        if i>0:
            time.sleep(30)
        i += 1
        for e in dv.get('VpcEndpoints'):
            state = e.get('State')
            states.append(state)
        print("{} {}".format(i, states))
        if vpces and len(vpce_list)!=len(states):
            print("Not all endpoints exist yet, found {}".format(len(states)))
            if i>10:
                print("This was attempt #{} and not all endpoints were found, giving up".format(i))
                sys.exit(1)
            continue
        if all(s=='available' for s in states) and len(states) > 0:
            print("all endpoints available: {}".format(states))
            return


def getPanZoneFromSubnetTags(subnet_id):
    client = boto3.client('ec2', region_name=region)
    ds = client.describe_subnets(SubnetIds=[subnet_id])
    for t in ds.get('Subnets')[0].get('Tags'):
        if t['Key'] == 'pan_zone':
            zone = t['Value']
            return zone
    return None
    
def getAwsVpceToPanZone():
    client = boto3.client('ec2', region_name=region)
    dv = client.describe_vpc_endpoints()
    vpce_zone = {}
    for e in dv.get('VpcEndpoints'):
        if e.get('VpcEndpointType') != 'GatewayLoadBalancer':
            continue
        vpce = e.get('VpcEndpointId')
        for t in e.get('Tags'):
            if t['Key'] == 'pan_zone':
                zone = t['Value']
                vpce_zone[vpce] = zone
                break
        else:
            subnet_id = e.get('SubnetIds')[0]
            zone = getPanZoneFromSubnetTags(subnet_id)
            if zone:
                vpce_zone[vpce] = zone
            else:
                print("Did not find pan_zone on vpce or subnet {}".format(subnet_id))
    return vpce_zone


def getPanoramaZoneInterfaceMapping(template):
    p = "/config/devices/entry[@name='localhost.localdomain']/"
    p += "template/entry[@name='{}']/".format(template)
    p += "config/devices/entry[@name='localhost.localdomain']/"
    p += "vsys/entry[*]"
    params = copy.copy(base_params)
    params['type'] = 'config'
    params['action'] = 'get'
    params['xpath'] = p
    resp = requests.get(pano_base_url, params=params, verify=False).content
    xml_resp = etree.fromstring(resp)
    r = xml_resp.find('./result')
    if int(r.attrib.get('total-count')) == 0:
      raise Exception('Did not find template: {}'.format(template))
    m = {}
    for z in xml_resp.findall('.//entry/zone/entry'):
        zone = z.attrib.get('name')
        for i in z.findall('./network/layer3/member'):
            interface = i.text
            m[zone] = interface
    return m


def createDummyEndpointMappings():
    mappings = {}
    for i in range(1, 251):
        a = "vpce-{:>010}".format(i)
        if i % 2 == 0:
            mappings[a] = 'ethernet1/1.1'
        else:
            mappings[a] = 'ethernet1/1.2'
    return mappings


def readConfiguration():
    global pano_base_url
    with open("panorama_creds.json") as f:
        data = json.load(f)
        base_params["key"] = data["api_key"]
        pano_base_url = 'https://{}/api/'.format(data['hostname'])


def mapVpceToInterface(endpoint_zone_mapping, interface_zone_mapping):
    endpoint_interface_mapping = {}
    for vpce in endpoint_zone_mapping:
        z = endpoint_zone_mapping[vpce]
        if not z in interface_zone_mapping:
            print(
                "No interface with zone {} exist in panorama template for {}".
                format(z, vpce))
            continue
        endpoint_interface_mapping[vpce] = interface_zone_mapping[z]
    return endpoint_interface_mapping


def main():
    parser = argparse.ArgumentParser(description='Create vpce mappings on fw and launch template')
    parser.add_argument('--clean', action='store_true')
    parser.add_argument('--dg', default='aws-gwlb')
    parser.add_argument('--ts', default='aws-gwlb')
    parser.add_argument('--lt', default='m-mfw')
    parser.add_argument('--region', default='eu-central-1')
    parser.add_argument('--vpces')
    parser.add_argument('--vpc')
    parser.add_argument('cmd')
    args = parser.parse_args()

    global region
    region = args.region
    ei = {}
    readConfiguration()
    print(args.cmd)
    if args.cmd=="apply-vpce-map":
        if not args.clean:
            #getSysInfo(serials)
            # 1. query vpce on aws, get zone from tag
            endpoint_zone_mapping = getAwsVpceToPanZone()
            # 2. query panorama and gets the zone to interface mapping
            interface_zone_mapping = getPanoramaZoneInterfaceMapping(args.ts)
            # 3. map the vpce via zone to interface
            ei = mapVpceToInterface(endpoint_zone_mapping, interface_zone_mapping)
        print(ei)
        # 4. update the launch template with vpce mappings for the new firewalls
        manageVpceMappingsInLaunchTemplate(args.lt, ei)
        # 5. get the existing / connected fws from panorama
        serials = getDGMembers(args.dg)
        # 6. update the existing firewalls with the vpce mappings
        manageVpceMappingsOnActiveFirewalls(serials, ei)
        sys.exit(0)
    if args.cmd=="vpce-wait":
        waitForVPCE(args.vpces, args.vpc)
        sys.exit(0)
    print("Unknown command")
    sys.exit(1)


if __name__ == '__main__':
    sys.exit(main())
