resource "google_compute_firewall" "pan" {
  name      = "clab-${var.name}-mgmt-i"
  project   = var.gcp_project
  network   = var.gcp_panorama_vpc_id
  direction = "INGRESS"
  source_ranges = module.mfw.natgw-public_ips
  allow {
    protocol = "tcp"
    ports    = ["3978", "28443"]
  }
  allow {
    protocol = "icmp"
  }
}
