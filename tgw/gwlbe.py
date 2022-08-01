#!env python3
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

# 1. query vpce on aws, get zone from tag
# 2. query panorama and gets the zone to interface mapping
# 3. map the vpce via zone to interface
# 4. update the launch template with vpce mappings for the new firewalls
# 5. get the existing / connected fws from panorama
# 6. update the existing firewalls with the vpce mappings

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
    devices = etree.fromstring(requests.get(pano_base_url, params=params, verify=False).content)
    for device in devices.findall('.//devices/'):
        serial = device.find('serial').text
        connected = device.find('connected').text
        if connected=="no":
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

def parseShowPluginsVmseriesAwsGwlb(txt):
  sm = 0
  mappings = {}
  for l in txt.splitlines():
      if "GWLB enabled" in l:
          if not "True" in l:
            print("WARNING: GWLB not enabled")
          continue
      if "VPC endpoint" in l:
          sm = 1
          continue
      if sm !=1:
        continue
      rm = re.match(r'\s+(vpce-[a-f0-9]+)\s+(ethernet.*[0-9])\s*$', l)
      if rm:
        mappings[rm.group(1)] = rm.group(2)
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
    if not xml_resp.attrib.get('status')=='success':
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
    if not xml_resp.attrib.get('status')=='success':
        print("Failed to create mapping {} {} on {}".format(vpce, interface, serial))
        print(resp)
        return False
    return True

def deleteVpceMappingFromFirewall(serial, vpce, interface):
    params = copy.copy(base_params)
    params['target'] = serial
    params['cmd'] = endpointMappingXML(vpce, interface, False)
    resp = requests.get(pano_base_url, params=params, verify=False).content
    xml_resp = etree.fromstring(resp)
    if not xml_resp.attrib.get('status')=='success':
        print("Failed to create mapping {} {} on {}".format(vpce, interface, serial))
        print(resp)
        return False
    return True

def manageVpceMappingsOnFirewall(serial, mappings):
    existing_mappings = getFirewallsExistingVpceMappings(serial)
    for v in mappings:
      if v in existing_mappings:
        if mappings[v]==existing_mappings[v]:
          continue
      if addVpceMappingToFirewall(serial, v, mappings[v]):
        print("Created mapping {} {}".format(v, mappings[v]))
    for v in existing_mappings:
      if v in mappings:
        continue
      print("Firewall has extra mapping {}".format(v))
      if deleteVpceMappingFromFirewall(serial, v, existing_mappings[v]):
        print("Removed mapping {} {}".format(v, existing_mappings[v]))

def manageVpceMappingsOnActiveFirewalls(serials, mappings):
    if len(serials)==0:
      print("No connected serials found")
      return
    for s in serials:
        print("Populating vpce mappings on {}".format(s))
        manageVpceMappingsOnFirewall(s, mappings)

def addVpceMappingsToLaunchTemplate(ltn, mappings):
    lt_po = 'plugin-op-commands=panorama-licensing-mode-on,aws-gwlb-inspect:enable'
    client = boto3.client('ec2', region_name=region)
    di = client.describe_launch_template_versions(LaunchTemplateName=ltn,
      Versions=['$Latest'])
    for v in di.get('LaunchTemplateVersions'):
      latest_ver = v.get('VersionNumber')
      ud = v.get('LaunchTemplateData').get('UserData')
      lt = base64.b64decode(ud).decode()
    nlt = ''
    for l in lt.splitlines():
      m = re.match(r'plugin-op-commands.*', l)
      if m:
        nlt+= lt_po
        for v in mappings:
          nlt+= ',aws-gwlb-associate-vpce:{}@{}'.format(v, mappings[v])
        nlt+= '\n'
      else:
        nlt+= l + '\n'
    di = client.create_launch_template_version(LaunchTemplateName=ltn,
      LaunchTemplateData={'UserData':base64.b64encode(nlt.encode()).decode()},
      SourceVersion=str(latest_ver))
    v = di.get('LaunchTemplateVersion').get('VersionNumber')
    print("set new version to: {}".format(v))
    client.modify_launch_template(LaunchTemplateName=ltn, DefaultVersion=str(v))

def getAwsVpce():
  client = boto3.client('ec2', region_name=region) 
  dv = client.describe_vpc_endpoints()
  vpce_zone = {}
  for e in dv.get('VpcEndpoints'):
    if e.get('VpcEndpointType')!='GatewayLoadBalancer':
      continue
    vpce = e.get('VpcEndpointId')
    for t in e.get('Tags'):
      if t['Key']=='pan_zone':
        zone = t['Value']
        vpce_zone[vpce] = zone
        break
    else:
      print("Did not find zone tag for {}".format(vpce))
  return vpce_zone

def getPanoramaZoneInterfaceMapping(template):
  p = "/config/devices/entry[@name='localhost.localdomain']/"
  p+= "template/entry[@name='{}']/".format(template)
  p+= "config/devices/entry[@name='localhost.localdomain']/"
  p+= "vsys/entry[@name='vsys1']"
  params = copy.copy(base_params)
  params['type'] = 'config'
  params['action'] = 'get'
  params['xpath'] = p
  r = etree.fromstring(requests.get(pano_base_url, params=params, verify=False).content)
  m = {}
  for z in r.findall('.//entry/zone/entry'):
    zone = z.attrib.get('name')
    for i in z.findall('./network/layer3/member'):
      interface = i.text
      m[zone] = interface
  return m

def createDummyEndpointMappings():
  mappings = {}
  for i in range(1,251):
    a = "vpce-{:>010}".format(i)
    if i%2==0:
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
      print("No interface with zone {} exist in panorama template for {}".format(z, vpce))
      continue
    endpoint_interface_mapping[vpce] = interface_zone_mapping[z]
  return endpoint_interface_mapping

def main():
  readConfiguration()
  #mappings = createDummyEndpointMappings()
  #getSysInfo(serials)
  endpoint_zone_mapping = getAwsVpce()
  interface_zone_mapping = getPanoramaZoneInterfaceMapping('aws-gwlb')
  ei = mapVpceToInterface(endpoint_zone_mapping, interface_zone_mapping)
  print(ei)
  addVpceMappingsToLaunchTemplate('m-mfw', ei)
  serials = getDGMembers("awsgwlbvmseries")
  manageVpceMappingsOnActiveFirewalls(serials, ei)



if __name__ == '__main__':
    sys.exit(main())
