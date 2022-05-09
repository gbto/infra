output "redshift-username" {
  sensitive = true
  value     = "u${random_string.root_username.result}"
}

output "redshift-password" {
  sensitive = true
  value     = "p${random_password.root_password.result}"
}
output "redshift-vpc-id" {
  value = aws_vpc.redshift_vpc.id
}

output "redshift-vpc-subnet-ids" {
  value = aws_subnet.redshift_subnet.id
}
