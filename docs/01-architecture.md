# 🏗️ Architecture Deep Dive

This document explains the high-level architecture of the "Fortified Go" microservice.

## The Problem with Default Deployments

By default, deploying a Cloud Run service creates a public URL (e.g., `https://service-xyz.run.app`). While convenient, this has significant security implications:
1.  **Direct Exposure:** Anyone can hit your service directly, bypassing any edge security you might have set up elsewhere.
2.  **Public Database:** Often, tutorials instruct you to give your database a public IP to make connections easier. This exposes your database port to the entire internet, relying solely on password strength.

## Our Fortified Approach

We take a "Security by Design" approach.

### 1. The Virtual Private Cloud (VPC)
We create a custom VPC (`workshop-vpc`) and Subnet. This acts as our private network boundary.
*   **Private Service Access:** We peer this VPC with Google's managed services network. This allows our resources to talk to Cloud SQL privately.

### 2. Private Cloud SQL
Our PostgreSQL database (`workshop-db`) is deployed with **No Public IP**. It effectively disappears from the internet.
*   **Connectivity:** It is only accessible from within the VPC (e.g., by Cloud Run) or via the secure Cloud SQL Auth Proxy (which acts as a secure tunnel).

### 3. Cloud Run & Direct VPC Egress
Our Go service runs on Cloud Run. We configure it with **Direct VPC Egress** attached to our `workshop-vpc`. This allows the serverless container to "reach into" our private network and talk to the database on its private IP (`10.x.x.x`).

### 4. The Global Load Balancer (GLB)
Instead of exposing Cloud Run directly, we place a Global External Application Load Balancer in front of it.
*   **Benefits:** Single Anycast IP, SSL termination, and the ability to attach security policies.

### 5. Cloud Armor (WAF)
This is our shield. Cloud Armor is attached to the Load Balancer.
*   **Capabilities:** We configure rules to block SQL Injection (`sqli-stable`) and can easily add rules for Geo-blocking, Rate Limiting, or IP blocklisting.
*   **Effect:** Malicious traffic is stopped at the Google Edge, never reaching our application or incurring compute costs on Cloud Run.

### 6. Restricted Ingress (`internal-and-cloud-load-balancing`)
We configure Cloud Run to **deny** all traffic that doesn't come from the Load Balancer or the VPC. If someone tries to bypass Cloud Armor and hit the `run.app` URL directly, they get a `403 Forbidden`.

---
[⬅️ Back to Table of Contents](./README.md)
