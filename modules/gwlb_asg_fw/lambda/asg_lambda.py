import boto3
import botocore
import json
import os
from datetime import datetime

ec2_client = boto3.client('ec2')


def retrieve_and_associate_public_ip(network_interface_id, config):
    ipv4alloc = None
    if config['reuse_public_ips']:
        log("Reuse public ips enabled")
        public_ips_description = ec2_client.describe_addresses(Filters=[
                {
                    'Name'   : 'tag:deployment',
                    'Values' : [config['name']]
                },
        ])
        public_ips = public_ips_description['Addresses']
        print(public_ips)
        for pip in public_ips:
            if 'AssociationId' not in pip: 
                log(f"Found free public ip: {pip['PublicIp']}")
                ipv4alloc = pip
                break
        else:
            log("Did not find a free public ip for reuse")
    if config['reuse_public_ips']==False or ipv4alloc is None:
        ipv4alloc = ec2_client.allocate_address(
            Domain = 'vpc',
            TagSpecifications = [{
                'ResourceType': 'elastic-ip',
                'Tags': [{
                    'Key'   : 'deployment',
                    'Value' : config['name']
                }]
            }]
        )
        log(f"Allocated new public ip: {ipv4alloc['PublicIp']}")
    assert(ipv4alloc)
    log("Will use public ip {} for {}".format(ipv4alloc['PublicIp'], network_interface_id))

    ipv4assoc = ec2_client.associate_address(
        AllocationId=ipv4alloc['AllocationId'],
        NetworkInterfaceId=network_interface_id
    )
    log(f"Created public ip association: {network_interface_id} {ipv4assoc['AssociationId']}")
    return




def create_and_attach_network_interface(instance_id, device_index, subnet, i_cfg, config):
    # ipv6 prefix delegation
    ipv6_count = 0
    if config['ipv6']:
        ipv6_count = 1

    network_interface = ec2_client.create_network_interface(
            SubnetId = subnet,
            Groups = i_cfg['security_group_ids'],
            Description = subnet,
            Ipv6AddressCount = ipv6_count,
        )
    network_interface_id = network_interface['NetworkInterface']['NetworkInterfaceId']
    private_ip = network_interface['NetworkInterface']['PrivateIpAddress']
    log(f"Created network interface: index:{device_index} - {network_interface_id} {private_ip}")

    attach_interface = ec2_client.attach_network_interface(
            NetworkInterfaceId=network_interface_id,
            InstanceId=instance_id,
            DeviceIndex=device_index,
        )
    attachment_id = attach_interface['AttachmentId']
    log(f"Created attachment: {attachment_id}")

    mnia = ec2_client.modify_network_interface_attribute(
            Attachment={
                'AttachmentId': attachment_id,
                'DeleteOnTermination': True,
            },
            NetworkInterfaceId=network_interface_id,
        )

    if config['ipv6'] and device_index==2:
        aipv6a = ec2_client.assign_ipv6_addresses(
                NetworkInterfaceId=network_interface_id,
                Ipv6PrefixCount=1
            )
        log(f"Assigned ipv6 prefix: {aipv6a['AssignedIpv6Prefixes'][0]}")

    if i_cfg.get('associate_public_ip', False):
        log(f"Associating public ip for interface: index:{device_index} - {network_interface_id}")
        retrieve_and_associate_public_ip(network_interface_id, config)
    else:
        log(f"Not associating public ip for interface: index:{device_index} - {network_interface_id}")
    return



def disasocciate_public_ip(public_ip, config):
    public_ip_description = ec2_client.describe_addresses(PublicIps=[public_ip])['Addresses'][0]
    for t in public_ip_description['Tags']:
        if t['Key']=='deployment':
            deployment = t['Value']
            break
    else:
        log("WARNING: did not find deployment tag on public ip, not handling it")
        return
    log(f"Disassociating IP {public_ip}")
    ec2_client.disassociate_address(AssociationId=public_ip_description['AssociationId'])

    if config['reuse_public_ips']:
        log(f"Reuse public IPs enabled, not releasing {public_ip}")
        return
    if deployment!=config['name']:
        log(f"ERROR: public IP {public_ip} tagged with \"{deployment}\" - a different deployment than \"{config['name']}\", not releasing")
        return
    log(f"Releasing IP {public_ip}")
    ec2_client.release_address(AllocationId=public_ip_description['AllocationId'])



def complete_lifecycle(instance_id, event):
    asg_client = boto3.client('autoscaling')
    try:
        asg_client.complete_lifecycle_action(
                LifecycleHookName=event['detail']['LifecycleHookName'],
                AutoScalingGroupName=event['detail']['AutoScalingGroupName'],
                LifecycleActionToken=event['detail']['LifecycleActionToken'],
                LifecycleActionResult='CONTINUE',
            )
    except botocore.exceptions.ClientError as e:
        log("Error completing life cycle hook for instance {}: {}".format(
            instance_id, e.response['Error']['Code']))

    log(f"Completed-continue lifecyle: {instance_id} Event:{event['detail-type']} ")
    return




def handle_launch(instance_id, interfaces, config):
    instance_description = ec2_client.describe_instances(InstanceIds=[instance_id])
    instance = instance_description['Reservations'][0]['Instances'][0]
    instance_zone = instance['Placement']['AvailabilityZone']
    log("Handling Launch for {} in {}".format(instance_id, instance_zone))
    # log("Disabling source/destination check")
    # ec2_client.modify_instance_attribute(SourceDestCheck={'Value': False}, InstanceId=instance_id)

    for device_index in range(1, len(interfaces)):
        i_cfg = interfaces[str(device_index)]
        subnet = i_cfg['subnet_id'][instance_zone]
        log("Adding interface index:{} in subnet: {}".format(device_index, subnet))
        create_and_attach_network_interface(instance_id, device_index, subnet, i_cfg, config)

    log("Completed launch for {} in {}".format(instance_id, instance_zone))
    return



def handle_termination(instance_id, config):
    instance_description = ec2_client.describe_instances(InstanceIds=[instance_id])
    instance = instance_description['Reservations'][0]['Instances'][0]
    instance_zone = instance['Placement']['AvailabilityZone']
    log("Handling Termination for {} in {}".format(instance_id, instance_zone))

    for ni in instance['NetworkInterfaces']:
        device_index = ni['Attachment']['DeviceIndex']
        network_interface_id = ni['NetworkInterfaceId']
        private_ip = ni['PrivateIpAddress']
        log(f"Checking device_index: {device_index} {network_interface_id} {private_ip}")
        try:
            public_ip = ni['PrivateIpAddresses'][0]['Association']['PublicIp']
        except:
            log(f"No public IP found on device_index: {device_index} {network_interface_id} {private_ip}")
            continue
        log(f"Public IP {public_ip} found on device_index: {device_index} {network_interface_id} {private_ip}")
        disasocciate_public_ip(public_ip, config)

    log("Completed termination for {} in {}".format(instance_id, instance_zone))
    return



def lambda_handler(event, context):
    # log(event)
    # log(os.environ)
    if os.environ['interfaces']:
        interfaces = json.loads(os.environ['interfaces'])
    else:
        log("Empty Environment variable interfaces")
        exit(1)
    if os.environ['config']:
        config = json.loads(os.environ['config'])
    else:
        log("Empty Environment variable config")
        exit(1)
    log(interfaces)
    config.setdefault('ipv6', False)
    config.setdefault('reuse_public_ips', False)
    log(config)

    instance_id = event['detail']['EC2InstanceId']
    event_detail = event["detail-type"] 
    if event_detail == "EC2 Instance-launch Lifecycle Action":
        log(f"Instance: {instance_id} Event:{event_detail} - handling")
        handle_launch(instance_id, interfaces, config)
        complete_lifecycle(instance_id, event)
        return
    if event_detail == "EC2 Instance-terminate Lifecycle Action":
        log(f"Instance: {instance_id} Event:{event_detail} - handling")
        handle_termination(instance_id, config)
        complete_lifecycle(instance_id, event)
        return

    log(f"ERROR: Instance: {instance_id} Event:{event_detail} - unknown")
    return




def log(message):
    print('{}'.format(message))
