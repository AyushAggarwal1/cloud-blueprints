# =============================================================================
# Usecase - vpc-peering-ec2-rds
# Same-region VPC peering: EC2 (VPC-A) -> Private RDS (VPC-B)
# Assumes both VPCs, the EC2, and the RDS already exist. You supply their IDs.
# =============================================================================

# ------------------------------------------------------------------ variables
variable "region" {
  type    = string
  default = "us-east-1" # your region
}

# --- VPC-A: where the EC2 lives ---
variable "vpc_a_id" {
  type = string
}
variable "vpc_a_cidr" {
  type = string # e.g. "10.0.0.0/16"
}
variable "ec2_route_table_ids" {
  type        = list(string)
  description = "Route table(s) associated with the EC2's subnet(s)"
}
variable "ec2_security_group_id" {
  type        = string
  description = "SG attached to the EC2 instance (used as the source in the RDS SG rule)"
}

# --- VPC-B: where the RDS lives ---
variable "vpc_b_id" {
  type = string
}
variable "vpc_b_cidr" {
  type = string # e.g. "10.1.0.0/16" -- MUST NOT overlap vpc_a_cidr
}
variable "rds_route_table_ids" {
  type        = list(string)
  description = "Route table(s) associated with the RDS subnet(s)"
}
variable "rds_security_group_id" {
  type        = string
  description = "SG attached to the RDS instance (we add the inbound rule here)"
}
variable "db_port" {
  type    = number
  default = 5432 # 5432 Postgres, 3306 MySQL/MariaDB, 1433 SQL Server, 1521 Oracle
}

provider "aws" {
  region = var.region
}

# ------------------------------------------------ 1. the peering connection
# Same account + same region => auto_accept works and no accepter block needed.
resource "aws_vpc_peering_connection" "a_to_b" {
  vpc_id      = var.vpc_a_id
  peer_vpc_id = var.vpc_b_id
  auto_accept = true

  tags = {
    Name = "ec2-vpca-to-rds-vpcb"
  }
}

# ------------------------------------------------ 2. routes (BOTH directions)
# VPC-A side: reach VPC-B's CIDR via the peering connection.
resource "aws_route" "a_to_b" {
  count                     = length(var.ec2_route_table_ids)
  route_table_id            = var.ec2_route_table_ids[count.index]
  destination_cidr_block    = var.vpc_b_cidr
  vpc_peering_connection_id = aws_vpc_peering_connection.a_to_b.id
}

# VPC-B side: return traffic to VPC-A's CIDR via the same peering connection.
resource "aws_route" "b_to_a" {
  count                     = length(var.rds_route_table_ids)
  route_table_id            = var.rds_route_table_ids[count.index]
  destination_cidr_block    = var.vpc_a_cidr
  vpc_peering_connection_id = aws_vpc_peering_connection.a_to_b.id
}

# ------------------------------------------------ 3. RDS security group rule
# Same-region peering => you can reference the EC2's SG directly (no raw CIDR).
resource "aws_security_group_rule" "rds_from_ec2" {
  type                     = "ingress"
  from_port                = var.db_port
  to_port                  = var.db_port
  protocol                 = "tcp"
  security_group_id        = var.rds_security_group_id
  source_security_group_id = var.ec2_security_group_id
  description              = "Allow EC2 in peered VPC-A to reach RDS"
}

# ------------------------------------------------------------------- outputs
output "peering_connection_id" {
  value = aws_vpc_peering_connection.a_to_b.id
}
