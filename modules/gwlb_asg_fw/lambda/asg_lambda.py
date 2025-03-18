import boto3
import botocore
import json
import os
from datetime import datetime

ec2_client = boto3.client('ec2')


def retrieve_and_associate_public_ip(network_interface_id):
    ipv4alloc = ec2_client.allocate_address(Domain='vpc')
    log("Created public ip {} for {}".format(ipv4alloc['PublicIp'], network_interface_id))

    ipv4assoc = ec2_client.associate_address(
        AllocationId=ipv4alloc['AllocationId'],
        NetworkInterfaceId=network_interface_id
    )
    log(f"Created public ip association: {network_interface_id} {ipv4assoc['AssociationId']}")

    return




def create_and_attach_network_interface(instance_id, device_index, subnet, i_cfg, config):
    # ipv6 prefix delegation
    ipv6_count = 0
    if config['ipv6'] and device_index==2:
        ipv6_count = 1

    network_interface = ec2_client.create_network_interface(
            SubnetId = subnet,
            Groups = i_cfg['security_group_ids'],
            Description = subnet,
            Ipv6PrefixCount = ipv6_count,
        )
    network_interface_id = network_interface['NetworkInterface']['NetworkInterfaceId']
    log(f"Created network interface: index:{device_index} - {network_interface_id}")

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

    if config['ipv6']:
        aipv6a = ec2_client.assign_ipv6_addresses(
                NetworkInterfaceId=network_interface_id,
                Ipv6AddressCount=1
            )
        log(f"Assigned ipv6 address: {aipv6a}")

    associate_public_ip = False
    try:
        associate_public_ip = i_cfg['associate_public_ip']
    except:
        pass
    if associate_public_ip:
        retrieve_and_associate_public_ip(network_interface_id)
    else:
        log("Not associating public ip")

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
    log(config)

    instance_id = event['detail']['EC2InstanceId']
    event_detail = event["detail-type"] 
    if event_detail != "EC2 Instance-launch Lifecycle Action":
        log(f"Instance: {instance_id} Event:{event_detail} - ignoring")
        return

    log(f"Instance: {instance_id} Event:{event_detail} - handling")

    handle_launch(instance_id, interfaces, config)

    log(f"Completing-continue lifecyle: {instance_id} Event:{event_detail} ")
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


def log(message):
    print('{}'.format(message))
