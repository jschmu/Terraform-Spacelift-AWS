output "security_group_id" {
  value = aws_security_group.tsa_sg.id
}

output "subnet_id" {
  value = aws_subnet.tsa_public_subnet.id
}