output "opensearch_endpoint" {
  description = "OpenSearch endpoint"
  value       = aws_opensearch_domain.this.endpoint
}

output "opensearch_dashboard_url" {
  description = "OpenSearch Dashboards URL"
  value       = aws_opensearch_domain.this.kibana_endpoint
}