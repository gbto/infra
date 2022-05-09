output "s3_dag_folder" {
  value = "s3://${aws_s3_bucket.mwaa_bucket.bucket}/${aws_mwaa_environment.mwaa_environment.dag_s3_path}"
}
output "spectrum_role_arn" {
  value = aws_iam_role.spectrum_role.arn
}
output "redshift_host" {
  value = aws_redshift_cluster.redshift_cluster.dns_name
}
output "task_role_arn" {
  value = aws_iam_role.ecs_task_role.arn
}
output "execution_role_arn" {
  value = aws_iam_role.ecs_task_execution_role.arn
}
