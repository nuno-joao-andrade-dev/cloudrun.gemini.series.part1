# 📋 Prerequisites & Setup

To build this microservice, you need a specific set of tools. We have automated this for Linux and macOS, but it's important to understand what is being installed.

## The Tools

### 1. Go (1.25.6+)
The core language for our microservice. We use version 1.25.6 (or newer) to leverage the latest features and security patches.

### 2. Google Cloud SDK (`gcloud`)
The Command Line Interface (CLI) for interacting with GCP. We use it to create every resource, from the database to the load balancer.

### 3. Cloud SQL Auth Proxy
A crucial tool for secure development. Since our database has no public IP, we cannot connect to it directly from our laptop's `psql` client.
*   **How it works:** The proxy creates a secure tunnel (using IAM permissions) from `localhost` to the Cloud SQL instance. We connect to `localhost`, and the proxy forwards traffic securely to the cloud.

### 4. PostgreSQL Client (`psql`)
Used to run the initial SQL scripts (`seed.sql`) to create users and tables.

## Automated Setup Scripts

We provide scripts to verify and install these dependencies. They include user confirmation prompts for safety.

*   **Linux:** `00_prerequisites_setup_linux.sh`
*   **macOS:** `00_prerequisites_setup_mac.sh`

Usage:
```bash
chmod +x 00_prerequisites_setup_linux.sh
./00_prerequisites_setup_linux.sh
```

---
[⬅️ Back to Table of Contents](./README.md)
