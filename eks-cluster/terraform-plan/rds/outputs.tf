output "rds-username" {
    value = "u${random_string.root_username.result}"
}

output "rds-password" {
    value = "p${random_password.root_password.result}"
}

output "private-rds-endpoint" {
    value = aws_db_instance.postgresql.address
}

output "public-rds-endpoint" {
    value = "${element(split("/", aws_lb.rds.arn), 2)}-${element(split("/", aws_lb.rds.arn), 3)}.elb.${var.region}.amazonaws.com"
}

output "aws_db_instance" {
    value = aws_db_instance.postgresql.resource_id
}

