resource "aws_lb" "this" {
  name                             = var.name
  load_balancer_type               = "gateway"
  enable_cross_zone_load_balancing = true
  subnets                          = aws_subnet.gwlb[*].id
}
resource "aws_vpc_endpoint_service" "this" {
  acceptance_required        = false
  gateway_load_balancer_arns = [aws_lb.this.arn]
  depends_on                 = [aws_lb.this]
}
resource "aws_lb_listener" "this" {
  load_balancer_arn = aws_lb.this.arn
  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.this.arn
  }
}
resource "aws_lb_target_group" "this" {
  name        = var.name
  vpc_id      = aws_vpc.this.id
  target_type = "instance"
  protocol    = "GENEVE"
  port        = "6081"

  health_check {
    path     = "/php/login.php"
    port     = 80
    protocol = "HTTP"
  }
}
