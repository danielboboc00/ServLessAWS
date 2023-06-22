// Key pair
resource "aws_key_pair" "deployer" {
  key_name   = "MyKP2"
  public_key = file("~/.ssh/MyKP22.pub") 
}