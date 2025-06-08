# AWS Minecraft Server Deployment w/ Terraform & Bash

This repository automates the provisioning, configuration, and deployment of a dedicated Minecraft server using **Terraform** and **Bash** on a **Windows** system.

## Background

This project sets up a Minecraft server on AWS EC2. Here's the high-level plan:

- Provision AWS infrastructure with **Terraform**:
  - EC2 instance
  - Security group allowing Minecraft traffic
- Configure the instance via **Bash**:
  - Install Java
  - Download and run the Minecraft server
  - Set up `systemd` to ensure the server starts on boot and shuts down cleanly

The server will be publicly accessible via port `25565`, and will auto-restart on system crash, and gracefully shutdown and restart on reboot.

---

## Requirements

To run this pipeline, you will need the following tools and configurations on your local **Windows** machine.

### Tools to Install

| Tool         | Description                              | Installation Guide                                               |
|--------------|------------------------------------------|------------------------------------------------------------------|
| Terraform    | Infrastructure as Code provisioning tool | [Install Terraform](https://developer.hashicorp.com/terraform/downloads) |
| AWS CLI      | Interact with AWS via terminal           | [Install AWS CLI](https://docs.aws.amazon.com/cli/latest/userguide/install-cliv2.html) |
| Git          | Clone this repo                          | [Install Git](https://git-scm.com/book/en/v2/Getting-Started-Installing-Git) |
| Unix shell   | Git Bash or WSL for Windows users        | [Git Bash for Windows](https://gitforwindows.org/)              |

### AWS Credentials

You'll need AWS access keys. Once you have them, run:

```bash
aws configure
```

This will prompt you to input:

* AWS Access Key ID
* AWS Secret Access Key
* Default region name
* Default output format

Input the Access Key ID and Secret Access Key, leave the last 2 prompts empty.

# Deployment Instructions

## Clone This Repository

```bash
git clone https://github.com/ColtonMelhase/minecraft-aws-server.git
cd minecraft-aws-server
```

## Create an SSH Key Pair w/ AWS CLI

```bash
aws ec2 create-key-pair `
  --key-name minecraft-key `
  --query 'KeyMaterial' `
  --output text | Out-File -Encoding ascii -FilePath minecraft-key.pem
```

## Deploy EC2 Infrastructure w/ Terraform

Run the following commands to initialize Terraform, and build the EC2 instance. Say 'yes' to any prompts.

```bash
terraform init
terraform apply
```

After ```terraform apply``` is completed, it will output the public IP of the Minecraft server that Minecraft clients will use to join, and the Public DNS address that the Bash script will use to SSH into the EC2 instance. Take note of both of these.

## Setup and Configure The Server w/ Bash

Open a Bash terminal, navigate to this repository, and run the ```configure-server.sh``` script giving the public DNS address that was output by Terraform and the link to the Minecraft server jar download of the latest version as parameters.

* To get the URL to the desired version of Minecraft, goto ```https://www.minecraft.net/en-us/download/server``` and copy the address of the latest server jar. 
An example of such URL would be ```https://piston-data.mojang.com/v1/objects/e6ec2f64e6080b9b5d9b471b291c33cc7f509733/server.jar```

```bash
./configure-server.sh <instance_public_dns> <server-jar-url>
```
Example:
```bash
./configure-server.sh ec2-35-90-9-182.us-west-2.compute.amazonaws.com https://piston-data.mojang.com/v1/objects/e6ec2f64e6080b9b5d9b471b291c33cc7f509733/server.jar
```

## Verify The Server is Online

To verify if the service is running in the EC2 instance, run the following command, supplying the instance public ip returned by Terraform

```bash
nmap -sV -Pn -p T:25565 <instance_public_ip>
```

Example
```bash
nmap -sV -Pn -p T:25565 35.90.9.182  
```

If the STATE is **open**, then the server is running!

## Join The Server via a Minecraft Client

Users can now join the server in Minecraft by supplying the Server Address either through the Direct Connection method or by adding a server.

The format of the Server Address will be ```<public_instance_ip>:25565```

Example: ```35.90.9.182:25565```