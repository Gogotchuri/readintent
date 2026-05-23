output "server_ip" {
  value       = hcloud_server.main.ipv4_address
  description = "Public IPv4 address of the server"
}

output "domain" {
  value       = var.domain
  description = "Domain pointing to the server"
}

output "ssh_command" {
  value       = "ssh deploy@${var.domain}"
  description = "SSH command to connect to the server"
}
