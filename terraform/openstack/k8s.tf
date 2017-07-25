data "openstack_images_image_v2" "etcd_image" {
  name = "${var.etcd_image}"
  most_recent = true
}
data "openstack_images_image_v2" "k8s_master_image" {
  name = "${var.k8s_master_image}"
  most_recent = true
}
data "openstack_images_image_v2" "k8s_node_image" {
  name = "${var.k8s_node_image}"
  most_recent = true
}
data "openstack_images_image_v2" "k8s_admin_image" {
  name = "${var.k8s_admin_image}"
  most_recent = true
}
data "template_file" "bootstap_ansible_sh" {
  template = "${file("${path.module}/templates/bootstrap-ansible.sh.tpl")}"
  vars {
    ssh_private_key   = "${var.ssh_private_key}"
    ansible_user      = "${var.ansible_user}"
    ansible_home      = "${var.ansible_home}"
    k8s_ansible_repo  = "${var.k8s_ansible_repo}"
  }
}
data "template_file" "ansible_external_variables_yaml" {
  template = "${file("${path.module}/templates/external_variables.yaml.tpl")}"
  vars {
      openstack_vm_api_ip       = "${var.openstack_vm_api_ip}"
      openstack_vm_domain_name  = "${var.openstack_vm_domain_name}"
      openstack_vm_no_proxy     = "${var.openstack_vm_no_proxy}"
      openstack_vm_proxy        = "${var.openstack_vm_proxy}"
      k8s_version               = "${var.k8s_version}"
  }
}

resource "openstack_compute_servergroup_v2" "k8s_etcd" {
  name     = "k8s_etcd"
  policies = ["anti-affinity"]
}

resource "openstack_compute_servergroup_v2" "k8s_node" {
  name     = "k8s_node"
  policies = ["anti-affinity"]
}

resource "openstack_compute_instance_v2" "etcd" {
  count                   = "${var.etcd_count}"
  name                    = "etcd0${count.index+1}"
  flavor_name             = "${var.etcd_flavor}"
  key_pair                = "${var.etcd_keypair}"
  security_groups         = [ "${var.etcd_securitygroups}" ]
  block_device {
    uuid                  = "${data.openstack_images_image_v2.etcd_image.id}"
    source_type           = "image"
    volume_size           = "${var.etcd_volume_size}"
    boot_index            = 0
    destination_type      = "volume"
    delete_on_termination = true
  }
  network {
    name                  = "${var.etcd_network}"
  }
  scheduler_hints {
    group                 = "${openstack_compute_servergroup_v2.k8s_etcd.id}"
  }
}

resource "openstack_compute_instance_v2" "k8s_master" {
  depends_on = [
    "openstack_compute_instance_v2.etcd",
  ]
  count                   = "1"
  name                    = "kube-master"
  flavor_name             = "${var.k8s_master_flavor}"
  key_pair                = "${var.k8s_master_keypair}"
  security_groups         = [ "${var.k8s_master_securitygroups}" ]
  # user_data               = "${data.template_file.bootstap_ansible_sh.rendered}"
  block_device {
    uuid                  = "${data.openstack_images_image_v2.k8s_master_image.id}"
    source_type           = "image"
    volume_size           = "${var.k8s_master_volume_size}"
    boot_index            = 0
    destination_type      = "volume"
    delete_on_termination = true
  }
  network {
    name                  = "${var.k8s_master_network}"
  }
}

resource "openstack_compute_instance_v2" "k8s_node" {
  depends_on = [
    "openstack_compute_instance_v2.etcd",
    "openstack_compute_instance_v2.k8s_master",
  ]
  count                   = "${var.k8s_node_count}"
  name                    = "kube0${count.index+1}"
  flavor_name             = "${var.k8s_node_flavor}"
  key_pair                = "${var.k8s_node_keypair}"
  security_groups         = [ "${var.k8s_node_securitygroups}" ]
  # user_data               = "${data.template_file.bootstap_ansible_sh.rendered}"
  block_device {
    uuid                  = "${data.openstack_images_image_v2.k8s_node_image.id}"
    source_type           = "image"
    volume_size           = "${var.k8s_node_volume_size}"
    boot_index            = 0
    destination_type      = "volume"
    delete_on_termination = true
  }
  network {
    name                  = "${var.k8s_node_network}"
  }
  scheduler_hints {
    group                 = "${openstack_compute_servergroup_v2.k8s_node.id}"
  }
}

resource "openstack_compute_instance_v2" "k8s_admin" {
  depends_on = [
    "openstack_compute_instance_v2.etcd",
    "openstack_compute_instance_v2.k8s_master",
    "openstack_compute_instance_v2.k8s_node",
  ]
  count                   = "1"
  name                    = "kube-admin"
  flavor_name             = "${var.k8s_admin_flavor}"
  key_pair                = "${var.k8s_admin_keypair}"
  security_groups         = [ "${var.k8s_admin_securitygroups}" ]
  user_data               = "${data.template_file.bootstap_ansible_sh.rendered}"
  block_device {
    uuid                  = "${data.openstack_images_image_v2.k8s_admin_image.id}"
    source_type           = "image"
    volume_size           = "${var.k8s_admin_volume_size}"
    boot_index            = 0
    destination_type      = "volume"
    delete_on_termination = true
  }
  network {
    name                  = "${var.k8s_admin_network}"
  }
}

resource "null_resource" "ansible_predeploy" {
  triggers {
    key = "${uuid()}"
  }
  depends_on = [
    "openstack_compute_instance_v2.etcd",
    "openstack_compute_instance_v2.k8s_master",
    "openstack_compute_instance_v2.k8s_node",
    "openstack_compute_instance_v2.k8s_admin",
  ]
  connection {
    type        = "ssh"
    agent       = false
    timeout     = "5m"
    host        = "${openstack_compute_instance_v2.k8s_admin.0.access_ip_v4}"
    user        = "root"
    private_key = "${var.ssh_private_key}"
  }
  provisioner "remote-exec" {
    inline = [
      "echo [etcd] > /ansible/environments/dev/hosts",
      "echo \"${join("\n",formatlist("%s ansible_ssh_host=%s", openstack_compute_instance_v2.etcd.*.name, openstack_compute_instance_v2.etcd.*.access_ip_v4))}\" >> /ansible/environments/dev/hosts",
      "echo '\n[k8s_admin]' >> /ansible/environments/dev/hosts",
      "echo \"${join("\n",formatlist("%s ansible_ssh_host=%s", openstack_compute_instance_v2.k8s_admin.*.name, openstack_compute_instance_v2.k8s_admin.*.access_ip_v4))}\" >> /ansible/environments/dev/hosts",
      "echo '\n[k8s_master]' >> /ansible/environments/dev/hosts",
      "echo \"${join("\n",formatlist("%s ansible_ssh_host=%s", openstack_compute_instance_v2.k8s_master.*.name, openstack_compute_instance_v2.k8s_master.*.access_ip_v4))}\" >> /ansible/environments/dev/hosts",
      "echo '\n[k8s_node]' >> /ansible/environments/dev/hosts",
      "echo \"${join("\n",formatlist("%s ansible_ssh_host=%s", openstack_compute_instance_v2.k8s_node.*.name, openstack_compute_instance_v2.k8s_node.*.access_ip_v4))}\" >> /ansible/environments/dev/hosts",
      "echo '\n[k8s:children]\nk8s_master\nk8s_node' >> /ansible/environments/dev/hosts",
      ]
  }
  provisioner "file" {
    content     = "${data.template_file.ansible_external_variables_yaml.rendered}"
    destination = "/ansible/external_variables.yaml"
  }

  provisioner "remote-exec" "run_ansible" {
    inline = [
      "cd /ansible",
      "ansible-playbook playbook.yaml",
    ]
  }
}

output "Etcd Servers" {
  value = "\n${join( "\n", formatlist("  %s - %s", openstack_compute_instance_v2.etcd.*.name, openstack_compute_instance_v2.etcd.*.access_ip_v4) )}\n"
}
output "K8s Servers" {
  value = "\n${join( "\n", formatlist("  %s - %s", openstack_compute_instance_v2.k8s_node.*.name, openstack_compute_instance_v2.k8s_node.*.access_ip_v4) )}\n"
}
output "K8s Admin Servers" {
  value = "\n${join( "\n", formatlist("  %s - %s", openstack_compute_instance_v2.k8s_admin.*.name, openstack_compute_instance_v2.k8s_admin.*.access_ip_v4) )}\n"
}
output "K8s Master Servers" {
  value = "\n${join( "\n", formatlist("  %s - %s", openstack_compute_instance_v2.k8s_master.*.name, openstack_compute_instance_v2.k8s_master.*.access_ip_v4) )}\n"
  # value = "${openstack_compute_instance_v2.k8s_master.0.access_ip_v4}"
}