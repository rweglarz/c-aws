import boto3
import botocore
import json
import os
from datetime import datetime

ec2_client = boto3.client('ec2')
asg_client = boto3.client('autoscaling')


def lambda_handler(event, context):
    log(event)
    log(context)
    log(os.environ)
    if os.environ['subnet_ids']:
        subnet_ids = os.environ['subnet_ids'].split(",")
    else:
        log("Empty Environment variable subnet_ids:".format(os.environ['subnet_ids']))
        exit(1)
    if os.environ['interfaces']:
        interfaces = json.loads(os.environ['interfaces'])
    else:
        log("Empty Environment variable interfaces")
        exit(1)
    if os.environ['di1_sg_ids']:
        di1_sg_ids = os.environ['di1_sg_ids'].split(",")
        log("di1_sg_ids:" + os.environ['di1_sg_ids'])
    else:
        log("Empty Environment variable di1_sg_ids:".format(os.environ['di1_sg_ids']))
        exit(1)
    if os.environ['di2_sg_ids']:
        di2_sg_ids = os.environ['di2_sg_ids'].split(",")
        log("di2_sg_ids:" + os.environ['di2_sg_ids'])
    else:
        log("Empty Environment variable di2_sg_ids:".format(os.environ['di2_sg_ids']))
    ipv6 = False
    try:
        if os.environ['ipv6']=="true":
            ipv6 = True
            log("IPv6 enabled")
        else:
            log("IPv6 disabled")
    except:
        log("IPv6 not passed, not enabled")

    if event["detail-type"] != "EC2 Instance-launch Lifecycle Action":
        return

    instance_id = event['detail']['EC2InstanceId']
    instance_description = ec2_client.describe_instances(
        InstanceIds=[instance_id])
    instance = instance_description['Reservations'][0]['Instances'][0]
    instance_zone = instance['Placement']['AvailabilityZone']
    log("Handling Launch for {} in {}".format(instance_id, instance_zone))
    # log("Disabling source/destination check")
    # ec2_client.modify_instance_attribute(SourceDestCheck={'Value': False}, InstanceId=instance_id)

    device_index = 1
    for subnet in subnet_ids:
        zones = ec2_client.describe_subnets(SubnetIds=[subnet])
        availability_zone = zones["Subnets"][0]["AvailabilityZone"]
        if availability_zone != instance_zone:
            continue
        log("Adding interface index:{} in subnet: {}".format(device_index, subnet))
        
        sg_ids = []
        if device_index==1:
            sg_ids = di1_sg_ids
        if device_index==2:
            sg_ids = di2_sg_ids
        ipv6_count = 0
        if ipv6 and device_index==2:
            ipv6_count = 1
        network_interface = ec2_client.create_network_interface(
                SubnetId = subnet,
                Groups = sg_ids,
                Description = subnet,
                Ipv6PrefixCount = ipv6_count,
            )
        network_interface_id = network_interface['NetworkInterface']['NetworkInterfaceId']
        log("Created network interface: {}".format(network_interface_id))

        attach_interface = ec2_client.attach_network_interface(
                NetworkInterfaceId=network_interface_id,
                InstanceId=instance_id,
                DeviceIndex=device_index,
            )
        attachment_id = attach_interface['AttachmentId']
        log("Created attachment: {}".format(attachment_id))


        associate_public_ip = False
        try:
            associate_public_ip = interfaces[str(device_index)]['associate_public_ip']
        except:
            pass
        if associate_public_ip:
            ipv4alloc = ec2_client.allocate_address(Domain='vpc')
            log("Created public ip {} for {}".format(ipv4alloc['PublicIp'], network_interface_id))

            ipv4assoc = ec2_client.associate_address(
                AllocationId=ipv4alloc['AllocationId'],
                NetworkInterfaceId=network_interface_id
            )
            log("Created association: {}".format(ipv4assoc['AssociationId']))
        else:
            log("Not associating public ip")


        if ipv6:
            aipv6a = ec2_client.assign_ipv6_addresses(
                    NetworkInterfaceId=network_interface_id,
                    Ipv6AddressCount=1
                )
            log("Assigned ipv6 address: {}".format(aipv6a))

        mnia = ec2_client.modify_network_interface_attribute(
                Attachment={
                    'AttachmentId': attachment_id,
                    'DeleteOnTermination': True,
                },
                NetworkInterfaceId=network_interface_id,
            )
        log("debug: delete on termination: {}".format(mnia))
        device_index += 1

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
