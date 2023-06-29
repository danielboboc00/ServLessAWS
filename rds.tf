// RDS
resource "aws_db_instance" "exercitiu_db" {
  identifier                      = "exercitiul-${random_id.id.hex}"
  allocated_storage               = 50
  engine                          = "mysql"
  engine_version                  = "8.0"
  instance_class                  = "db.t2.micro"
  username                        = "lambda"
  password                        = "Abecedar10!" 
  parameter_group_name            = "default.mysql8.0"
  skip_final_snapshot             = true
  publicly_accessible             = false
  iam_database_authentication_enabled = true
  apply_immediately               = true
  vpc_security_group_ids          = [aws_security_group.sg_exercitiu.id]
  db_subnet_group_name            = aws_db_subnet_group.exercitiu_db_subnet_group.name
}

// Private Subnet Creation
resource "aws_subnet" "exercitiu_subnet_private_1" {
  vpc_id            = aws_vpc.exercitiu_vpc.id
  cidr_block        = "10.0.2.0/24"
  availability_zone = "us-east-2a"

  tags = {
    Name = "exercitiu-subnet-private-1"
  }
}

resource "aws_subnet" "exercitiu_subnet_private_2" {
  vpc_id            = aws_vpc.exercitiu_vpc.id
  cidr_block        = "10.0.3.0/24"
  availability_zone = "us-east-2b"

  tags = {
    Name = "exercitiu-subnet-private-2"
  }
}

// Subnet group creation for RDS
resource "aws_db_subnet_group" "exercitiu_db_subnet_group" {
  name       = "exercitiu-db-subnet-group"
  subnet_ids = [aws_subnet.exercitiu_subnet_private_1.id, aws_subnet.exercitiu_subnet_private_2.id]
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
    cidr_blocks = ["0.0.0.0/0"]
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
    cidr_blocks = ["0.0.0.0/0"]
  }
}

// Elastic IP for the NAT gateway
resource "aws_eip" "nat" {
  vpc = true
}

// NAT Gateway
resource "aws_nat_gateway" "exercitiu_nat_gw" {
  allocation_id = aws_eip.nat.id
  subnet_id     = aws_subnet.exercitiu_subnet_public.id

  tags = {
    Name = "exercitiu-nat-gw"
  }
}

// Private Subnet Route Table
resource "aws_route_table" "exercitiu_private_rt" {
  vpc_id = aws_vpc.exercitiu_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.exercitiu_nat_gw.id
  }

  tags = {
    Name = "exercitiu-private-rt"
  }
}

// Associate the private route table with the private subnets
resource "aws_route_table_association" "a_private_1" {
  subnet_id      = aws_subnet.exercitiu_subnet_private_1.id
  route_table_id = aws_route_table.exercitiu_private_rt.id
}

resource "aws_route_table_association" "a_private_2" {
  subnet_id      = aws_subnet.exercitiu_subnet_private_2.id
  route_table_id = aws_route_table.exercitiu_private_rt.id
}
