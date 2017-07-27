# Secret environment variables are sourced from  ~/.terraform_openstack_sandbox_rc
# source  ~/.terraform_openstack_sandbox_rc
variable "openstack_vm_api_ip" {}
variable "openstack_vm_domain_name" {}
variable "openstack_vm_no_proxy" {}
variable "openstack_vm_proxy" {}

variable "ansible_user" {}
variable "ansible_home" {}

variable "calicoctl_version" {}
variable "k8s_version" {}
variable "k8s_ansible_repo" {}

variable "auth_url" {}
variable "domain_name" {}
variable "tenant_name" {}
variable "user_name" {}
variable "password" {}

variable "ssh_public_key" {}
variable "ssh_private_key" {}

variable "etcd_count" {}
variable "etcd_image" {}
variable "etcd_flavor" {}
variable "etcd_keypair" {}
variable "etcd_network" {}
variable "etcd_volume_size" {}
variable "etcd_securitygroups" {}

variable "k8s_admin_image" {}
variable "k8s_admin_flavor" {}
variable "k8s_admin_keypair" {}
variable "k8s_admin_network" {}
variable "k8s_admin_volume_size" {}
variable "k8s_admin_securitygroups" {}

variable "k8s_master_image" {}
variable "k8s_master_flavor" {}
variable "k8s_master_keypair" {}
variable "k8s_master_network" {}
variable "k8s_master_volume_size" {}
variable "k8s_master_securitygroups" {}

variable "k8s_node_count" {}
variable "k8s_node_image" {}
variable "k8s_node_flavor" {}
variable "k8s_node_keypair" {}
variable "k8s_node_network" {}
variable "k8s_node_volume_size" {}
variable "k8s_node_securitygroups" {}
