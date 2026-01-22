# 🏗️ Infrastructure as Code (Bash Scripts)

This workshop uses modular Bash scripts to provision infrastructure. This approach mimics "Infrastructure as Code" principles, making the deployment reproducible and documenting every flag used.

## Script Breakdown

### 1. Environment & Auth (`01_part1_01...` - `01_part1_02...`)
*   Sets critical variables: `PROJECT_ID`, `REGION`, `DB_PASS`.
*   Handles authentication: `gcloud auth login` with `--no-launch-browser` support for headless environments.

### 2. Network & Database (`01_part1_04_create_db.sh`)
This is a heavy-lifter script.
*   **VPC Creation:** Creates `workshop-vpc` and `workshop-subnet`.
*   **Peering:** Allocates an IP range (`google-managed-services-default`) and peers it with `servicenetworking`. This is the "pipe" that lets Cloud SQL live in our VPC.
*   **Database Creation:** Creates the PostgreSQL instance with:
    *   `--tier=db-f1-micro`: Cost-effective tier.
    *   `--edition=ENTERPRISE`: Required to use the micro tier.
    *   `--network=workshop-vpc`: Places it in our private network.
    *   `--no-assign-ip`: **Crucial.** Disables the public IP entirely.

### 3. Load Balancer (`05_part5_create_lb.sh`)
Builds a global HTTP(S) Load Balancer.
*   **Serverless NEG:** Creates a "Network Endpoint Group" that points to our Cloud Run service.
*   **Backend Service:** Connects the NEG to the Load Balancer.
*   **URL Map & Proxy:** Defines routing rules (send everything to the backend).
*   **Forwarding Rule:** The "Front Door" that gives us a global IP address.

### 4. Cloud Armor (`06_part6_...`)
*   **Policy Creation:** Creates `workshop-armor-policy`.
*   **Rules:**
    *   `priority 1000`: Allow legitimate traffic.
    *   `priority 9000`: Block SQL Injection using the pre-configured `sqli-stable` signature set.
*   **Activation:** Attaches this policy to the `workshop-backend`.

---
[⬅️ Back to Table of Contents](./README.md)
