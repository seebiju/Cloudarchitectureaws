aws_region            = "ap-southeast-1"
vpc_cidr              = "172.16.0.0/16"
public_subnet_1_cidr  = "172.16.1.0/24"
public_subnet_2_cidr  = "172.16.2.0/24"
private_subnet_1_cidr = "172.16.3.0/24"
private_subnet_2_cidr = "172.16.4.0/24"

ami_id                = "ami-0a80ee51a7ebf1a5f" # replace with actual AMI
instance_type         = "t3.micro"
db_instance_class     = "db.t3.micro"
db_username           = "admin"
db_password           = "your_secure_password"
s3_bucket_name        = "my-cloudfront-origin-bucket-example"
