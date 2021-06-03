
resource "aws_security_group" "asg-sg2" {
  name   = "asg-sg2"
  vpc_id = "${var.TFVPC}"
}

resource "aws_security_group_rule" "asg_inbound_ssh" {
  from_port         = 22
  protocol          = "tcp"
  security_group_id = "${aws_security_group.asg-sg2.id}"
  to_port           = 22
  type              = "ingress"
  cidr_blocks       = ["0.0.0.0/0"]
}

resource "aws_security_group_rule" "asg_inbound_http" {
  from_port         = 80
  protocol          = "tcp"
  security_group_id = "${aws_security_group.asg-sg2.id}"
  to_port           = 80
  type              = "ingress"
  cidr_blocks       = ["0.0.0.0/0"]
}

resource "aws_security_group_rule" "asg_inbound_database" {
  from_port         = 3306
  protocol          = "tcp"
  security_group_id = "${aws_security_group.asg-sg2.id}"
  to_port           = 3306
  type              = "ingress"
  cidr_blocks       = ["0.0.0.0/0"]
}

resource "aws_security_group_rule" "asg_inbound_backend" {
  from_port         = 8000
  protocol          = "tcp"
  security_group_id = "${aws_security_group.asg-sg2.id}"
  to_port           = 8000
  type              = "ingress"
  cidr_blocks       = ["0.0.0.0/0"]
}

resource "aws_security_group_rule" "asg_outbound_all" {
  from_port         = 0
  protocol          = "-1"
  security_group_id = "${aws_security_group.asg-sg2.id}"
  to_port           = 0
  type              = "egress"
  cidr_blocks       = ["0.0.0.0/0"]
}

resource "aws_security_group" "alb-sg2" {
  name   = "alb-sg2"
  vpc_id = "${var.TFVPC}"
}

resource "aws_security_group_rule" "inbound_http" {
  from_port         = 80
  protocol          = "tcp"
  security_group_id = "${aws_security_group.alb-sg2.id}"
  to_port           = 80
  type              = "ingress"
  cidr_blocks       = ["0.0.0.0/0"]
}

resource "aws_security_group_rule" "outbound_all" {
  from_port         = 0
  protocol          = "-1"
  security_group_id = "${aws_security_group.alb-sg2.id}"
  to_port           = 0
  type              = "egress"
  cidr_blocks       = ["0.0.0.0/0"]
}

resource "aws_lb" "InternalLoadBalancer" {
  name     = "InternalLoadBalancer"
  internal = true
  security_groups = ["${aws_security_group.alb-sg2.id}"]
  subnets = ["${var.Private-Subnet-1}","${var.Private-Subnet-2}"]
  load_balancer_type = "application"
  tags = {
    Name = "InternalLoadBalancer"
  }
}

resource "aws_lb_target_group" "backendTG" {
  name = "backendTG"
  port        = 8000
  protocol    = "HTTP"
  vpc_id      = "${var.TFVPC}"
}



resource "aws_lb_listener" "listner1" {
   load_balancer_arn = aws_lb.InternalLoadBalancer.arn
   port              = 80
   protocol          = "HTTP"

   default_action {
     type             = "forward"
     target_group_arn = aws_lb_target_group.backendTG.arn
   }
}


resource "aws_launch_configuration" "backend-launch-config" {
  image_id        = "ami-04a3a409113a1ce5a"
  instance_type   = "t2.micro"
  key_name  = "public_instance_key"
  user_data   =  "${file("userScript.sh")}"   
  security_groups = [aws_security_group.asg-sg2.id]
}

resource "aws_autoscaling_group" "Backend-ASG" {
  launch_configuration = "${aws_launch_configuration.backend-launch-config.name}"
  vpc_zone_identifier  = ["${var.Private-Subnet-1}"]
  target_group_arns    = [aws_lb_target_group.backendTG.arn]
  health_check_type    = "EC2"
  min_size = 1
  desired_capacity = 1
  max_size = 5
    
}

resource "aws_autoscaling_policy" "backend-asg-policy" {
  name = "backend-asg-policy"
  policy_type = "TargetTrackingScaling"
  target_tracking_configuration {
    predefined_metric_specification {
      predefined_metric_type = "ASGAverageCPUUtilization"
    }
    target_value = 60.0
  }
  autoscaling_group_name = aws_autoscaling_group.Backend-ASG.name
}