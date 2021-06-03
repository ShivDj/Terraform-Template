
resource "aws_security_group" "frontasg-sg2" {
  name   = "frontasg-sg2"
  vpc_id = "${var.TFVPC}"
}

resource "aws_security_group_rule" "asg_inbound_ssh" {
  from_port         = 22
  protocol          = "tcp"
  security_group_id = "${aws_security_group.frontasg-sg2.id}"
  to_port           = 22
  type              = "ingress"
  cidr_blocks       = ["0.0.0.0/0"]
}

resource "aws_security_group_rule" "asg_inbound_http" {
  from_port         = 80
  protocol          = "tcp"
  security_group_id = "${aws_security_group.frontasg-sg2.id}"
  to_port           = 80
  type              = "ingress"
  cidr_blocks       = ["0.0.0.0/0"]
}

resource "aws_security_group_rule" "asg_outbound_all" {
  from_port         = 0
  protocol          = "-1"
  security_group_id = "${aws_security_group.frontasg-sg2.id}"
  to_port           = 0
  type              = "egress"
  cidr_blocks       = ["0.0.0.0/0"]
}

resource "aws_security_group" "externalalb-sg2" {
  name   = "externalalb-sg2"
  vpc_id = "${var.TFVPC}"
}

resource "aws_security_group_rule" "inbound_http" {
  from_port         = 80
  protocol          = "tcp"
  security_group_id = "${aws_security_group.externalalb-sg2.id}"
  to_port           = 80
  type              = "ingress"
  cidr_blocks       = ["0.0.0.0/0"]
}

resource "aws_security_group_rule" "outbound_all" {
  from_port         = 0
  protocol          = "-1"
  security_group_id = "${aws_security_group.externalalb-sg2.id}"
  to_port           = 0
  type              = "egress"
  cidr_blocks       = ["0.0.0.0/0"]
}

resource "aws_lb" "ExternalLoadBalancer" {
  name     = "ExternalLoadBalancer"
  internal = false
  security_groups = ["${aws_security_group.externalalb-sg2.id}"]
  subnets = ["${var.Public-Subnet-1}","${var.Public-Subnet-2}"]
  load_balancer_type = "application"
  tags = {
    Name = "ExternalLoadBalancer"
  }
}

resource "aws_lb_target_group" "frontendTG" {
  name = "frontendTG"
  port        = 80
  protocol    = "HTTP"
  vpc_id      = "${var.TFVPC}"
}



resource "aws_lb_listener" "listner1" {
   load_balancer_arn = aws_lb.ExternalLoadBalancer.arn
   port              = 80
   protocol          = "HTTP"

   default_action {
     type             = "forward"
     target_group_arn = aws_lb_target_group.frontendTG.arn
   }
}


resource "aws_launch_configuration" "frontend-launch-config" {
  image_id        = "ami-0e0cc6d5243c54191"
  instance_type   = "t2.micro"
  key_name  = "public_instance_key"
  user_data   =  "${file("frontendScript.sh")}"   
  security_groups = [aws_security_group.frontasg-sg2.id]
}

resource "aws_autoscaling_group" "Frontend-ASG" {
  launch_configuration = "${aws_launch_configuration.frontend-launch-config.name}"
  vpc_zone_identifier  = ["${var.Public-Subnet-1}"]
  target_group_arns    = [aws_lb_target_group.frontendTG.arn]
  health_check_type    = "EC2"
  min_size = 1
  desired_capacity = 1
  max_size = 5
    
}

resource "aws_autoscaling_policy" "front-asg-policy" {
  name = "front-asg-policy"
  policy_type = "TargetTrackingScaling"
  target_tracking_configuration {
    predefined_metric_specification {
      predefined_metric_type = "ASGAverageCPUUtilization"
    }
    target_value = 60.0
  }
  autoscaling_group_name = aws_autoscaling_group.Frontend-ASG.name
}