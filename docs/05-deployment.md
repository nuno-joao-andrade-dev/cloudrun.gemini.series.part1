# 🚀 Deployment & Containerization

How do we get our Go code to the cloud?

## 1. The Dockerfile
We use a **Multi-Stage Build** to keep our production image tiny and secure.

*   **Stage 1 (Builder):** Uses `golang:1.25.6-trixie` (Debian 13). Contains the compiler and build tools. We compile the binary here.
*   **Stage 2 (Runtime):** Uses `debian:trixie-slim`. This is a minimal OS image. We copy *only* the compiled binary from Stage 1.
*   **Result:** A small, secure image without source code or compilers.

## 2. Cloud Build (`gcloud builds submit`)
We don't need Docker installed locally. We zip up our code and send it to Google Cloud Build.
*   Cloud Build runs the `Dockerfile` instructions.
*   It pushes the resulting image to Google Container Registry (`gcr.io`).

## 3. Cloud Run Deployment (`04_part4_deploy.sh`)
This command ties everything together.

```bash
gcloud run deploy go-service \
    --image gcr.io/$PROJECT_ID/go-workshop \
    --network=workshop-vpc \
    --subnet=workshop-subnet \
    ...
```

*   **`--image`**: The image we just built.
*   **`--network` & `--subnet`**: Enables **Direct VPC Egress**. This gives the container an IP address inside our VPC, allowing it to route traffic directly to the Private IP of Cloud SQL.
*   **`--allow-unauthenticated`**: We allow public access *at the Cloud Run level* because we are putting a Load Balancer + Auth Middleware in front of it. (Note: In strict setups, we might use `internal-and-cloud-load-balancing` ingress restriction, which we apply in Part 6).

---
[⬅️ Back to Table of Contents](./README.md)
