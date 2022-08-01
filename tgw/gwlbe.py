#!env python3
import base64
import botocore
import boto3
import copy
import json
from lxml import etree
from lxml.builder import E 
from panos.panorama import Panorama, DeviceGroup
import requests
import re
import sys

import urllib3
urllib3.disable_warnings(urllib3.exceptions.InsecureRequestWarning)


#pip install pan-os-python

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

def getEndpointMappings(serials):
    params = copy.copy(base_params)
    r = etree.Element('show')
    s = etree.SubElement(r, 'plugins')
    s = etree.SubElement(s, 'vm_series')
    s = etree.SubElement(s, 'aws')
    s = etree.SubElement(s, 'gwlb')
    params['cmd'] = etree.tostring(r)
    for s in serials:
        params['target'] = s
        print(requests.get(pano_base_url, params=params, verify=False).content)

def endpointMappingXML(pvpce, pinterface):
    r = etree.Element('request')
    s = etree.SubElement(r, 'plugins')
    s = etree.SubElement(s, 'vm_series')
    s = etree.SubElement(s, 'aws')
    s = etree.SubElement(s, 'gwlb')
    s = etree.SubElement(s, 'associate')
    vpce = etree.SubElement(s, 'vpc-endpoint')
    vpce.text = pvpce
    interface = etree.SubElement(s, 'interface')
    interface.text = pinterface
    #print(etree.tostring(r, pretty_print=True).decode())
    return etree.tostring(r)

def populateEndpointMappings(serials, mappings):
    params = copy.copy(base_params)
    if len(serials)==0:
      print("No connected serials found")
      return
    for s in serials:
        print("Populating vpce mappings on {}".format(s))
        for v in mappings:
          params['target'] = s
          params['cmd'] = endpointMappingXML(v, mappings[v])
          print(requests.get(pano_base_url, params=params, verify=False).content)


def firewalls():
    serials = getDGMembers("awsgwlbvmseries")
    #getSysInfo(serials)
    getEndpointMappings(serials)
    print()
    mappings = {
      'vpce-00000000000000001': 'ethernet1/1.1',
      'vpce-00000000000000002': 'ethernet1/1.2',
      'vpce-00000000000000003': 'ethernet1/1.1',
      'vpce-00000000000000004': 'ethernet1/1.2',
      'vpce-00000000000000005': 'ethernet1/1.1',
      'vpce-006cae7779c3741b1': 'ethernet1/1.2',
      'vpce-0de7c14af8a7192b9': 'ethernet1/1.1',
    }
    populateEndpointMappings(serials, mappings)
    print()
    getEndpointMappings(serials)

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



if __name__ == '__main__':
    sys.exit(main())
