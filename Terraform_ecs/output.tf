output "vpc_id" {
  value = aws_vpc.vpc.id
}

output "subnet_ids" {
  value = aws_subnet.public_subnets[*].id
}

output "internet_gateway_id" {
  value = aws_internet_gateway.igw.id
}

output "route_table_id" {
  value = aws_route_table.route_table.id
}

output "security_group_id" {
  value = aws_security_group.security_group.id
}

output "load_balancer_arn" {
  value = aws_lb.alb.arn
}

output "target_group_arn" {
  value = aws_lb_target_group.target_group.arn
}

output "ecs_cluster_id" {
  value = aws_ecs_cluster.cluster.id
}

output "ecs_task_definition_arn" {
  value = aws_ecs_task_definition.task.arn
}

output "ecs_service_name" {
  value = aws_ecs_service.ecs_service.name
}

output "alb_dns_name" {
  value = aws_lb.alb.dns_name
}