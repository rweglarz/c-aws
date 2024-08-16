resource "aws_instance" "this" {
  ami = coalesce(
    var.ami, 
    var.fw_license=="byol" ? data.aws_ami.pa_vm_byol.id : null,
    var.fw_license=="bnd2" ? data.aws_ami.pa_vm_bnd2.id : null,
  )
  instance_type          = var.fw_instance_type
  vpc_security_group_ids = var.vpc_security_group_ids

  iam_instance_profile = var.iam_instance_profile

  dynamic "network_interface" {
    for_each = { for k, v in var.interfaces : k => v if v.device_index == 0 }
    content {
      device_index         = 0
      network_interface_id = aws_network_interface.this[network_interface.key].id
    }
  }

  key_name      = var.key_pair
  ebs_optimized = true

  user_data = join("\n", 
    [for k, v in var.bootstrap_options : "${k}=${v}"],
  )

  tags = {
    Name = var.name
  }
}

locals {
  interfaces_with_public_ip = {
    for ki, vi in var.interfaces :
    ki => {
      private_ips = (
        length(try(vi.private_ips, [])) == 0 ? [null] :
        (length(vi.private_ips) > 1 ?
          slice(vi.private_ips, 1, length(vi.private_ips))
          : vi.private_ips
        )
      )
    } if try(vi.public_ip, false)
  }
  public_ip_for_private_ip = flatten([
    for ki, vi in local.interfaces_with_public_ip : [
      for ip in vi.private_ips : {
        network_interface = ki
        private_ip        = ip
        k                 = ip == null ? ki : "${ki}_${ip}"
      }
    ]
  ])
}

resource "aws_eip" "this" {
  for_each          = { for s in local.public_ip_for_private_ip : s.k => s }
  network_interface = aws_network_interface.this[each.value.network_interface].id
  // if we have two private_ips associate with secondary (assuming for ha move)
  associate_with_private_ip = lookup(each.value, "private_ip", null)
}

resource "aws_network_interface" "this" {
  for_each                = var.interfaces
  subnet_id               = each.value.subnet_id
  private_ip_list_enabled = true
  private_ip_list         = lookup(each.value, "private_ips", null)
  source_dest_check       = lookup(each.value, "source_dest_check", false)
  security_groups         = lookup(each.value, "security_group_ids", null)
}


resource "aws_network_interface_attachment" "this" {
  for_each = { for k, v in var.interfaces : k => v if v.device_index > 0 }

  instance_id          = aws_instance.this.id
  network_interface_id = aws_network_interface.this[each.key].id
  device_index         = each.value.device_index
}

