// RDS 
resource "aws_db_instance" "exercitiu_db" {
  identifier                      = "exercitiul-${random_id.id.hex}"
  allocated_storage               = 50
  engine                          = "mysql"
  engine_version                  = "8.0"
  instance_class                  = "db.t2.micro"
  username                        = "lambda"
  password                        = "devopsdevops" 
  parameter_group_name            = "default.mysql8.0"
  skip_final_snapshot             = true
  publicly_accessible             = false
  iam_database_authentication_enabled = true
  apply_immediately               = true
  vpc_security_group_ids          = [aws_security_group.sg_exercitiu.id]
  db_subnet_group_name            = aws_db_subnet_group.exercitiu_db_subnet_group.name
}

// Security group
resource "aws_security_group" "sg_exercitiu" {
  name        = "sg_lambda_to_rds"
  description = "Inbound from Lambda to RDS"
  vpc_id      = aws_vpc.exercitiu_vpc.id

  ingress {
    from_port   = 3306
    to_port     = 3306
    protocol    = "tcp"
    cidr_blocks = [var.cidr0]
  }

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = [var.cidr0]
  }
}

// EC2 instance
resource "aws_instance" "exercitiu_instance" {
  ami           = "ami-0331ebbf81138e4de"
  instance_type = "t2.micro"
  subnet_id     = aws_subnet.exercitiu_subnet_1.id

  vpc_security_group_ids = [aws_security_group.sg_exercitiu.id]

  key_name = aws_key_pair.deployer.key_name // use the name of the key pair you just created

  tags = {
    Name = "exercitiu-instance"
  }

  user_data = base64encode(jsonencode({
    "commands" : [
      "sudo yum update -y",
      "sudo yum install -y mysql"
    ]
  }))
}