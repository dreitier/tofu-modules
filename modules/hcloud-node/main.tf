# One RKE2 node of a Rancher custom cluster: private network only, registered once via cloud-init with
# the node command of the cluster unit plus its roles. One unit per node (stages/…/nodes/<name>), shared
# settings in nodes/node.hcl – same layout as tg-env's VMs.

resource "hcloud_server" "this" {
  name               = var.name
  server_type        = var.server_type
  image              = var.image
  location           = var.location
  ssh_keys           = var.ssh_key_ids
  placement_group_id = var.placement_group_id
  labels             = var.labels

  public_net {
    ipv4_enabled = false
    ipv6_enabled = false
  }

  network {
    network_id = var.network_id
    ip         = var.private_ip
  }

  user_data = templatefile("${path.module}/cloud-init.yaml.tftpl", {
    router_ip    = var.network_router_ip
    private_ip   = var.private_ip
    node_command = var.node_command
    roles        = var.roles
    packages     = var.packages
    write_files = concat([
      {
        path        = "/usr/local/sbin/default-route"
        permissions = "0755"
        content     = templatefile("${path.module}/default-route.sh.tftpl", { router_ip = var.network_router_ip, resolver_ip = var.gateway_ip })
      },
      {
        path        = "/etc/systemd/system/default-route.service"
        permissions = "0644"
        content     = file("${path.module}/default-route.service")
      },
      {
        # The agent starts at boot before the private interface has its address and logs one failed
        # attempt ("network is unreachable") – start it after the route is set
        path        = "/etc/systemd/system/rancher-system-agent.service.d/10-after-default-route.conf"
        permissions = "0644"
        content     = "[Unit]\nAfter=default-route.service\nWants=default-route.service\n"
      },
    ], var.write_files)
    base_runcmd = var.base_runcmd
  })

  delete_protection  = var.protect
  rebuild_protection = var.protect

  lifecycle {
    # One-shot registration (tg-env lesson): changing node.hcl only affects new nodes, and the
    # registration token in node_command rotates every 30 days
    ignore_changes = [user_data, image, ssh_keys]
  }
}
