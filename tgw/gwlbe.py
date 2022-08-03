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

import urllib3

urllib3.disable_warnings(urllib3.exceptions.InsecureRequestWarning)

region = 'eu-central-1'

base_params = {
    'key': '',
    'type': 'op',
}
pano_base_url = 'https://{}/api/'.format('dummy')


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


def vpceNoToVpceId(no):
    vpcex = format(no, '#019x')
    vpce = 'vpce-' + vpcex[2:]
    return vpce


def parseShowPluginsVmseriesAwsGwlb(txt):
    sm = 0
    mappings = {}
    for l in txt.splitlines():
        if "GWLB enabled" in l:
            if not "True" in l:
                print("WARNING: GWLB not enabled, mappings cannot be verified")
            continue
        if "VPC endpoint" in l:
            sm = 1
            continue
        if sm != 1:
            continue
        rm = re.match(r'\s+vpce-([a-f0-9]+)\s+(ethernet.*[0-9])\s*$', l)
        if rm:
            vpce_no = int(rm.group(1), 16)
            vpce = vpceNoToVpceId(vpce_no)
            mappings[vpce] = rm.group(2)
    return mappings


def getFirewallsExistingVpceMappings(serial):
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
        print("Failed to get mappings from {}".format(serial))
        print(resp)
        return {}
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


def manageVpceMappingsInLaunchTemplate(ltn, mappings):
    new_mappings_txt = 'plugin-op-commands=panorama-licensing-mode-on,aws-gwlb-inspect:enable'
    for v in sorted(mappings):
        new_mappings_txt += ',aws-gwlb-associate-vpce:{}@{}'.format(v, mappings[v])
    client = boto3.client('ec2', region_name=region)
    di = client.describe_launch_template_versions(LaunchTemplateName=ltn,
                                                  Versions=['$Latest'])
    for v in di.get('LaunchTemplateVersions'):
        latest_ver = v.get('VersionNumber')
        ud = v.get('LaunchTemplateData').get('UserData')
        lt = base64.b64decode(ud).decode()
    nlt = ''
    found_gwlb = False
    for l in lt.splitlines():
        m = re.match(r'plugin-op-commands.*', l)
        if m:
            if (l==new_mappings_txt):
              print("Existing mappings are correct, launch template update is not needed")
              return
            nlt += new_mappings_txt
            nlt += '\n'
            found_gwlb = True
        else:
            nlt += l + '\n'
    if not found_gwlb:
      nlt += new_mappings_txt
      nlt += '\n'
    di = client.create_launch_template_version(LaunchTemplateName=ltn,
                                               LaunchTemplateData={
                                                   'UserData':
                                                   base64.b64encode(
                                                       nlt.encode()).decode()
                                               },
                                               SourceVersion=str(latest_ver))
    v = di.get('LaunchTemplateVersion').get('VersionNumber')
    print("set new version to: {}".format(v))
    client.modify_launch_template(LaunchTemplateName=ltn,
                                  DefaultVersion=str(v))


def getAwsVpce():
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
            print("Did not find zone tag for {}".format(vpce))
    return vpce_zone


def getPanoramaZoneInterfaceMapping(template):
    p = "/config/devices/entry[@name='localhost.localdomain']/"
    p += "template/entry[@name='{}']/".format(template)
    p += "config/devices/entry[@name='localhost.localdomain']/"
    p += "vsys/entry[@name='vsys1']"
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
    args = parser.parse_args()

    ei = {}
    readConfiguration()
    if not args.clean:
        #getSysInfo(serials)
        # 1. query vpce on aws, get zone from tag
        endpoint_zone_mapping = getAwsVpce()
        # 2. query panorama and gets the zone to interface mapping
        interface_zone_mapping = getPanoramaZoneInterfaceMapping('aws-gwlb')
        # 3. map the vpce via zone to interface
        ei = mapVpceToInterface(endpoint_zone_mapping, interface_zone_mapping)
    print(ei)
    # 4. update the launch template with vpce mappings for the new firewalls
    manageVpceMappingsInLaunchTemplate('m-mfw', ei)
    # 5. get the existing / connected fws from panorama
    serials = getDGMembers("awsgwlbvmseries")
    # 6. update the existing firewalls with the vpce mappings
    manageVpceMappingsOnActiveFirewalls(serials, ei)


if __name__ == '__main__':
    sys.exit(main())
