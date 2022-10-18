module "vpc-app4" {
  source = "../modules/vpc"

  name = "${var.name}-app4"

  cidr_block              = var.app4_cidr
  public_mgmt_prefix_list = var.pl-mgmt-mgmt_ips

  connect_tgw  = false
  deploy_igw   = true
  deploy_natgw = true

  subnets = {
    "apigw_a" : { "idx" : 0, "zone" : var.availability_zones[0] },
    "apigw_b" : { "idx" : 1, "zone" : var.availability_zones[1] },
    "lb_a" : { "idx" : 2, "zone" : var.availability_zones[0] },
    "lb_b" : { "idx" : 3, "zone" : var.availability_zones[1] },
    "gwlbe_a" : { "idx" : 4, "zone" : var.availability_zones[0] },
    "gwlbe_b" : { "idx" : 5, "zone" : var.availability_zones[1] },
    "ecs_a" : { "idx" : 6, "zone" : var.availability_zones[0] },
    "ecs_b" : { "idx" : 7, "zone" : var.availability_zones[1] },
    "natgw_a" : { "idx" : 8, "zone" : var.availability_zones[0] },
    "natgw_b" : { "idx" : 9, "zone" : var.availability_zones[1] },
  }
}
resource "aws_vpc_endpoint" "this" {
  subnet_ids        = [module.vpc-app4.subnets["gwlbe_a"].id]
  vpc_id            = module.vpc-app4.vpc.id
  service_name      = data.terraform_remote_state.tgw.outputs.fw_vpc_endpoint_service_name
  vpc_endpoint_type = "GatewayLoadBalancer"

  lifecycle {
    # Workaround for error "InvalidParameter: Endpoint must be removed from route table before deletion".
    create_before_destroy = true
  }
  tags = {
    pan_zone = "fargate"
  }
}

resource "aws_route_table_association" "app4_natgw" {
  for_each       = { for k, v in module.vpc-app4.subnets : k => v if(length(regexall("-natgw", v.tags.Name)) > 0) }
  subnet_id      = module.vpc-app4.subnets[each.key].id
  route_table_id = module.vpc-app4.route_tables["via_igw"]
}
resource "aws_route_table" "app4_ecs" {
  for_each = { for k, v in module.vpc-app4.subnets : v.availability_zone => v if(length(regexall("-ecs", v.tags.Name)) > 0) }
  vpc_id   = module.vpc-app4.vpc.id
}
resource "aws_route" "app4_ecs-dg" {
  for_each               = { for k, v in module.vpc-app4.subnets : v.availability_zone => v if(length(regexall("-ecs", v.tags.Name)) > 0) }
  route_table_id         = aws_route_table.app4_ecs[each.key].id
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id         = module.vpc-app4.nat_gateways[each.key]
}
resource "aws_route" "app4_ecs-endpoint-a" {
  route_table_id         = aws_route_table.app4_ecs["eu-central-1a"].id
  destination_cidr_block = module.vpc-app4.subnets["lb_a"].cidr_block
  vpc_endpoint_id        = aws_vpc_endpoint.this.id
}
resource "aws_route" "app4_ecs-endpoint-b" {
  route_table_id         = aws_route_table.app4_ecs["eu-central-1b"].id
  destination_cidr_block = module.vpc-app4.subnets["lb_b"].cidr_block
  vpc_endpoint_id        = aws_vpc_endpoint.this.id
}
resource "aws_route_table_association" "app4_ecs" {
  for_each       = { for k, v in module.vpc-app4.subnets : k => v if(length(regexall("-ecs", v.tags.Name)) > 0) }
  subnet_id      = module.vpc-app4.subnets[each.key].id
  route_table_id = aws_route_table.app4_ecs[each.value.availability_zone].id
}

resource "aws_route_table_association" "app4_lb" {
  for_each       = { for k, v in module.vpc-app4.subnets : k => v if(length(regexall("-lb", v.tags.Name)) > 0) }
  subnet_id      = module.vpc-app4.subnets[each.key].id
  route_table_id = aws_route_table.app4_lb[each.value.availability_zone].id
}
resource "aws_route_table" "app4_lb" {
  for_each = { for k, v in module.vpc-app4.subnets : v.availability_zone => v if(length(regexall("-lb", v.tags.Name)) > 0) }
  vpc_id   = module.vpc-app4.vpc.id
}
resource "aws_route" "app4_lb-ecs-a" {
  route_table_id         = aws_route_table.app4_lb["eu-central-1a"].id
  destination_cidr_block = module.vpc-app4.subnets["ecs_a"].cidr_block
  vpc_endpoint_id        = aws_vpc_endpoint.this.id
}
resource "aws_route" "app4_lb-ecs-b" {
  route_table_id         = aws_route_table.app4_lb["eu-central-1b"].id
  destination_cidr_block = module.vpc-app4.subnets["ecs_b"].cidr_block
  vpc_endpoint_id        = aws_vpc_endpoint.this.id
}


resource "aws_iam_role" "fargate-exec" {
  name = "${var.name}-ecsTaskExecutionRole"

  assume_role_policy = <<EOF
{
 "Version": "2012-10-17",
 "Statement": [
   {
     "Action": "sts:AssumeRole",
     "Principal": {
       "Service": "ecs-tasks.amazonaws.com"
     },
     "Effect": "Allow",
     "Sid": ""
   }
 ]
}
EOF
}

resource "aws_ecs_cluster" "main" {
  name = "${var.name}-ecs1"
}

resource "aws_ecs_service" "nodejs" {
  name            = "nodejs"
  cluster         = aws_ecs_cluster.main.id
  task_definition = aws_ecs_task_definition.nodejs.arn
  desired_count   = 2
  launch_type     = "FARGATE"

  load_balancer {
    target_group_arn = aws_lb_target_group.fargate.arn
    container_name   = "nodejs"
    container_port   = 8000
  }
  network_configuration {
    subnets = [
      module.vpc-app4.subnets["ecs_a"].id,
      module.vpc-app4.subnets["ecs_b"].id,
    ]
    security_groups = [
      module.vpc-app4.sg_open_id
    ]
  }
  depends_on = [
    aws_lb_listener.fargate
  ]

}

resource "aws_ecs_task_definition" "nodejs" {
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = 256
  memory                   = 512
  execution_role_arn       = aws_iam_role.fargate-exec.arn
  #task_role_arn            = aws_iam_role.ecs_task_role.arn
  family = "service"
  container_definitions = jsonencode([{
    name      = "nodejs"
    image     = var.container_image
    essential = true
    #environment = var.container_environment
    portMappings = [{
      protocol      = "tcp"
      containerPort = 8000
      hostPort      = 8000
    }]
  }])
}

resource "aws_lb" "fargate" {
  name               = "${var.name}-fargate"
  internal           = true
  load_balancer_type = "network"
  #load_balancer_type = "application"
  subnets = [
    module.vpc-app4.subnets["lb_a"].id,
    module.vpc-app4.subnets["lb_b"].id,
  ]
}


resource "aws_lb_target_group" "fargate" {
  name        = "${var.name}-fargate"
  port        = 80
  protocol    = "TCP"
  target_type = "ip"
  vpc_id      = module.vpc-app4.vpc.id
}

resource "aws_lb_listener" "fargate" {
  load_balancer_arn = aws_lb.fargate.arn
  port              = "80"
  protocol          = "TCP"
  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.fargate.arn
  }
}

resource "aws_apigatewayv2_api" "main" {
  name          = "main"
  protocol_type = "HTTP"
}

resource "aws_apigatewayv2_vpc_link" "main" {
  name = "main"
  security_group_ids = [
    module.vpc-app4.sg_open_id
  ]
  subnet_ids = [
    module.vpc-app4.subnets["apigw_a"].id,
    module.vpc-app4.subnets["apigw_b"].id,
  ]
}
resource "aws_apigatewayv2_integration" "api_integration" {
  api_id             = aws_apigatewayv2_api.main.id
  integration_type   = "HTTP_PROXY"
  connection_id      = aws_apigatewayv2_vpc_link.main.id
  connection_type    = "VPC_LINK"
  description        = "VPC integration"
  integration_method = "ANY"
  integration_uri    = aws_lb_listener.fargate.arn
}
resource "aws_apigatewayv2_route" "default_route" {
  api_id    = aws_apigatewayv2_api.main.id
  route_key = "ANY /"
  target    = "integrations/${aws_apigatewayv2_integration.api_integration.id}"
}

resource "aws_apigatewayv2_deployment" "basic" {
  api_id = aws_apigatewayv2_api.main.id
  lifecycle {
    create_before_destroy = true
  }
}
resource "aws_apigatewayv2_stage" "txt" {
  api_id = aws_apigatewayv2_api.main.id
  #deployment_id = aws_apigatewayv2_deployment.basic.id
  auto_deploy = true

  name = "txt"
}

output "try_me_url" {
  value = "${aws_apigatewayv2_stage.txt.invoke_url}/"
}
