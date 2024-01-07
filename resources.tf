#VPC 
resource "aws_vpc" "myvpc" {
  tags = {
    Name = "myvpc"
  }
  enable_dns_hostnames = true
  cidr_block = "10.10.0.0/16"
}

#Subnets
#Zone a
resource "aws_subnet" "WebA" {
  tags = {
    Name = "webA"
  }
  map_public_ip_on_launch = true
  vpc_id     = aws_vpc.myvpc.id
  cidr_block = "10.10.0.0/20"
  availability_zone = "eu-west-3a"
}
 
resource "aws_subnet" "AppA" {
  tags = {
    Name = "AppA"
  }
  vpc_id     = aws_vpc.myvpc.id
  cidr_block = "10.10.16.0/20"
  availability_zone = "eu-west-3a"
}
 
resource "aws_subnet" "DbA" {
  tags = {
    Name = "DbA"
  }
  vpc_id     = aws_vpc.myvpc.id
  cidr_block = "10.10.32.0/20"
  availability_zone = "eu-west-3a"
}
  
#Zone b
resource "aws_subnet" "WebB" {
  tags = {
    Name = "webB"
  }
  map_public_ip_on_launch = true
  vpc_id     = aws_vpc.myvpc.id
  cidr_block = "10.10.48.0/20"
  availability_zone = "eu-west-3b"
}
 
resource "aws_subnet" "AppB" {
  tags = {
    Name = "AppB"
  }
  vpc_id     = aws_vpc.myvpc.id
  cidr_block = "10.10.64.0/20"
  availability_zone = "eu-west-3b"
}
 
resource "aws_subnet" "DbB" {
  tags = {
    Name = "DbB"
  }
  vpc_id     = aws_vpc.myvpc.id
  cidr_block = "10.10.80.0/20"
  availability_zone = "eu-west-3b"
}

#Gateway
resource "aws_internet_gateway" "gw" {
  tags = {
    Name = "gw"
  }
  vpc_id = aws_vpc.myvpc.id
}

#Route tables
#Public subnet
resource "aws_route_table" "rt_WebA" {
    vpc_id = aws_vpc.myvpc.id
route {
        cidr_block = "0.0.0.0/0"
        gateway_id = aws_internet_gateway.gw.id
    }
tags = {
        Name = "Public rt WebA "
    }
}
resource "aws_route_table_association" "rt_associate_WebA" {
    subnet_id = aws_subnet.WebA.id
    route_table_id = aws_route_table.rt_WebA.id
}

resource "aws_route_table" "rt_WebB" {
    vpc_id = aws_vpc.myvpc.id
route {
        cidr_block = "0.0.0.0/0"
        gateway_id = aws_internet_gateway.gw.id
    }
tags = {
        Name = "Public rt WebB"
    }
}
resource "aws_route_table_association" "rt_associate_WebB" {
    subnet_id = aws_subnet.WebB.id
    route_table_id = aws_route_table.rt_WebB.id
}

#Private Subnets
resource "aws_route_table" "rt_AppA" {
  vpc_id = aws_vpc.myvpc.id

  route {
    cidr_block = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.NAT_gw_WebA.id
  }

  tags = {
    Name = "rt AppA"
  }

}

resource "aws_route_table_association" "rt_associate_AppA" {
  subnet_id      = aws_subnet.AppA.id

  route_table_id = aws_route_table.rt_AppA.id
}

resource "aws_route_table" "rt_AppB" {
  vpc_id = aws_vpc.myvpc.id

  route {
    cidr_block = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.NAT_gw_WebB.id
  }

  tags = {
    Name = "rt AppB"
  }

}

resource "aws_route_table_association" "rt_associate_AppB" {
  subnet_id      = aws_subnet.AppB.id

  route_table_id = aws_route_table.rt_AppB.id
}

resource "aws_route_table" "rt_DbA" {
  vpc_id = aws_vpc.myvpc.id

#  route {
#    cidr_block = "0.0.0.0/0"
#    nat_gateway_id = aws_nat_gateway.NAT_gw_AppA.id
#  }

  tags = {
    Name = "rt DbA"
  }

}

resource "aws_route_table_association" "rt_associate_DbA" {
  subnet_id      = aws_subnet.DbA.id

  route_table_id = aws_route_table.rt_DbA.id
}

resource "aws_route_table" "rt_DbB" {
  vpc_id = aws_vpc.myvpc.id

#  route {
#    cidr_block = "0.0.0.0/0"
#    nat_gateway_id = aws_nat_gateway.NAT_gw_AppB.id
#  }

  tags = {
    Name = "rt DbB"
  }

}

resource "aws_route_table_association" "rt_associate_DbB" {
  subnet_id      = aws_subnet.DbB.id

  route_table_id = aws_route_table.rt_DbB.id
}

#Elastic IP
resource "aws_eip" "NAT_gw_EIP_a" {
  domain   = "vpc"
}

resource "aws_eip" "NAT_gw_EIP_b" {
  domain   = "vpc"
}

#NAT Gateway
resource "aws_nat_gateway" "NAT_gw_WebA" {

  allocation_id = aws_eip.NAT_gw_EIP_a.id
  
  subnet_id = aws_subnet.WebA.id
  tags = {
    Name = "NAT gw WebA"
  }
}

resource "aws_nat_gateway" "NAT_gw_WebB" {

  allocation_id = aws_eip.NAT_gw_EIP_b.id
  
  subnet_id = aws_subnet.WebB.id
  tags = {
    Name = "NAT gw WebB"
  }
}

#Security groups
#frontend - 80 порт, backend - 3000, database - 6000
#Внешний трафик мог приходить только в сеть frontend (public)
#backend был доступен только из сети frontend и имел возможность обновляться через nat gw
#DB был доступен только из сети backend
resource "aws_default_security_group" "sg_default" {
  vpc_id      = aws_vpc.myvpc.id

  ingress {
    description      = "all in"
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
  }
  
  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
  }

  tags = {
    Name = "sg_default"
  }
}

resource "aws_security_group" "sg_WebA" {
  description = "HTTP, PING, SSH"

  name = "sg_WebA"
  
  vpc_id = aws_vpc.myvpc.id

  ingress {
    description = "HTTP"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "Ping"
    from_port   = 0
    to_port     = 0
    protocol    = "ICMP"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "SSH"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    description = "output from webserver"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_security_group" "sg_AppA" {
  description = "backend"
  name = "sg_AppA"
  vpc_id = aws_vpc.myvpc.id

  ingress {
    description = "input backend"
    from_port   = 3000
    to_port     = 3000
    protocol    = "tcp"
    #cidr_blocks = ["10.10.0.0/20", "10.10.32.0/20"]	
    security_groups = [aws_security_group.sg_WebA.id]
	
  }

  egress {
    description = "output backend"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_security_group" "sg_DbA" {
  description = "database"
  name = "sg_DbA"
  vpc_id = aws_vpc.myvpc.id

  ingress {
    description = "input database"
    from_port   = 6000
    to_port     = 6000
    protocol    = "tcp"
    #cidr_blocks = ["10.10.16.0/20"]		
    security_groups = [aws_security_group.sg_AppA.id]
  }

  egress {
    description = "output database"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

#NACLs
resource "aws_network_acl" "public" {
  vpc_id     = aws_vpc.myvpc.id
  subnet_ids = [aws_subnet.WebA.id, aws_subnet.WebB.id]

  # Ingress rules
  # Allow all local traffic
  ingress {
    protocol   = -1
    rule_no    = 100
    action     = "allow"
    cidr_block = aws_vpc.myvpc.cidr_block
    from_port  = 0
    to_port    = 0
  }

  # Allow HTTP traffic from the internet
  ingress {
    protocol   = "6"
    rule_no    = 110
    action     = "allow"
    cidr_block = "0.0.0.0/0"
    from_port  = 80
    to_port    = 80
  }

  # Egress rules
  # Allow all ports, protocols, and IPs outbound
  egress {
    protocol   = -1
    rule_no    = 100
    action     = "allow"
    cidr_block = "0.0.0.0/0"
    from_port  = 0
    to_port    = 0
  }

  tags = {
    Name = "Web-nacl"
  }
}

resource "aws_network_acl" "app" {
  vpc_id     = aws_vpc.myvpc.id
  subnet_ids = [aws_subnet.AppA.id, aws_subnet.AppB.id]

  # Ingress rules
  ingress {
    protocol   = -1
    rule_no    = 100
    action     = "allow"
    cidr_block = aws_vpc.myvpc.cidr_block
    from_port  = 0
    to_port    = 0
  }

  # Egress rules
  egress {
    protocol   = -1
    rule_no    = 100
    action     = "allow"
    cidr_block = "0.0.0.0/0"
    from_port  = 0
    to_port    = 0
  }

  tags = {
    Name = "App-nacl"
  }
}

resource "aws_network_acl" "data" {
  vpc_id     = aws_vpc.myvpc.id
  subnet_ids = [aws_subnet.DbA.id, aws_subnet.DbB.id]

  # Ingress rules
  ingress {
    protocol   = "tcp"
    rule_no    = 100
    action     = "allow"
    cidr_block = aws_vpc.myvpc.cidr_block
    from_port  = 6000
    to_port    = 6000
  }

  # Egress rules
  egress {
    protocol   = "tcp"
    rule_no    = 100
    action     = "allow"
    cidr_block = aws_vpc.myvpc.cidr_block
    from_port  = 0
    to_port    = 0
  }

  tags = {
    Name = "Db-nacl"
  }
}

#Instances for testing
resource "aws_instance" "web-server" {
  tags = {
    Name = "web-server"
  }
  ami           = "ami-02ea01341a2884771"
  instance_type = "t2.micro"
  subnet_id     = aws_subnet.WebA.id
#  security_groups = [aws_security_group.sg_WebA.id]
}

resource "aws_instance" "backend" {
  tags = {
    Name = "backend"
  }
  ami           = "ami-02ea01341a2884771"
  instance_type = "t2.micro"
  subnet_id     = aws_subnet.AppA.id
#  security_groups = [aws_security_group.sg_AppA.id]  
  
}

resource "aws_instance" "database" {
  tags = {
    Name = "database"
  }
  ami           = "ami-02ea01341a2884771"
  instance_type = "t2.micro"
  subnet_id     = aws_subnet.DbA.id
#  security_groups = [aws_security_group.sg_DbA.id]    
}
