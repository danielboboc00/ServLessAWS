// RDS 
resource "aws_db_instance" "exercitiu_db" {
  identifier                      = "exercitiu-${random_id.id.hex}"
  allocated_storage               = 50
  engine                          = "mysql"
  engine_version                  = "8.0"
  instance_class                  = "db.t2.micro"
  username                        = "lambda"
  password                        = "devopsdevops" // Please replace it with your desired password
  parameter_group_name            = "default.mysql8.0"
  skip_final_snapshot             = true
  publicly_accessible             = false
  iam_database_authentication_enabled = true
  apply_immediately               = true
  vpc_security_group_ids          = [aws_security_group.sg_exercitiu.id]
  db_subnet_group_name            = aws_db_subnet_group.exercitiu_db_subnet_group.name
}

// security grou[]
resource "aws_security_group" "sg_exercitiu" {
  name        = "sg_lambda_to_rds"
  description = "inbound de la Lambda to RDS"
  vpc_id      = aws_vpc.exercitiu_vpc.id



  ingress {
    from_port   = 3306
    to_port     = 3306
    protocol    = "tcp"
    cidr_blocks = [var.cidr0]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = [var.cidr0]
  }
}
