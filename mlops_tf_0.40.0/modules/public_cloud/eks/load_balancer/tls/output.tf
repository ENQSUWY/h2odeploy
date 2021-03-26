output "certificate_arn" {
  value       = aws_acm_certificate.wildcard.arn
  description = "ARN of the created ACM certificate."
}
