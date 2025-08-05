# Cloudawsinfra
provider "aws" {
  region = var.aws_region
}

resource "aws_vpc" "main" {
  cidr_block           = var.vpc_cidr
  enable_dns_hostnames = true
  tags = {
    Name = "main-vpc"
  }
}
# Default Security Groups

resource "aws_security_group" "ec2_sg" {
  name        = "ec2-sg"
  description = "Security group for EC2 instances"
  vpc_id      = aws_vpc.main.id

  ingress {
    description = "Allow HTTPS for SSM"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "ec2-sg"
  }
}

resource "aws_security_group" "db_sg" {
  name        = "db-sg"
  description = "Security group for MariaDB"
  vpc_id      = aws_vpc.main.id

  ingress {
    description     = "Allow MySQL from EC2 SG"
    from_port       = 3306
    to_port         = 3306
    protocol        = "tcp"
    security_groups = [aws_security_group.ec2_sg.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "db-sg"
  }
}

resource "aws_security_group" "ssm_sg" {
  name        = "ssm-endpoint-sg"
  description = "Security group for VPC Interface Endpoint (SSM)"
  vpc_id      = aws_vpc.main.id

  ingress {
    description     = "Allow HTTPS from EC2 SG"
    from_port       = 443
    to_port         = 443
    protocol        = "tcp"
    security_groups = [aws_security_group.ec2_sg.id]
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "ssm-endpoint-sg"
  }
}


resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.main.id
  tags = {
    Name = "main-igw"
  }
}

resource "aws_eip" "nat" {
  tags = {
    Name = "nat-eip"
  }
}

resource "aws_nat_gateway" "nat" {
  allocation_id = aws_eip.nat.id
  subnet_id     = aws_subnet.public_1.id
  tags = {
    Name = "nat-gateway"
  }
}

resource "aws_subnet" "public_1" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = var.public_subnet_1_cidr
  map_public_ip_on_launch = true
  availability_zone       = "${var.aws_region}a"
  tags = {
    Name = "public-subnet-1"
  }
}

resource "aws_subnet" "public_2" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = var.public_subnet_2_cidr
  map_public_ip_on_launch = true
  availability_zone       = "${var.aws_region}b"
  tags = {
    Name = "public-subnet-2"
  }
}

resource "aws_subnet" "private_1" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = var.private_subnet_1_cidr
  availability_zone = "${var.aws_region}a"
  tags = {
    Name = "private-subnet-1"
  }
}

resource "aws_subnet" "private_2" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = var.private_subnet_2_cidr
  availability_zone = "${var.aws_region}b"
  tags = {
    Name = "private-subnet-2"
  }
}

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }
  route {
    cidr_block = "192.168.0.0/16"
    gateway_id = "local"
  }
  tags = {
    Name = "public-rt"
  }
}

resource "aws_route_table_association" "public_1" {
  subnet_id      = aws_subnet.public_1.id
  route_table_id = aws_route_table.public.id
}

resource "aws_route_table_association" "public_2" {
  subnet_id      = aws_subnet.public_2.id
  route_table_id = aws_route_table.public.id
}

resource "aws_route_table" "private" {
  vpc_id = aws_vpc.main.id
  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.nat.id
  }
  route {
    cidr_block = "192.168.0.0/16"
    gateway_id = "local"
  }
  tags = {
    Name = "private-rt"
  }
}

resource "aws_route_table_association" "private_1" {
  subnet_id      = aws_subnet.private_1.id
  route_table_id = aws_route_table.private.id
}

resource "aws_route_table_association" "private_2" {
  subnet_id      = aws_subnet.private_2.id
  route_table_id = aws_route_table.private.id
}

resource "aws_vpc_endpoint" "ssm" {
  vpc_id              = aws_vpc.main.id
  service_name        = "com.amazonaws.${var.aws_region}.ssm"
  subnet_ids          = [aws_subnet.private_1.id, aws_subnet.private_2.id]
  vpc_endpoint_type   = "Interface"
  security_group_ids  = [aws_security_group.ssm_sg.id]
  private_dns_enabled = true
  tags = {
    Name = "ssm-vpc-endpoint"
  }
}

resource "aws_iam_role" "ssm" {
  name = "ec2-ssm-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Effect = "Allow",
      Principal = {
        Service = "ec2.amazonaws.com"
      },
      Action = "sts:AssumeRole"
    }]
  })
}

resource "aws_iam_role_policy_attachment" "ssm_managed" {
  role       = aws_iam_role.ssm.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

resource "aws_iam_instance_profile" "ssm" {
  name = "ec2-ssm-instance-profile"
  role = aws_iam_role.ssm.name
}

resource "aws_instance" "ssm_host" {
  ami                         = var.ami_id
  instance_type               = var.instance_type
  subnet_id                   = aws_subnet.public_1.id
  associate_public_ip_address = true
  vpc_security_group_ids      = [aws_security_group.ec2_sg.id]
  iam_instance_profile        = aws_iam_instance_profile.ssm.name
  tags = {
    Name = "ssm-host"
  }
}

resource "aws_db_subnet_group" "mariadb" {
  name       = "mariadb-subnet-group"
  subnet_ids = [aws_subnet.private_1.id, aws_subnet.private_2.id]
}

resource "aws_db_instance" "mariadb_master" {
  identifier             = "mariadb-master"
  instance_class         = var.db_instance_class
  allocated_storage      = 20
  engine                 = "mariadb"
  username               = var.db_username
  password               = var.db_password
  db_subnet_group_name   = aws_db_subnet_group.mariadb.name
  vpc_security_group_ids = [aws_security_group.db_sg.id]
  skip_final_snapshot    = true
  multi_az               = false
  publicly_accessible    = false
  availability_zone      = "${var.aws_region}b"
  tags = {
    Name = "mariadb-master"
  }
}

resource "aws_db_instance" "mariadb_replica" {
  identifier             = "mariadb-replica"
  instance_class         = var.db_instance_class
  engine                 = "mariadb"
  replicate_source_db    = aws_db_instance.mariadb_master.id
  db_subnet_group_name   = aws_db_subnet_group.mariadb.name
  vpc_security_group_ids = [aws_security_group.db_sg.id]
  skip_final_snapshot    = true
  publicly_accessible    = false
  availability_zone      = "${var.aws_region}a"
  tags = {
    Name = "mariadb-replica"
  }
}

resource "aws_s3_bucket" "web_assets" {
  bucket = var.s3_bucket_name
}

resource "aws_cloudfront_origin_access_control" "oac" {
  name                              = "s3-oac"
  origin_access_control_origin_type = "s3"
  signing_behavior                  = "always"
  signing_protocol                  = "sigv4"
}

resource "aws_cloudfront_distribution" "cdn" {
  origin {
    domain_name              = aws_s3_bucket.web_assets.bucket_regional_domain_name
    origin_id                = "s3-origin"
    origin_access_control_id = aws_cloudfront_origin_access_control.oac.id
  }

  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }

  enabled             = true
  default_root_object = "index.html"

  default_cache_behavior {
    allowed_methods  = ["GET", "HEAD"]
    cached_methods   = ["GET", "HEAD"]
    target_origin_id = "s3-origin"

    forwarded_values {
      query_string = false
      cookies {
        forward = "none"
      }
    }

    viewer_protocol_policy = "redirect-to-https"
  }

  viewer_certificate {
    cloudfront_default_certificate = true
  }
}

resource "aws_lb" "nlb" {
  name               = "app-nlb"
  internal           = false
  load_balancer_type = "network"
  subnets            = [aws_subnet.public_1.id, aws_subnet.public_2.id]
}

resource "aws_lb_target_group" "ec2_targets" {
  name        = "ec2-targets"
  port        = 80
  protocol    = "TCP"
  vpc_id      = aws_vpc.main.id
  target_type = "instance"
}

resource "aws_lb_listener" "nlb_listener" {
  load_balancer_arn = aws_lb.nlb.arn
  port              = 80
  protocol          = "TCP"
  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.ec2_targets.arn
  }
}

resource "aws_launch_template" "ec2_template" {
  name_prefix            = "ec2-template-"
  image_id               = var.ami_id
  instance_type          = var.instance_type
  vpc_security_group_ids = [aws_security_group.ec2_sg.id]

  block_device_mappings {
    device_name = "/dev/xvda"
    ebs {
      volume_size = 8
    }
  }
}

resource "aws_autoscaling_group" "ec2_asg" {
  desired_capacity     = 2
  max_size             = 3
  min_size             = 2
  vpc_zone_identifier  = [aws_subnet.private_2.id]
  launch_template {
    id      = aws_launch_template.ec2_template.id
    version = "$Latest"
  }
  target_group_arns = [aws_lb_target_group.ec2_targets.arn]
  tag {
    key                 = "Name"
    value               = "asg-ec2"
    propagate_at_launch = true
  }
}
