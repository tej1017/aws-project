data "aws_availability_zones" "available" {
  state = "available"
}

data "aws_ssm_parameter" "al2023" {
  name = "/aws/service/ami-amazon-linux-latest/al2023-ami-kernel-default-x86_64"
}

locals {
  az   = data.aws_availability_zones.available.names[0]
  tags = { Project = "EWB-VPC-Peering", Student = var.student_name }
}

resource "aws_key_pair" "lab" {
  key_name   = "ewb-lab"
  public_key = file(pathexpand(var.public_key_path))
}

############ VPC A ############
resource "aws_vpc" "a" {
  cidr_block = "10.10.0.0/16"
  tags       = { Name = "ewb-vpc-a" }
}

resource "aws_subnet" "a_public" {
  vpc_id                  = aws_vpc.a.id
  cidr_block              = "10.10.1.0/24"
  availability_zone       = local.az
  map_public_ip_on_launch = false
  tags                    = { Name = "ewb-a-public" }
}

resource "aws_subnet" "a_private" {
  vpc_id                  = aws_vpc.a.id
  cidr_block              = "10.10.2.0/24"
  availability_zone       = local.az
  map_public_ip_on_launch = false
  tags                    = { Name = "ewb-a-private" }
}

resource "aws_internet_gateway" "a" {
  vpc_id = aws_vpc.a.id
  tags   = { Name = "ewb-igw-a" }
}

resource "aws_route_table" "a_public" {
  vpc_id = aws_vpc.a.id
  tags   = { Name = "ewb-rt-a-public" }
}

resource "aws_route_table" "a_private" {
  vpc_id = aws_vpc.a.id
  tags   = { Name = "ewb-rt-a-private" }
}

resource "aws_route" "a_public_default" {
  route_table_id         = aws_route_table.a_public.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.a.id
}

resource "aws_route_table_association" "a_public" {
  subnet_id      = aws_subnet.a_public.id
  route_table_id = aws_route_table.a_public.id
}

resource "aws_route_table_association" "a_private" {
  subnet_id      = aws_subnet.a_private.id
  route_table_id = aws_route_table.a_private.id
}

############ VPC B ############
resource "aws_vpc" "b" {
  cidr_block = "10.20.0.0/16"
  tags       = { Name = "ewb-vpc-b" }
}

resource "aws_subnet" "b_private" {
  vpc_id                  = aws_vpc.b.id
  cidr_block              = "10.20.1.0/24"
  availability_zone       = local.az
  map_public_ip_on_launch = false
  tags                    = { Name = "ewb-b-private" }
}

resource "aws_route_table" "b_private" {
  vpc_id = aws_vpc.b.id
  tags   = { Name = "ewb-rt-b-private" }
}

resource "aws_route_table_association" "b_private" {
  subnet_id      = aws_subnet.b_private.id
  route_table_id = aws_route_table.b_private.id
}

############ Peering (phase 2) ############
resource "aws_vpc_peering_connection" "a_b" {
  count       = var.enable_peering ? 1 : 0
  vpc_id      = aws_vpc.a.id # requester
  peer_vpc_id = aws_vpc.b.id # accepter
  auto_accept = true         # same account + Region
  tags        = { Name = "ewb-a-b-peer" }
}

resource "aws_route" "a_private_to_b" {
  count                     = var.enable_peering ? 1 : 0
  route_table_id            = aws_route_table.a_private.id
  destination_cidr_block    = "10.20.0.0/16"
  vpc_peering_connection_id = aws_vpc_peering_connection.a_b[0].id
}

resource "aws_route" "b_private_to_a" {
  count                     = var.enable_peering ? 1 : 0
  route_table_id            = aws_route_table.b_private.id
  destination_cidr_block    = "10.10.0.0/16"
  vpc_peering_connection_id = aws_vpc_peering_connection.a_b[0].id
}

# Public subnet needs it too: ProxyJump makes the bastion open the connection to App-B
resource "aws_route" "a_public_to_b" {
  count                     = var.enable_peering ? 1 : 0
  route_table_id            = aws_route_table.a_public.id
  destination_cidr_block    = "10.20.0.0/16"
  vpc_peering_connection_id = aws_vpc_peering_connection.a_b[0].id
}

############ Security groups ############
resource "aws_security_group" "bastion" {
  name        = "ewb-sg-bastion"
  description = "Bastion SSH from my IP"
  vpc_id      = aws_vpc.a.id
  tags        = { Name = "ewb-sg-bastion" }
}

resource "aws_security_group" "app_a" {
  name        = "ewb-sg-app-a"
  description = "App-A: SSH from bastion, ICMP echo from App-B"
  vpc_id      = aws_vpc.a.id
  tags        = { Name = "ewb-sg-app-a" }
}

resource "aws_security_group" "app_b" {
  name        = "ewb-sg-app-b"
  description = "App-B: SSH from bastion, ICMP echo from App-A"
  vpc_id      = aws_vpc.b.id
  tags        = { Name = "ewb-sg-app-b" }
}

resource "aws_vpc_security_group_ingress_rule" "bastion_ssh" {
  security_group_id = aws_security_group.bastion.id
  cidr_ipv4         = var.my_ip_cidr
  ip_protocol       = "tcp"
  from_port         = 22
  to_port           = 22
  description       = "SSH from my public IP"
}

resource "aws_vpc_security_group_ingress_rule" "app_a_ssh" {
  security_group_id = aws_security_group.app_a.id
  cidr_ipv4         = "10.10.1.10/32"
  ip_protocol       = "tcp"
  from_port         = 22
  to_port           = 22
  description       = "SSH from bastion private IP"
}

resource "aws_vpc_security_group_ingress_rule" "app_a_icmp" {
  security_group_id = aws_security_group.app_a.id
  cidr_ipv4         = "10.20.1.10/32"
  ip_protocol       = "icmp"
  from_port         = 8 # ICMP type 8 = echo request
  to_port           = 0 # code 0
  description       = "Echo request from App-B"
}

resource "aws_vpc_security_group_ingress_rule" "app_b_ssh" {
  security_group_id = aws_security_group.app_b.id
  cidr_ipv4         = "10.10.1.10/32"
  ip_protocol       = "tcp"
  from_port         = 22
  to_port           = 22
  description       = "SSH from bastion private IP"
}

resource "aws_vpc_security_group_ingress_rule" "app_b_icmp" {
  security_group_id = aws_security_group.app_b.id
  cidr_ipv4         = "10.10.2.10/32"
  ip_protocol       = "icmp"
  from_port         = 8
  to_port           = 0
  description       = "Echo request from App-A"
}

resource "aws_vpc_security_group_egress_rule" "bastion_all" {
  security_group_id = aws_security_group.bastion.id
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "-1"
}

resource "aws_vpc_security_group_egress_rule" "app_a_all" {
  security_group_id = aws_security_group.app_a.id
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "-1"
}

resource "aws_vpc_security_group_egress_rule" "app_b_all" {
  security_group_id = aws_security_group.app_b.id
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "-1"
}

############ Instances ############
resource "aws_instance" "bastion" {
  ami                         = data.aws_ssm_parameter.al2023.value
  instance_type               = var.instance_type
  subnet_id                   = aws_subnet.a_public.id
  private_ip                  = "10.10.1.10"
  associate_public_ip_address = true
  vpc_security_group_ids      = [aws_security_group.bastion.id]
  key_name                    = aws_key_pair.lab.key_name
  metadata_options {
    http_tokens = "required"
  }
  root_block_device {
    volume_size           = 8
    volume_type           = "gp3"
    delete_on_termination = true
    tags                  = merge(local.tags, { Name = "ewb-bastion-root" })
  }
  tags = { Name = "ewb-bastion" }
}

resource "aws_instance" "app_a" {
  ami                         = data.aws_ssm_parameter.al2023.value
  instance_type               = var.instance_type
  subnet_id                   = aws_subnet.a_private.id
  private_ip                  = "10.10.2.10"
  associate_public_ip_address = false
  vpc_security_group_ids      = [aws_security_group.app_a.id]
  key_name                    = aws_key_pair.lab.key_name
  metadata_options {
    http_tokens = "required"
  }
  root_block_device {
    volume_size           = 8
    volume_type           = "gp3"
    delete_on_termination = true
    tags                  = merge(local.tags, { Name = "ewb-app-a-root" })
  }
  tags = { Name = "ewb-app-a" }
}

resource "aws_instance" "app_b" {
  ami                         = data.aws_ssm_parameter.al2023.value
  instance_type               = var.instance_type
  subnet_id                   = aws_subnet.b_private.id
  private_ip                  = "10.20.1.10"
  associate_public_ip_address = false
  vpc_security_group_ids      = [aws_security_group.app_b.id]
  key_name                    = aws_key_pair.lab.key_name
  metadata_options {
    http_tokens = "required"
  }
  root_block_device {
    volume_size           = 8
    volume_type           = "gp3"
    delete_on_termination = true
    tags                  = merge(local.tags, { Name = "ewb-app-b-root" })
  }
  tags = { Name = "ewb-app-b" }
}
