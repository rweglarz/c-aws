import boto3
import botocore
import os
from datetime import datetime

ec2_client = boto3.client('ec2')
asg_client = boto3.client('autoscaling')


def lambda_handler(event, context):
    if os.environ['subnet_ids']:
        subnet_ids = os.environ['subnet_ids'].split(",")
    else:
        log("Empty Environment variable subnet_ids:" +
            os.environ['subnet_ids'])
        exit(1)
    if os.environ['sg_ids']:
        sg_ids = os.environ['sg_ids'].split(",")
    else:
        log("Empty Environment variable sg_ids:" + os.environ['sg_ids'])
        exit(1)

    if event["detail-type"] != "EC2 Instance-launch Lifecycle Action":
        return

    instance_id = event['detail']['EC2InstanceId']
    instance_description = ec2_client.describe_instances(
        InstanceIds=[instance_id])
    instance = instance_description['Reservations'][0]['Instances'][0]
    instance_zone = instance['Placement']['AvailabilityZone']
    log("Handling Launch for {} in {}".format(instance_id, instance_zone))

    device_index = 1
    for subnet in subnet_ids:
        zones = ec2_client.describe_subnets(SubnetIds=[subnet])
        availability_zone = zones["Subnets"][0]["AvailabilityZone"]
        if availability_zone != instance_zone:
            continue
        log("Adding interface index:{} in subnet: {}".format(
            device_index, subnet))

        network_interface = ec2_client.create_network_interface(
            SubnetId=subnet, Groups=sg_ids)
        network_interface_id = network_interface['NetworkInterface'][
            'NetworkInterfaceId']
        log("Created network interface: {}".format(network_interface_id))

        attach_interface = ec2_client.attach_network_interface(
            NetworkInterfaceId=network_interface_id,
            InstanceId=instance_id,
            DeviceIndex=device_index)
        attachment_id = attach_interface['AttachmentId']
        log("Created attachment: {}".format(attachment_id))

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
            LifecycleActionResult='CONTINUE')

    except botocore.exceptions.ClientError as e:
        log("Error completing life cycle hook for instance {}: {}".format(
            instance_id, e.response['Error']['Code']))


def log(message):
    print('{}Z {}'.format(datetime.utcnow().isoformat(), message))
