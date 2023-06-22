// Generam id-uri aleatorii pt nume
resource "random_id" "id" {
  byte_length = 8
}

// Cream bucketul
resource "aws_s3_bucket" "exercitiu_bucket" {
  bucket = "exercitiu-${random_id.id.hex}"
}
