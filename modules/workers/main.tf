resource "digitalocean_droplet" "node" {
  ssh_keys           = ["${var.ssh_keys}"]
  image              = "${var.image}"
  region             = "${var.region}"
  size               = "${var.size}"
  private_networking = true
  backups            = "${var.backups}"
  ipv6               = false
  user_data          = "${var.user_data}"
  tags               = ["${var.tags}"]
  count              = "${var.total_instances}"
  name               = "${format("%s-%02d.%s.%s", var.name, count.index + 1, var.region, var.domain)}"

  connection {
    type        = "ssh"
    user        = "${var.provision_user}"
    private_key = "${var.provision_ssh_key_content}"
    timeout     = "${var.connection_timeout}"
  }

  provisioner "file" {
    source      = "${path.module}/scripts/join.sh"
    destination = "/tmp/join_cluster_as_worker.sh"
  }

  provisioner "remote-exec" {
    inline = [
      "chmod +x /tmp/join_cluster_as_worker.sh",
      "timeout 100 /tmp/join_cluster_as_worker.sh",
    ]
  }

	provisioner "remote-exec" {
    inline = [
      "timeout 100 ${var.docker_cmd} swarm join --token ${var.join_token} --availability ${var.availability} ${var.manager_private_ip}:2377"
    ]
  }

  provisioner "remote-exec" {
    when = "destroy"

    inline = [
      "docker swarm leave",
    ]

    on_failure = "continue"
  }
}
