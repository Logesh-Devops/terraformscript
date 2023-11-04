
resource "aws_db_subnet_group" "aurora_subnet_group" {
  name       = "aurora-subnet-group"
  description = "Aurora subnet group for multi-AZ"
  subnet_ids = var.subnet_ids
}

resource "aws_security_group" "aurora_sg" {
  name        = "aurora-sg-new"
  description = "Aurora RDS security group"
  ingress {
    from_port   = 3306
    to_port     = 3306
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"] 
  }
}

resource "aws_db_instance" "aurora_master" {
  allocated_storage    = 20
  storage_type         = "gp2"
  engine               = "aurora"
  engine_version       = "14.5"
  instance_class       = "db.r5.large"
  username             = "your-username"
  password             = "your-password"
  skip_final_snapshot  = true
  db_subnet_group_name = aws_db_subnet_group.aurora_subnet_group.name
  vpc_security_group_ids = [aws_security_group.aurora_sg.id]
}

resource "aws_db_instance" "aurora_replica" {
  count               = 2  # Number of replicas
  allocated_storage   = 20
  storage_type        = "gp2"
  engine              = "aurora"
  engine_version      = "14.5"
  instance_class      = "db.r5.large"
  username            = "your-username"
  password            = "your-password"
  skip_final_snapshot = true
  db_subnet_group_name = aws_db_subnet_group.aurora_subnet_group.name
  vpc_security_group_ids = [aws_security_group.aurora_sg.id]
}

resource "aws_rds_cluster" "aurora_cluster" {
  cluster_identifier   = "my-aurora-cluster"
  engine              = "aurora-postgresql"  # Specify "aurora-mysql" for MySQL-compatible Aurora
  engine_version      = "14.5"  # Adjust the version as needed
  master_username      = "your-username"
  master_password      = "your-password"
  availability_zones   = ["us-east-1a", "us-east-1b"]  # AZs for multi-AZ
  database_name        = "mydb"
  db_subnet_group_name = aws_db_subnet_group.aurora_subnet_group.name
  vpc_security_group_ids = [aws_security_group.aurora_sg.id]
  skip_final_snapshot  = true

  replication_source_identifier = aws_db_instance.aurora_master.id

  tags = {
    Name = "AuroraDBCluster"
  }
}
output "aurora_cluster_endpoint" {
  value = aws_rds_cluster.aurora_cluster.endpoint
}
