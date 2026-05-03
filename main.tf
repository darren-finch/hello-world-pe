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
variable "subnet_id" {
  description = "The OCID of the public subnet from your VCN Wizard"
}
variable "vcn_id" {
  description = "The OCID of the VCN from your VCN Wizard"
}
variable "default_security_list_id" {
  description = "The OCID of the default security list from your VCN Wizard subnet"
}
variable "default_route_table_id" {
  description = "The OCID of the default route table from your VCN"
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

# --- 3. THE "ALWAYS FREE" VM ---
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
    subnet_id        = var.subnet_id
    assign_public_ip = true
    nsg_ids          = [oci_core_network_security_group.vm_nsg.id]
  }

  metadata = {
    ssh_authorized_keys = file(var.ssh_public_key_path)
  }
}

# --- 4. SUBNET SECURITY LIST ---
resource "oci_core_default_security_list" "default" {
  manage_default_resource_id = var.default_security_list_id

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

  egress_security_rules {
    protocol    = "all"
    destination = "0.0.0.0/0"
    stateless   = false
  }
}

# --- 5. NETWORK SECURITY GROUP ---
resource "oci_core_network_security_group" "vm_nsg" {
  compartment_id = var.compartment_id
  vcn_id         = var.vcn_id
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

resource "oci_core_network_security_group_security_rule" "allow_all_egress" {
  network_security_group_id = oci_core_network_security_group.vm_nsg.id
  direction                 = "EGRESS"
  protocol                  = "all"
  destination               = "0.0.0.0/0"
  destination_type          = "CIDR_BLOCK"
}

# --- 6. INTERNET GATEWAY & ROUTE TABLE ---
resource "oci_core_internet_gateway" "igw" {
  compartment_id = var.compartment_id
  vcn_id         = var.vcn_id
  display_name   = "SaaS-Micro-Server-IGW"
  enabled        = true
}

resource "oci_core_default_route_table" "default" {
  manage_default_resource_id = var.default_route_table_id

  route_rules {
    destination       = "0.0.0.0/0"
    destination_type  = "CIDR_BLOCK"
    network_entity_id = oci_core_internet_gateway.igw.id
  }
}

# --- 7. DATA SOURCES & OUTPUTS ---
data "oci_identity_availability_domains" "ads" {
  compartment_id = var.tenancy_ocid
}

output "instance_public_ip" {
  value = oci_core_instance.ampere_vm.public_ip
}