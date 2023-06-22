// Generate random ids for names
resource "random_id" "id" {
  byte_length = 8
}

// S3 Bucket Creation
resource "aws_s3_bucket" "exercitiu_bucket" {
  bucket = "exercitiu-${random_id.id.hex}"
}

resource "aws_s3_bucket_public_access_block" "exercitiu_bucket_public_access_block" {
  bucket = aws_s3_bucket.exercitiu_bucket.id

  block_public_acls       = false
  block_public_policy     = false
  ignore_public_acls      = false
  restrict_public_buckets = false
}

// VPC Creation
resource "aws_vpc" "exercitiu_vpc" {
  cidr_block = "10.0.0.0/16"

  tags = {
    Name = "exercitiu-vpc"
  }
}

// Subnet Creation
resource "aws_subnet" "exercitiu_subnet_1" {
  vpc_id     = aws_vpc.exercitiu_vpc.id
  cidr_block = "10.0.7.0/24"
  availability_zone = "us-east-2b"

  tags = {
    Name = "exercitiu-subnet-1"
  }
}

resource "aws_subnet" "exercitiu_subnet_2" {
  vpc_id     = aws_vpc.exercitiu_vpc.id
  cidr_block = "10.0.8.0/24"
  availability_zone = "us-east-2c"

  tags = {
    Name = "exercitiu-subnet-2"
  }
}

// Subnet group creation
resource "aws_db_subnet_group" "exercitiu_db_subnet_group" {
  name       = "exercitiu-db-subnet-group"
  subnet_ids = [aws_subnet.exercitiu_subnet_1.id, aws_subnet.exercitiu_subnet_2.id]
}

// Internet gateway creation
resource "aws_internet_gateway" "exercitiu_igw" {
  vpc_id = aws_vpc.exercitiu_vpc.id

  tags = {
    Name = "exercitiu-igw"
  }
}

// Route table creation
resource "aws_route_table" "exercitiu_rt" {
  vpc_id = aws_vpc.exercitiu_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.exercitiu_igw.id
  }

  tags = {
    Name = "exercitiu-rt"
  }
}

resource "aws_main_route_table_association" "exercitiu_a" {
  vpc_id         = aws_vpc.exercitiu_vpc.id
  route_table_id = aws_route_table.exercitiu_rt.id
}
