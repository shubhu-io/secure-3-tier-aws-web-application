# ============================================================================
# ALB module outputs
# ============================================================================

output "alb_arn" {
  description = "ALB ARN"
  value       = aws_lb.this.arn
}

output "alb_dns_name" {
  description = "ALB DNS name (CNAME target for Route 53)"
  value       = aws_lb.this.dns_name
}

output "alb_zone_id" {
  description = "ALB hosted zone ID (for Route 53 alias records)"
  value       = aws_lb.this.zone_id
}

output "target_group_arn" {
  description = "App target group ARN"
  value       = aws_lb_target_group.app.arn
}

output "web_acl_arn" {
  description = "WAF web ACL ARN"
  value       = var.enable_waf ? aws_wafv2_web_acl.this[0].arn : ""
}
