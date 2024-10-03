resource "aws_networkmanager_global_network" "this" {
  description = "main"
}

resource "aws_networkmanager_core_network" "this" {
  global_network_id = aws_networkmanager_global_network.this.id
}

resource "aws_networkmanager_core_network_policy_attachment" "this" {
  core_network_id = aws_networkmanager_core_network.this.id
  policy_document = data.aws_networkmanager_core_network_policy_document.this.json
}
