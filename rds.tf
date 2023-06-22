resource "aws_db_instance" "exercitiu_db" {
  engine               = "mysql"
  engine_version       = "8.0"
  instance_class       = "db.t2.micro"
  allocated_storage    = 50
  username             = "lambda"
  password             = "devopsdevops"
  db_subnet_group_name = aws_db_subnet_group.exercitiu_db_subnet_group.name
  iam_database_authentication_enabled = true
  identifier           = "exercitiu-db"
}
