# Distributed Cloud Computing Learning Project

A hands-on project to learn distributed cloud computing using **Terraform**, **Kubernetes**, **Docker**, **GitHub Actions**, and **Next.js**.

---

## Project Overview

This project serves as a practical learning path for modern cloud infrastructure and DevOps practices. Each phase builds upon the previous, culminating in a fully distributed, containerized application.

---

## 1. Docker: The "Containerize Anything" Project

- Implemented two different Dockerfiles for different deployment targets (Dockerfle.dev and Dockerfile.prod)
- Utilized volumes to mount local source code into the DEV container to allow hot-reloading
- Implemented .devcontainer and .editorconfig to commoditize the developer environment

## 2. GitHub Actions: The "Automatic Gatekeeper" Project

- Implemented testing and linting checks on pull request changes
- Implemented deployment automation to build/deploy Docker image (actual deployment is not there yet, we need Terraform)

## 3. Terraform: The "Clickless Cloud" Project

- Provisioned an OCI **Always Free** ARM VM (`VM.Standard.A1.Flex`) with 4 OCPUs and 24GB RAM using OpenTofu (the open-source Terraform fork, required since Terraform was removed from Alpine Linux's package repositories)
- Used Ubuntu 24.04 aarch64 as the VM image, matching the ARM architecture of the A1.Flex shape
- Configured OCI provider authentication via API key (`tenancy_ocid`, `user_ocid`, `fingerprint`, `private_key_path`)
- Injected SSH public key via instance metadata for passwordless access as the `ubuntu` user
- Created a **Network Security Group (NSG)** attached to the VM's VNIC with rules allowing inbound SSH (TCP 22), inbound ICMP (ping), and unrestricted egress
- Managed the subnet's **default Security List** to mirror the NSG rules at the subnet level (both layers must allow traffic in OCI)
- Created an **Internet Gateway** and configured the VCN's **default Route Table** with a `0.0.0.0/0` route to enable public internet access
- Stored sensitive values (`tenancy_ocid`, key paths, OCIDs) in `terraform.tfvars`, excluded from version control via `.gitignore`

## 4. Kubernetes (K8s): The "Orchestrator" Project

## 5. Distributed Computing: The "Stateful vs. Stateless" Project

## Tech Stack

| Technology     | Purpose                        |
| -------------- | ------------------------------ |
| Next.js        | Frontend application framework |
| Docker         | Containerization               |
| GitHub Actions | CI/CD pipeline                 |
| Terraform      | Infrastructure as Code         |
| Kubernetes     | Container orchestration        |
| Redis          | Stateful data store            |

---

## Getting Started

### Run application inside DEV container

npm run dev
