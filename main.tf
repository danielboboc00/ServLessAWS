// Generam id-uri aleatorii pt nume
resource "random_id" "id" {
  byte_length = 8
}

// Creare de Bucket s3 
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

# Creare de VPC
resource "aws_vpc" "exercitiu_vpc" {
  cidr_block = "10.0.0.0/16"

  tags = {
    Name = "exercitiu-vpc"
  }
}

# Creare de subnet
resource "aws_subnet" "exercitiu_subnet_1" {
  vpc_id     = aws_vpc.exercitiu_vpc.id
  cidr_block = "10.0.3.0/24"
  availability_zone = "us-east-1a"

  tags = {
    Name = "exercitiu-subnet-1"
  }
}

resource "aws_subnet" "exercitiu_subnet_2" {
  vpc_id     = aws_vpc.exercitiu_vpc.id
  cidr_block = "10.0.4.0/24"
  availability_zone = "us-east-1b"

  tags = {
    Name = "exercitiu-subnet-2"
  }
}

# Creare de grupuri
resource "aws_db_subnet_group" "exercitiu_db_subnet_group" {
  name       = "exercitiu-db-subnet-group"
  subnet_ids = [aws_subnet.exercitiu_subnet_1.id, aws_subnet.exercitiu_subnet_2.id]
}