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

// Public Subnet Creation
resource "aws_subnet" "exercitiu_subnet_public" {
  vpc_id            = aws_vpc.exercitiu_vpc.id
  cidr_block        = "10.0.1.0/24"
  availability_zone = "us-east-2a"

  tags = {
    Name = "exercitiu-subnet-public"
  }
}

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

resource "aws_route_table_association" "exercitiu_a_public" {
  subnet_id      = aws_subnet.exercitiu_subnet_public.id
  route_table_id = aws_route_table.exercitiu_rt.id
}

// EC2 instance
resource "aws_instance" "exercitiu_instance" {
  ami           = "ami-0331ebbf81138e4de"
  instance_type = "t2.micro"
  subnet_id     = aws_subnet.exercitiu_subnet_public.id
  associate_public_ip_address = true

  vpc_security_group_ids = [aws_security_group.sg_exercitiu.id]

  key_name = aws_key_pair.deployer.key_name 

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