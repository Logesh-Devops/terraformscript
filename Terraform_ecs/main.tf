resource "aws_vpc" "vpc" {
  cidr_block           = var.vpc_cidr_block
  enable_dns_support   = true
  enable_dns_hostnames = true
  tags = {
    Name = var.vpc_name
  }
}

resource "aws_subnet" "public_subnets" {
  count                   = length(var.availability_zones)
  vpc_id                  = aws_vpc.vpc.id
  cidr_block              = var.updated_subnet_cidr_blocks[count.index]
  availability_zone       = var.availability_zones[count.index]
  map_public_ip_on_launch = true
  tags = {
    Name = "Updated Public Subnet ${count.index + 1}"
  }
}

resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.vpc.id
}

resource "aws_route_table" "route_table" {
  vpc_id = aws_vpc.vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }

  tags = {
    Name = "route-table"
  }
}


resource "aws_route_table_association" "subnet_associations" {
  count          = length(aws_subnet.public_subnets)
  subnet_id      = aws_subnet.public_subnets[count.index].id
  route_table_id = aws_route_table.route_table.id
}

resource "aws_security_group" "security_group" {
  name        = "security-group"
  description = "My security group"
  vpc_id      = aws_vpc.vpc.id
}

resource "aws_security_group_rule" "allow_http" {
  type              = "ingress"
  from_port         = 80
  to_port           = 80
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"] # Allow incoming HTTP traffic from anywhere
  security_group_id = aws_security_group.security_group.id
}

resource "aws_security_group_rule" "allow_https" {
  type              = "ingress"
  from_port         = 443
  to_port           = 443
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"] # Allow incoming HTTPS traffic from anywhere
  security_group_id = aws_security_group.security_group.id
}

resource "aws_security_group_rule" "allow_all_egress" {
  type              = "egress"
  from_port         = 0
  to_port           = 0
  protocol          = "-1" # Allow all outbound traffic
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.security_group.id
}

resource "aws_lb" "alb" {
  name               = "alb"
  internal           = false
  load_balancer_type = "application"
  subnets            = aws_subnet.public_subnets[*].id
  security_groups    = [aws_security_group.security_group.id]

  enable_http2 = true

  idle_timeout                     = 60
  enable_deletion_protection       = false
  enable_cross_zone_load_balancing = true

  tags = {
    Name = "My ALB"
  }
}

resource "aws_lb_target_group" "target_group" {
  name        = "target-group"
  port        = 80
  protocol    = "HTTP"
  vpc_id      = aws_vpc.vpc.id
  target_type = "ip"
  health_check {
    path = "/"
  }
}

resource "aws_lb_listener" "http_listener" {
  load_balancer_arn = aws_lb.alb.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type = "fixed-response"
    fixed_response {
      content_type = "text/plain"
      status_code  = "200"
    }
  }
}

resource "aws_lb_listener_rule" "http_listener_rule" {
  listener_arn = aws_lb_listener.http_listener.arn
  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.target_group.arn
  }

  condition {
    path_pattern {
      values = ["/"] # Modify this to match the desired path pattern
    }
  }
}

resource "aws_ecs_cluster" "cluster" {
  name = "ecs-cluster"
}

resource "aws_ecs_task_definition" "task" {
  family                   = "ecs-task"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = 512
  memory                   = 2048

  execution_role_arn = aws_iam_role.ecs_execution_role.arn

  container_definitions = jsonencode([
    {
      name   = "nginx-helloworld"
      image  = var.docker_image
      memory = 512
      cpu    = 256

      portMappings = [
        {
          containerPort = 80
          hostPort      = 80
        }
      ]
    },
  ])
}

resource "aws_iam_role" "ecs_execution_role" {
  name = "ecs-execution-role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Action = "sts:AssumeRole",
        Effect = "Allow",
        Principal = {
          Service = "ecs-tasks.amazonaws.com"
        }
      }
    ]
  })
}

resource "aws_ecs_service" "ecs_service" {
  name            = "ecs-service"
  cluster         = aws_ecs_cluster.cluster.id       # Reference the ECS cluster by its ID
  task_definition = aws_ecs_task_definition.task.arn # Reference the task definition ARN
  launch_type     = "FARGATE"
  desired_count   = 1 # Number of tasks you want to run

  network_configuration {
    subnets          = aws_subnet.public_subnets[*].id          # Reference the updated VPC subnets
    security_groups  = [aws_security_group.security_group.id] # Reference the security group
    assign_public_ip = "true"
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.target_group.arn # Reference the Target Group ARN
    container_name   = "nginx-helloworld"
    container_port   = 80
  }
}

resource "aws_ecs_service" "ecs_service_2" {
  name            = "ecs-service"
  cluster         = aws_ecs_cluster.cluster.id       # Reference the ECS cluster by its ID
  task_definition = aws_ecs_task_definition.task.arn # Reference the task definition ARN
  launch_type     = "FARGATE"
  desired_count   = 1 # Number of tasks you want to run

  network_configuration {
    subnets          = aws_subnet.public_subnets[*].id          # Reference the updated VPC subnets
    security_groups  = [aws_security_group.security_group.id] # Reference the security group
    assign_public_ip = "true"
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.target_group.arn # Reference the Target Group ARN
    container_name   = "nginx-helloworld"
    container_port   = 80
  }
}
