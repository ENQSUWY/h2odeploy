output "id" {
  value       = aws_vpc.cluster.id
  description = "ID of the created VPC."

  # VPC by itself is useless without subnets and internet gateway so we want to
  # wait for these resources before letting other know about us.
  depends_on = [aws_route_table_association.cluster]
}
