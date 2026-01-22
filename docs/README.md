# 📚 Documentation: Fortified Go Microservice on GCP

Welcome to the detailed documentation for the Gemini Workshop Series (Part 1). This folder contains in-depth guides for every aspect of the workshop.

## Table of Contents

### 1. [Architecture Deep Dive](./01-architecture.md)
*   The "Why" behind the design.
*   Understanding the VPC, Private IP, and Direct VPC Egress.
*   How Cloud Armor and Load Balancing work together.

### 2. [Prerequisites & Setup](./02-prerequisites.md)
*   Required tools (Go, gcloud, Cloud SQL Proxy).
*   Explanation of the automated setup scripts.

### 3. [Infrastructure as Code (Bash Scripts)](./03-infrastructure.md)
*   Detailed breakdown of the `00-99` scripts.
*   Explanation of critical `gcloud` flags used for networking and security.

### 4. [The Application Code (Go)](./04-application.md)
*   Code structure (`handlers`, `middleware`, `models`).
*   Dependency Injection pattern.
*   Basic Authentication middleware implementation.
*   Unit testing with `go-sqlmock`.

### 5. [Deployment & Containerization](./05-deployment.md)
*   Multi-stage `Dockerfile` explanation.
*   Cloud Build process.
*   Cloud Run deployment details (VPC connections).

### 6. [Security & Hardening](./06-security.md)
*   Principle of Least Privilege (IAM).
*   Network Isolation strategies.
*   Cloud Armor WAF rules (`sqli-stable`).
*   Ingress restrictions.

---
[⬅️ Back to Main README](../README.md)
