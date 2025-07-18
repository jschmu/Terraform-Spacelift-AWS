# AWS Dev Environment Automation with Terraform, GitHub, and Spacelift

This project automates the provisioning of a secure and accessible development environment in AWS using Infrastructure as Code (IaC) principles. It leverages **Terraform** for infrastructure definition, **GitHub** for version control and CI/CD integration, and **Spacelift** for automated plan and apply workflows. The primary goal is to provide a reproducible mechanism for developers to spin up their isolated dev workspaces.

## Table of Contents

- [Features](#features)
- [Architecture Overview](#architecture-overview)
- [Technologies Used](#technologies-used)
- [Project Structure](#project-structure)
- [Getting Started](#getting-started)
  - [Prerequisites](#prerequisites)
  - [Deployment with Spacelift](#deployment-with-spacelift)
  - [Connecting to the Dev Environment](#connecting-to-the-dev-environment)
- [Terraform Modules](#terraform-modules)
  - [Networking Module](#networking-module)
  - [Compute Module](#compute-module)
- [Outputs](#outputs)
- [Contributing](#contributing)
- [License](#license)

## Features

* **Automated AWS Dev Environment Provisioning:** Fully automates the creation of a secure development node and its associated networking infrastructure in AWS.
* **Infrastructure as Code (IaC):** All infrastructure is defined and managed using Terraform, ensuring consistency and version control.
* **CI/CD with Spacelift:** Leverages Spacelift for automated Terraform plan and apply operations, triggered by Git events.
* **Remote-SSH Integration:** Provides a connection script as a Terraform output, enabling seamless connection to the dev environment via VS Code's Remote-SSH extension.
* **Modular Design:** Utilizes Terraform modules (`networking` and `compute`) for better organization, reusability, and maintainability.

## Architecture Overview

The project provisions a development environment consisting of:
* **VPC and Subnets:** A dedicated Virtual Private Cloud (VPC) with a public subnet to host the development instance.
* **Security Groups:** Appropriately configured security groups to control inbound and outbound traffic, ensuring secure access to the development node.
* **EC2 Instance:** An Ubuntu-based EC2 instance acting as the development node.
* **SSH Key Pair:** An AWS Key Pair for secure SSH access to the EC2 instance.

The deployment workflow is handled by Spacelift, which interacts with the Terraform code stored in this GitHub repository to provision and manage the AWS resources.

## Technologies Used

* **Terraform:** For defining, provisioning, and managing the AWS infrastructure.
* **AWS (Amazon Web Services):** The cloud provider for hosting the development environment (EC2, VPC, Security Groups, EC2 Key Pair).
* **GitHub:** Version control for the Terraform code and integration with Spacelift workflows.
* **Spacelift:** An Infrastructure as Code collaboration and automation platform for running Terraform.
* **VS Code (Visual Studio Code):** The recommended IDE for connecting to the remote development environment via Remote-SSH.

## Getting Started

Follow these steps to deploy your development environment.

### Prerequisites

Before you begin, ensure you have the following:

* An AWS account with appropriate permissions to create VPCs, EC2 instances, security groups, and key pairs.
* A GitHub account.
* A Spacelift account configured to integrate with your GitHub repository.
* Terraform CLI installed locally (for local testing/development, though Spacelift handles the primary execution).
* VS Code with the Remote-SSH extension installed.
* An SSH key pair (`mtckey` and `mtckey.pub`) generated on your local machine. The public key (`mtckey.pub`) needs to be accessible by Terraform (e.g., if running locally, ensure the path `/mnt/workspace/mtckey.pub` is correct or adjust the `file()` function in `compute.tf` to point to your key's location). For Spacelift, you would typically manage SSH keys via Spacelift's environment variables or secrets.

### Deployment with Spacelift

1.  **Fork this Repository:** Fork this GitHub repository to your own GitHub account.
2.  **Spacelift Stack Configuration:**
    * In Spacelift, create a new Stack.
    * Connect the Stack to your forked GitHub repository.
    * Set the **Project Root** to the root of this repository.
    * Configure Spacelift to use your AWS credentials (e.g., via IAM Role or Access Keys).
    * Ensure any necessary environment variables are set in Spacelift, especially for the `host_os` variable if it's not hardcoded or automatically determined (e.g., `TF_VAR_host_os = "linux"` or `"windows"`).
    * Crucially, you'll need to provide your SSH public key to Spacelift. This can often be done via a Spacelift secret or environment variable that Terraform can access. The `aws_key_pair.mtc_auth` resource requires the public key content.
3.  **Trigger a Run:**
    * Push a commit to your forked repository. This will trigger a `proposed` run (Terraform Plan) in Spacelift.
    * Review the plan in Spacelift to ensure it aligns with your expectations.
    * Approve the `tracked` run (Terraform Apply) in Spacelift to provision the resources.

### Connecting to the Dev Environment

Once the Spacelift apply is successful, Terraform will output a `connection_script`. This script is designed to add an entry to your local SSH configuration file (`~/.ssh/config`) or provide direct `ssh` command.

1.  **Security Warning!**
    This project uses security group rules allowing open access to port 22 (SSH) from any IP (0.0.0.0/0). This is for testing and learning purposes only. In production or public-facing environments, always restrict access to trusted IP ranges and use proper firewall rules. 

2.  **Retrieve the Connection Script:**
    * Go to the Spacelift run details for your successful `apply`.
    * Look for the `Outputs` section and copy the content of the `connection_script` output.

3.  **Execute the Connection Script (Example for Linux/macOS):**
    If the output is designed to be directly executed (e.g., `echo "Host dev-node..." >> ~/.ssh/config`):
    ```bash
    # Paste the copied connection_script output here and run it
    # Example (output will vary based on your template):
    # echo "Host dev_node" >> ~/.ssh/config
    # echo "  Hostname <PUBLIC_IP_ADDRESS>" >> ~/.ssh/config
    # echo "  User ubuntu" >> ~/.ssh/config
    # echo "  IdentityFile ~/.ssh/mtckey" >> ~/.ssh/config
    ```
    Make sure your private key (`~/.ssh/mtckey`) has the correct permissions (`chmod 400 ~/.ssh/mtckey`).

4.  **Connect via VS Code:**
    * Open VS Code.
    * Press `F1` or `Ctrl+Shift+P` to open the command palette.
    * Type `Remote-SSH: Connect to Host...` and select it.
    * Choose `dev_node` (or whatever hostname you defined in your SSH config).

You should now be connected to your newly provisioned AWS development environment directly from VS Code.

## Terraform Modules

This project is organized into two main Terraform modules to promote reusability and maintainability.

### Networking Module

* **Source:** `./modules/networking`
* **Purpose:** Responsible for creating the core networking infrastructure, including the VPC, public subnets, and security groups required for the development environment.
* **Outputs:**
    * `security_group_id`: The ID of the security group created for the dev node.
    * `subnet_id`: The ID of the public subnet where the dev node will reside.

### Compute Module

* **Source:** `./modules/compute`
* **Purpose:** Responsible for provisioning the EC2 instance (the "dev node") and managing the SSH key pair for access.
* **Inputs:**
    * `security_group_id`: References the output from the `networking` module.
    * `subnet_id`: References the output from the `networking` module.
    * `host_os`: Specifies the operating system of the host machine running the connection script (e.g., "windows" or "linux"). This is used to select the correct SSH configuration template.

* **Key Resources:**
    * `aws_key_pair.mtc_auth`: Creates an AWS EC2 Key Pair using your provided public key.
    * `aws_instance.dev_node`: Provisions the EC2 instance, attaching the security group, subnet, and key pair. It also uses a `user_data` script for initial setup of the instance.

## Outputs

The main Terraform configuration provides a crucial output:

* `connection_script`: This output provides a shell script (or PowerShell script for Windows) that, when executed, configures your local SSH client to connect to the newly created `dev_node` in AWS. It includes the hostname (public IP), user (`ubuntu`), and identity file path.

```terraform
output "connection_script" {
  value = templatefile("${var.host_os}-ssh-config.tpl", {
    hostname = aws_instance.dev_node.public_ip,
    user     = "ubuntu",
    identityfile = "~/.ssh/mtckey"
  })
  description = "Script to connect to the dev environment via SSH"
}