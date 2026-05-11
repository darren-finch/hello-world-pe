# Distributed Cloud Computing Learning Project

A hands-on project to learn distributed cloud computing using **Terraform**, **Kubernetes**, **Docker**, **GitHub Actions**, and **Next.js**.

---

## Project Overview

This project serves as a practical learning path for modern cloud infrastructure and DevOps practices. Each phase builds upon the previous, culminating in a fully distributed, containerized application.

---

## 1. Docker: The "Containerize Anything" Project

- Implemented two different Dockerfiles for different deployment targets (_Dockerfle.dev_ and _Dockerfile.prod_)
- Utilized volumes to mount local source code into the DEV container to allow hot-reloading
- Implemented .devcontainer and .editorconfig to commoditize the developer environment

## 2. GitHub Actions: The "Automatic Gatekeeper" Project

- Implemented testing and linting checks on pull request changes
- Implemented deployment automation to build/deploy Docker image

## 3. Terraform: The "Clickless Cloud" Project

- Provisioned an Ubuntu 24.04 aarch64 (ARM) OCI Ampere VM _(VM.Standard.A1.Flex)_ with 4 OCPUs and 24 GB of RAM
- Provisioned a public IP resource with a runtime reference to the VM's private IP so the IP is not ephemeral (without this OCI will return the VM to the object pool after some time, resulting in the IP being invalid)
- Provisioned a VCN (Virtual Cloud Network) named _SaaS-Micro-Server-VCN_ and corresponding subnet _SaaS-Micro-Server-Subnet_ with default route table rules
- Provisioned an NSG attached to the VM's VNIC (Virtual Network Interface Card) with firewall rules allowing SSH, ICMP, HTTP, HTTPS, K3s API, and all egress traffic.
- Applied same firewall rules to default Security List and applied the security list to the VCN's subnet
- Applied routing rule to _SaaS-Micro-Server-Subnet_'s default routing table to allow all outbound traffic
- Provisioned an Internet Gateway so the VCN has internet access
- Used terraform.tfvars to configure secrets
- Created a _cloud-init.sh_ Bash script which runs on VM startup initializes Docker and K3s, opens the iptables firewall rules to allow the same traffic as previously discussed, and uses the _iptables-persistent_ package to persist the iptable rules across VM restarts.

## 4. Kubernetes (K8s): The "Orchestrator" Project

- Created _deployment.yaml_, which specifies the labels and spec for the Pods that will run the application's Docker container. It also specifies two replicas should be created on the VM for simulated redundancy (real-world redundancy would require more nodes) and that the expected port for the app is 3000.
- Created _ingress.yaml_, which contains routing rules for _Traefik_ so it knows which K3s Service to route traffic to. In our case we're sending incoming traffic from port 80 (HTTP) to the _hello-world-pe-svc_, which is the main Service for our application defined in service.yaml.
- Created _service.yaml_, which defines essentially a name associated with a stable internal IP (A Service IP or _ClusterIP_) which is stored in _CoreDNS_ for Traefik to route traffic to. From there kube-proxy updates the iptables NAT config with INPUT rule for ClusterIP -> real Pod IP.

## 5. Distributed Computing: The "Stateful vs. Stateless" Project

- Implemented a K3s Redis Service with a _PersistentVolume_, allowing the Redis snapshot to persist across VM reboots
- Provised 1 gigabyte of storage to the volume
- Updated Next.js application to have a simple routes at _/api/counter_ (GET to get current value and POST to increment).
- Created _LEARNING_WITH_AI.md_, summarizing what I learned about learning with AI throughout this project
- Fixed README.md to reflect what I did with Terraform and K3s in my own words, so I can understand the full picture of the components involved in the project.

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

To run the application, just navigate to the project in your host's terminal (not in the dev container) and run `docker compose up --build`.

To stop, Ctrl + C in the terminal window.

To remove the stopped containers, run `docker compose down` or `docker compose down -v` to remove the Redis volume as well.
