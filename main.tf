# --- 1. VARIABLE DECLARATIONS ---
variable "tenancy_ocid" {}
variable "user_ocid" {}
variable "fingerprint" {}
variable "private_key_path" {}
variable "region" {}
variable "compartment_id" {}
variable "ssh_public_key_path" {
  default = "/root/.oci/oci_vm_key.pub" # Path to your local SSH public key
}

# --- 2. PROVIDER CONFIGURATION ---
terraform {
  required_providers {
    oci = {
      source  = "oracle/oci"
      version = ">= 5.0.0"
    }
  }
}

provider "oci" {
  tenancy_ocid     = var.tenancy_ocid
  user_ocid        = var.user_ocid
  fingerprint      = var.fingerprint
  private_key_path = var.private_key_path
  region           = var.region
}

# --- 3. NETWORKING (VCN + SUBNET) ---
resource "oci_core_vcn" "main" {
  compartment_id = var.compartment_id
  cidr_block     = "10.0.0.0/16"
  display_name   = "SaaS-Micro-Server-VCN"
  dns_label      = "saasvcn"
}

resource "oci_core_subnet" "public" {
  compartment_id    = var.compartment_id
  vcn_id            = oci_core_vcn.main.id
  cidr_block        = "10.0.1.0/24"
  display_name      = "SaaS-Micro-Server-Subnet"
  dns_label         = "public"
  route_table_id    = oci_core_vcn.main.default_route_table_id
  security_list_ids = [oci_core_vcn.main.default_security_list_id]
}

# --- 4. THE "ALWAYS FREE" VM ---
resource "oci_core_instance" "ampere_vm" {
  availability_domain = data.oci_identity_availability_domains.ads.availability_domains[0].name
  compartment_id      = var.compartment_id
  display_name        = "SaaS-Micro-Server"
  shape               = "VM.Standard.A1.Flex"

  # The "Always Free" Magic Numbers
  shape_config {
    ocpus         = 4
    memory_in_gbs = 24
  }

  source_details {
    source_type = "image"
    # Ubuntu 24.04 aarch64 (ARM) Image OCID for your region
    # Note: You can find specific IDs at https://docs.oracle.com/iaas/images/
    source_id = "ocid1.image.oc1.us-chicago-1.aaaaaaaaoo4nzxuu6w5aty4ap6jjnfxebwwxhlfxj5gkzmtgtnsw24eksmia"
  }

  create_vnic_details {
    subnet_id        = oci_core_subnet.public.id
    assign_public_ip = false
    nsg_ids          = [oci_core_network_security_group.vm_nsg.id]
  }

  metadata = {
    ssh_authorized_keys = file(var.ssh_public_key_path)
    user_data           = base64encode(file("${path.module}/cloud-init.sh"))
  }
}

# --- 5. SUBNET SECURITY LIST ---
resource "oci_core_default_security_list" "default" {
  manage_default_resource_id = oci_core_vcn.main.default_security_list_id

  ingress_security_rules {
    protocol  = "6" # TCP
    source    = "0.0.0.0/0"
    stateless = false
    tcp_options {
      min = 22
      max = 22
    }
  }

  ingress_security_rules {
    protocol  = "1" # ICMP
    source    = "0.0.0.0/0"
    stateless = false
    icmp_options {
      type = 8 # Echo request
    }
  }

  ingress_security_rules {
    protocol  = "6" # HTTP
    source    = "0.0.0.0/0"
    stateless = false
    tcp_options {
      min = 80
      max = 80
    }
  }

  ingress_security_rules {
    protocol  = "6" # HTTPS
    source    = "0.0.0.0/0"
    stateless = false
    tcp_options {
      min = 443
      max = 443
    }
  }

  ingress_security_rules {
    protocol  = "6"
    source    = "0.0.0.0/0"
    stateless = false
    tcp_options {
      min = 6443
      max = 6443
    }
  }

  egress_security_rules {
    protocol    = "all"
    destination = "0.0.0.0/0"
    stateless   = false
  }
}

# --- 6. NETWORK SECURITY GROUP ---
resource "oci_core_network_security_group" "vm_nsg" {
  compartment_id = var.compartment_id
  vcn_id         = oci_core_vcn.main.id
  display_name   = "SaaS-Micro-Server-NSG"
}

resource "oci_core_network_security_group_security_rule" "allow_ssh" {
  network_security_group_id = oci_core_network_security_group.vm_nsg.id
  direction                 = "INGRESS"
  protocol                  = "6" # TCP
  source                    = "0.0.0.0/0"
  source_type               = "CIDR_BLOCK"
  tcp_options {
    destination_port_range {
      min = 22
      max = 22
    }
  }
}

resource "oci_core_network_security_group_security_rule" "allow_icmp" {
  network_security_group_id = oci_core_network_security_group.vm_nsg.id
  direction                 = "INGRESS"
  protocol                  = "1" # ICMP
  source                    = "0.0.0.0/0"
  source_type               = "CIDR_BLOCK"
  icmp_options {
    type = 8 # Echo request
  }
}

resource "oci_core_network_security_group_security_rule" "allow_k8s_api" {
  network_security_group_id = oci_core_network_security_group.vm_nsg.id
  direction                 = "INGRESS"
  protocol                  = "6" # TCP
  source                    = "0.0.0.0/0"
  source_type               = "CIDR_BLOCK"
  tcp_options {
    destination_port_range {
      min = 6443
      max = 6443
    }
  }
}

resource "oci_core_network_security_group_security_rule" "allow_all_egress" {
  network_security_group_id = oci_core_network_security_group.vm_nsg.id
  direction                 = "EGRESS"
  protocol                  = "all"
  destination               = "0.0.0.0/0"
  destination_type          = "CIDR_BLOCK"
}

resource "oci_core_network_security_group_security_rule" "allow_http" {
  network_security_group_id = oci_core_network_security_group.vm_nsg.id
  direction                 = "INGRESS"
  protocol                  = "6" # TCP
  source                    = "0.0.0.0/0"
  source_type               = "CIDR_BLOCK"
  tcp_options {
    destination_port_range {
      min = 80
      max = 80
    }
  }
}

resource "oci_core_network_security_group_security_rule" "allow_https" {
  network_security_group_id = oci_core_network_security_group.vm_nsg.id
  direction                 = "INGRESS"
  protocol                  = "6" # TCP
  source                    = "0.0.0.0/0"
  source_type               = "CIDR_BLOCK"
  tcp_options {
    destination_port_range {
      min = 443
      max = 443
    }
  }
}

# --- 7. INTERNET GATEWAY & ROUTE TABLE ---
resource "oci_core_internet_gateway" "igw" {
  compartment_id = var.compartment_id
  vcn_id         = oci_core_vcn.main.id
  display_name   = "SaaS-Micro-Server-IGW"
  enabled        = true
}

resource "oci_core_default_route_table" "default" {
  manage_default_resource_id = oci_core_vcn.main.default_route_table_id

  route_rules {
    destination       = "0.0.0.0/0"
    destination_type  = "CIDR_BLOCK"
    network_entity_id = oci_core_internet_gateway.igw.id
  }
}

# --- 8. DATA SOURCES & OUTPUTS ---
data "oci_identity_availability_domains" "ads" {
  compartment_id = var.tenancy_ocid
}

# Get the VNIC attachment (needed to find the VNIC ID)
data "oci_core_vnic_attachments" "vm_vnic_attachments" {
  compartment_id = var.compartment_id
  instance_id    = oci_core_instance.ampere_vm.id
}

data "oci_core_private_ips" "vm_private_ip" {
  vnic_id = data.oci_core_vnic_attachments.vm_vnic_attachments.vnic_attachments[0].vnic_id
}

# Update the output to use the reserved IP
output "instance_public_ip" {
  value = oci_core_public_ip.reserved_ip.ip_address
}

# --- 9. RESERVED PUBLIC IP ---
# Reserved (static) public IP
resource "oci_core_public_ip" "reserved_ip" {
  compartment_id = var.compartment_id
  lifetime       = "RESERVED"
  display_name   = "SaaS-Micro-Server-IP"
  private_ip_id  = data.oci_core_private_ips.vm_private_ip.private_ips[0].id
}