output "vpc_id" {
  value = aws_vpc.main.id
}

output "eks_public_subnet_ids" {
    value = [aws_subnet.public["public-eks-1"].id, aws_subnet.public["public-eks-2"].id]
}

output "eks_private_subnet_ids" {
    value = [aws_subnet.private["private-eks-1"].id, aws_subnet.private["private-eks-2"].id]
}

output "aws_subnet_public" {
    value = aws_subnet.public
}

output "aws_subnet_private" {
    value = aws_subnet.private
}

