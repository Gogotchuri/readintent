resource "cloudflare_record" "main" {
  zone_id = var.cloudflare_zone_id
  name    = var.domain
  content = hcloud_server.main.ipv4_address
  type    = "A"
  ttl     = 300
  proxied = false
}
