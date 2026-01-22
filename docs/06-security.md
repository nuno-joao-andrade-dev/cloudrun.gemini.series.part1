# 🔒 Security & Hardening

Security is the primary theme of this workshop. Here is how we fortified the microservice.

## 1. Principle of Least Privilege (IAM)
We created a dedicated Service Account (`workshop-sa`) and granted it *only* `roles/cloudsql.client`.
*   **Impact:** If the container is compromised, the attacker can only talk to Cloud SQL. They cannot spin up VMs, delete buckets, or access other sensitive API data.

## 2. Network Isolation (Private IP)
The database has **no public IP address**.
*   **Impact:** It is completely invisible to port scanners and bots on the internet. The only way to reach it is from inside the VPC (Cloud Run) or via the authorized Proxy tunnel.

## 3. Web Application Firewall (Cloud Armor)
We attached a security policy to our Load Balancer.
*   **Rule `sqli-stable`:** Analyzes incoming requests for SQL Injection patterns (e.g., `' OR 1=1`).
*   **Impact:** Exploits are blocked at the edge. The request never reaches our Go application logic.

## 4. Ingress Restriction
We ran:
```bash
gcloud run services update go-service --ingress internal-and-cloud-load-balancing
```
*   **Impact:** This ensures users cannot bypass the Load Balancer (and Cloud Armor) by guessing the `*.run.app` URL. The service will only accept traffic that has passed through our specific Global Load Balancer.

## 5. Container Security
*   **Distroless/Slim Images:** Using `debian:trixie-slim` reduces the attack surface by minimizing the number of installed packages in the runtime environment.
*   **Non-Root:** (Enhancement for future) We typically run the Go binary as a non-root user inside the container for added isolation.

---
[⬅️ Back to Table of Contents](./README.md)
