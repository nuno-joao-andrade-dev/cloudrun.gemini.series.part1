Here is the comprehensive, end-to-end workshop guide. This text is designed to be copied directly into a `README.md` file or distributed as a workshop handbook.

It includes the **refactored Go code** (dependency injection pattern) to ensure the AI-generated unit tests work seamlessly.

---

# 🚀 Gemini Workshop Series: Microservices on GCP (Part 1/3 - Fortified) — Securing Go with Cloud SQL & Cloud Armor

**Objective:** Build a production-ready Go microservice that connects to Cloud SQL (Postgres), expose it via a Global Load Balancer, and secure it with Cloud Armor Web Application Firewall (WAF).

> 💡 **Note:** This is the first installment of a workshop series that evolves from a basic microservice to a complex architecture featuring distributed caching, advanced authentication, inter-service communication, and **deep database hardening**.

## 📖 Preface: The "Why" Behind The Architecture

Before we dive into the code, let's understand the architectural decisions driving this workshop. This guide is designed not just to "get it working," but to "get it working securely and scalably."

### 1. Dedicated Service Account
We create a specific Service Account (`workshop-sa`) instead of using the default Compute Engine account. This adheres to the **Principle of Least Privilege**. By granting only `roles/cloudsql.client`, we ensure that if this service is compromised, the attacker cannot access other resources (like Storage Buckets or other VMs) that the default account might have permission to.

### 2. Basic Authentication (vs. JWT)
We start with Basic Authentication to focus on the middleware pattern without the complexity of token management. **Note:** In future sessions of this series, we will evolve this to **JWT (JSON Web Tokens)** backed by a shared memory store (like Redis) for robust, stateless session management across multiple microservices.

### 3. Code Organization (Dependency Injection)
The code is structured into `models`, `handlers`, and `middleware`. This separation of concerns, combined with **Dependency Injection** (passing the DB connection into the handler), allows us to:
*   Keep logic clean and maintainable.
*   **Mock dependencies** easily. As seen in the "AI-Assisted Testing" section, we can test our API logic without needing a running database.

### 4. Global Load Balancer & Cloud Armor
Cloud Run exposes a public URL by default, but for production, we need more control.
*   **Load Balancer:** Provides a single global IP, handles SSL termination, and allows us to route traffic intelligently.
*   **Cloud Armor:** Acts as our Web Application Firewall (WAF). Attaching it to the Load Balancer allows us to block malicious traffic (like SQL Injection attempts) *at the edge*, before it ever reaches our application.

### 5. Restricting Ingress
By setting the ingress to `internal-and-cloud-load-balancing`, we effectively "close the backdoor." Users cannot bypass our security controls (Cloud Armor) by hitting the Cloud Run URL directly. Traffic *must* pass through the Load Balancer to reach the service.

## 📋 Prerequisites

* [Go 1.25.6+](https://go.dev/dl/) installed.
* [Google Cloud SDK (`gcloud`)](https://www.google.com/search?q=%5Bhttps://cloud.google.com/sdk/docs/install%5D(https://cloud.google.com/sdk/docs/install)) installed and authenticated.
* [Cloud SQL Auth Proxy](https://cloud.google.com/sql/docs/postgres/sql-proxy#install) installed.
* [PostgreSQL Client (`psql`)](https://www.postgresql.org/download/) installed.
* **Billing enabled** on your Google Cloud Project.

### Automated Setup
You can create a `setup.sh` file with the following content to verify and install dependencies (Linux):

```bash
#!/bin/bash
set -e

echo "🛠️  Checking and Installing Dependencies..."

read -p "This script will install Go 1.25.6, Google Cloud SDK, Cloud SQL Proxy, and PostgreSQL Client. Do you want to proceed? (y/N) " response
if [[ ! "$response" =~ ^([yY][eE][sS]|[yY])$ ]]; then
    echo "Aborting installation."
    exit 1
fi

# 1. Install Go (Linux/amd64 example)
if ! command -v go &> /dev/null; then
    echo "❌ Go not found. Attempting to install Go 1.25.6..."
    wget -q https://go.dev/dl/go1.25.6.linux-amd64.tar.gz
    sudo rm -rf /usr/local/go && sudo tar -C /usr/local -xzf go1.25.6.linux-amd64.tar.gz
    rm go1.25.6.linux-amd64.tar.gz
    # Update PATH for this session
    export PATH=$PATH:/usr/local/go/bin
    echo "✅ Go installed. (Remember to add /usr/local/go/bin to your PATH permanently)"
else
    echo "✅ Go is already installed."
fi

# 2. Install gcloud
if ! command -v gcloud &> /dev/null; then
    echo "❌ gcloud CLI not found."
    echo "📥 Installing Google Cloud SDK..."
    # Non-interactive install
    curl https://sdk.cloud.google.com | bash -s -- --disable-prompts
    echo "✅ Google Cloud SDK installed. Please restart your shell or source the path file."
else
    echo "✅ gcloud is already installed."
fi

# 3. Cloud SQL Proxy
if [ ! -f ./cloud-sql-proxy ]; then
    echo "📥 Downloading Cloud SQL Auth Proxy..."
    curl -o cloud-sql-proxy https://storage.googleapis.com/cloud-sql-connectors/cloud-sql-proxy/v2.8.0/cloud-sql-proxy.linux.amd64
    chmod +x cloud-sql-proxy
    echo "✅ Cloud SQL Auth Proxy installed."
else
    echo "✅ Cloud SQL Auth Proxy is present."
fi

# 4. PostgreSQL Client
if ! command -v psql &> /dev/null; then
    echo "📥 Installing PostgreSQL Client..."
    if [ -f /etc/debian_version ]; then
        sudo apt-get update && sudo apt-get install -y postgresql-client
    elif [ -f /etc/redhat-release ]; then
        sudo yum install -y postgresql
    else
        echo "⚠️  OS not detected. Please install 'postgresql-client' manually."
    fi
else
    echo "✅ psql is already installed."
fi

echo "🎉 Dependency check complete!"
```

Then run:
```bash
chmod +x setup.sh
./setup.sh
```

### Automated Setup (macOS)
You can create a `setup_mac.sh` file with the following content to verify and install dependencies (macOS):

```bash
#!/bin/bash
set -e

echo "🛠️  Checking and Installing Dependencies (macOS)..."

read -p "This script will check/install Homebrew, Go (latest), Google Cloud SDK, Cloud SQL Proxy, and PostgreSQL Client. Do you want to proceed? (y/N) " response
if [[ ! "$response" =~ ^([yY][eE][sS]|[yY])$ ]]; then
    echo "Aborting installation."
    exit 1
fi

# 0. Install Homebrew if missing
if ! command -v brew &> /dev/null; then
    echo "❌ Homebrew not found. Installing..."
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
    echo "✅ Homebrew installed."
else
    echo "✅ Homebrew is already installed."
fi

# 1. Install Go
if ! command -v go &> /dev/null; then
    echo "❌ Go not found. Installing via Homebrew..."
    brew install go
    echo "✅ Go installed."
else
    echo "✅ Go is already installed."
fi

# 2. Install gcloud
if ! command -v gcloud &> /dev/null; then
    echo "❌ gcloud CLI not found. Installing via Homebrew..."
    brew install --cask google-cloud-sdk
    echo "✅ Google Cloud SDK installed."
else
    echo "✅ gcloud is already installed."
fi

# 3. Cloud SQL Proxy
if [ ! -f ./cloud-sql-proxy ]; then
    echo "📥 Downloading Cloud SQL Auth Proxy..."
    curl -o cloud-sql-proxy https://storage.googleapis.com/cloud-sql-connectors/cloud-sql-proxy/v2.8.0/cloud-sql-proxy.darwin.amd64
    chmod +x cloud-sql-proxy
    echo "✅ Cloud SQL Auth Proxy installed."
else
    echo "✅ Cloud SQL Auth Proxy is present."
fi

# 4. PostgreSQL Client
if ! command -v psql &> /dev/null; then
    echo "📥 Installing PostgreSQL Client..."
    brew install libpq
    # Link libpq to path if needed (instructional)
    echo "⚠️  Ensure libpq is in your PATH: export PATH=\"/usr/local/opt/libpq/bin:\$PATH\""
else
    echo "✅ psql is already installed."
fi

echo "🎉 Dependency check complete!"
```

Then run:
```bash
chmod +x setup_mac.sh
./setup_mac.sh
```

---

## 🛠️ Part 1: The Foundation (Database)

We start by creating the storage layer. We will use Cloud SQL (PostgreSQL).

### 1. Environmental Setup

Open your terminal and set these variables to save time later.

```bash
export PROJECT_ID="your-project-id-here"
export REGION="us-central1"
export DB_PASS="<YOUR_SECURE_PASSWORD>" # ⚠️ CHANGE THIS!
export INSTANCE_NAME="workshop-db"

gcloud config set project $PROJECT_ID
```

### 2. Authentication

Log in to Google Cloud and set up application default credentials.

```bash
gcloud auth login --no-launch-browser
gcloud auth application-default login --project $PROJECT_ID --no-launch-browser
```

> 💡 **Note:** In some Linux environments or when using certain terminal emulators, you may need to prefix the commands with `DISPLAY=":0"` if you encounter issues with browser-based flows even with the `--no-launch-browser` flag (e.g., `DISPLAY=":0" gcloud auth login ...`).

### 3. Enable Google Cloud APIs

```bash
gcloud services enable \
    sqladmin.googleapis.com \
    run.googleapis.com \
    compute.googleapis.com \
    servicenetworking.googleapis.com \
    logging.googleapis.com

```

### 4. Network Setup

We need a secure private network (VPC) for our services to communicate.

```bash
# 1. Create VPC and Subnet
gcloud compute networks create workshop-vpc --subnet-mode=custom
gcloud compute networks subnets create workshop-subnet \
    --network=workshop-vpc \
    --range=10.0.0.0/24 \
    --region=$REGION

# 2. Configure Private Service Access (for Cloud SQL)
gcloud compute addresses create google-managed-services-default \
    --global \
    --purpose=VPC_PEERING \
    --prefix-length=16 \
    --network=workshop-vpc

gcloud services vpc-peerings connect \
    --service=servicenetworking.googleapis.com \
    --ranges=google-managed-services-default \
    --network=workshop-vpc
```

### 5. Create Database Instance & User

*Note: This step takes 5-10 minutes.*

```bash
# Create the instance
gcloud sql instances create $INSTANCE_NAME \
    --database-version=POSTGRES_16 \
    --tier=db-f1-micro \
    --edition=ENTERPRISE \
    --region=$REGION \
    --root-password=$DB_PASS \
    --network=workshop-vpc \
    --no-assign-ip

# Create the specific database
gcloud sql databases create users_db --instance=$INSTANCE_NAME

```

### 6. Seed the Data

Since we disabled the public IP, we cannot connect directly from our local machine easily without a Bastion host. For this workshop, we will temporarily re-enable the public IP to seed data, then turn it off.

1. **Enable Public IP (Temporarily):**
```bash
gcloud sql instances patch $INSTANCE_NAME --assign-ip
```

2. **Start the Proxy:**
   Open a new terminal window and run:
```bash
./cloud-sql-proxy --port=5433 $PROJECT_ID:$REGION:$INSTANCE_NAME

```
   *Note: We use port 5433 to avoid conflicts if you have a local PostgreSQL instance running on the default port 5432.*
   *Wait until you see "Ready for new connections".*

2. **Connect & Run SQL:** 
   In your original terminal, connect via the proxy (localhost) on port 5433:
```bash
PGPASSWORD=$DB_PASS psql \
    --host=127.0.0.1 \
    --port=5433 \
    --username=postgres \
    --dbname=postgres

```

3. **Run SQL Commands:** (Paste this when you see the `postgres=>` prompt)
```sql
-- 1. Create the application user (run as postgres)
CREATE USER go_workshop WITH PASSWORD '<YOUR_SECURE_PASSWORD>';

-- 2. Make the user the owner of the database
ALTER DATABASE users_db OWNER TO go_workshop;

-- 3. Connect to the database
\c users_db;

-- 4. Grant Schema level permissions (Critical for creating new objects)
GRANT ALL ON SCHEMA public TO go_workshop;

-- 5. Create the table
CREATE TABLE IF NOT EXISTS users (
    id SERIAL PRIMARY KEY,
    username VARCHAR(50) NOT NULL UNIQUE,
    email VARCHAR(100) NOT NULL
);

-- 5. Ensure the application user owns the table and schema objects
ALTER TABLE users OWNER TO go_workshop;
GRANT ALL PRIVILEGES ON ALL SEQUENCES IN SCHEMA public TO go_workshop;

-- 6. Insert data
INSERT INTO users (username, email) VALUES 
    ('cloud_runner', 'runner@example.com'),
    ('gopher_fan', 'go@example.com'),
    ('secure_armor', 'shield@example.com')
ON CONFLICT (username) DO NOTHING;
```


5. **Exit:** Type `\q` and hit Enter. You can now stop the proxy in the other window.

6. **Disable Public IP:**
```bash
gcloud sql instances patch $INSTANCE_NAME --no-assign-ip
```


---

## 💻 Part 2: The Application (Go)

We will write a Go service using **Dependency Injection** and a clean directory structure. This makes the code maintainable and allows us to mock the database for unit testing.

### 1. Initialize Project

```bash
mkdir go-workshop && cd go-workshop
go mod init github.com/youruser/go-workshop

# Create directory structure
mkdir models handlers middleware

# Install Dependencies
go get github.com/jackc/pgx/v4
go get github.com/DATA-DOG/go-sqlmock # For testing later

```

### 2. The Model (`models/user.go`)

Create `models/user.go` to define our data structures.

```go
package models

// User represents our database model
type User struct {
	ID       int
	Username string
	Email    string
}
```

### 3. The Middleware (`middleware/basic_auth.go`)

Create `middleware/basic_auth.go` to handle authentication separately.

```go
package middleware

import (
	"net/http"
)

// BasicAuth wraps an http.Handler to provide authentication
type BasicAuth struct {
	Username string
	Password string
	Next     http.Handler
}

func (m *BasicAuth) ServeHTTP(w http.ResponseWriter, r *http.Request) {
	user, pass, ok := r.BasicAuth()
	if !ok || user != m.Username || pass != m.Password {
		w.Header().Set("WWW-Authenticate", `Basic realm="Restricted"`)
		http.Error(w, "Unauthorized", http.StatusUnauthorized)
		return
	}
	m.Next.ServeHTTP(w, r)
}
```

### 4. The Handler (`handlers/user_handler.go`)

Create `handlers/user_handler.go`. The `UserHandler` struct holds the DB connection.

```go
package handlers

import (
	"database/sql"
	"encoding/json"
	"log"
	"net/http"

	"github.com/youruser/go-workshop/models"
)

// UserHandler holds dependencies (like the DB)
type UserHandler struct {
	DB *sql.DB
}

// ServeHTTP implements the http.Handler interface
func (h *UserHandler) ServeHTTP(w http.ResponseWriter, r *http.Request) {
	// 1. Health/Ping Check
	if err := h.DB.Ping(); err != nil {
		http.Error(w, "Database Disconnected ❌", http.StatusInternalServerError)
		log.Printf("Ping error: %v", err)
		return
	}

	// 2. Query Data
	rows, err := h.DB.Query("SELECT id, username, email FROM users LIMIT 10")
	if err != nil {
		http.Error(w, "Query Failed", http.StatusInternalServerError)
		log.Printf("Query error: %v", err)
		return
	}
	defer rows.Close()

	// 3. Collect Data
	var users []models.User
	for rows.Next() {
		var u models.User
		if err := rows.Scan(&u.ID, &u.Username, &u.Email); err != nil {
			log.Printf("Scan error: %v", err)
			continue
		}
		users = append(users, u)
	}

	// 4. Render JSON Response
	w.Header().Set("Content-Type", "application/json")
	if err := json.NewEncoder(w).Encode(users); err != nil {
		http.Error(w, "Encoding Failed", http.StatusInternalServerError)
		log.Printf("JSON error: %v", err)
		return
	}
}
```

### 5. The Entry Point (`main.go`)

Create `main.go` in the root directory. It handles the connection logic and starts the server.

```go
package main

import (
	"database/sql"
	"fmt"
	"log"
	"net/http"
	"os"
	"time"

	_ "github.com/jackc/pgx/v4/stdlib"
	"github.com/youruser/go-workshop/handlers"
	"github.com/youruser/go-workshop/middleware"
)

func main() {
	// 1. Connect (Standard Postgres)
	dsn := fmt.Sprintf("host=%s port=%s user=%s password=%s dbname=%s sslmode=disable",
		os.Getenv("DB_HOST"),
		os.Getenv("DB_PORT"),
		os.Getenv("DB_USER"),
		os.Getenv("DB_PASS"),
		os.Getenv("DB_NAME"),
	)
	db, err := sql.Open("pgx", dsn)
	if err != nil {
		log.Fatalf("Could not connect to DB: %v", err)
	}

	// 2. Configure Pool (Critical for Cloud Run)
	db.SetMaxOpenConns(5)
	db.SetMaxIdleConns(5)
	db.SetConnMaxLifetime(30 * time.Minute)

	// 3. Start Server
	userHandler := &handlers.UserHandler{DB: db}
	
	// Wrap with Authentication Middleware
	authHandler := &middleware.BasicAuth{
		Username: os.Getenv("AUTH_USER"),
		Password: os.Getenv("AUTH_PASS"),
		Next:     userHandler,
	}

	port := os.Getenv("PORT")
	if port == "" {
		port = "8080"
	}
	
	log.Printf("Listening on port %s", port)
	if err := http.ListenAndServe(":"+port, authHandler); err != nil {
		log.Fatal(err)
	}
}
```

### 6. The Dockerfile (`Dockerfile`)

Create a `Dockerfile` in the root of your `go-workshop` directory. This is used by Cloud Build to package your application.

```dockerfile
# Stage 1: Build
FROM golang:1.25.6-trixie as builder

WORKDIR /app

# Copy dependency files
COPY go.mod go.sum ./
RUN go mod download

# Copy source code
COPY . .

# Build the binary
RUN CGO_ENABLED=0 GOOS=linux go build -v -o server .

# Stage 2: Runtime environment
FROM debian:trixie-slim
RUN apt-get update && apt-get install -y ca-certificates && rm -rf /var/lib/apt/lists/*

# Copy the binary from the builder stage
COPY --from=builder /app/server /app/server

# Run the web service on container startup
CMD ["/app/server"]
```

---

## 🏠 Part 2.5: Running Locally

Before deploying to the cloud, you can run the service on your local machine. **Important:** Since our database is Private IP only, we must temporarily enable the Public IP to connect from our local machine.

### 1. Enable Public IP
```bash
gcloud sql instances patch $INSTANCE_NAME --assign-ip
```

### 2. Start Cloud SQL Auth Proxy (**Optional**/Verification)
The Go application uses the built-in connector, but you can run the proxy to verify connectivity.

```bash
./cloud-sql-proxy --port=5433 $PROJECT_ID:$REGION:$INSTANCE_NAME
```

### 3. Set Local Environment Variables

In your main terminal, set the environment variables. **Note:** If you are in a new terminal, you must first set the project variables from Part 1.

```bash
# 1. Project Base Variables (Ensure these match Part 1)
export PROJECT_ID="your-project-id-here"
export REGION="us-central1"
export INSTANCE_NAME="workshop-db"

# 2. Database Connection Variables
export DB_HOST="127.0.0.1" # Connect via local proxy
export DB_PORT="5433"
export DB_USER="go_workshop"
export DB_PASS="<YOUR_SECURE_PASSWORD>"
export DB_NAME="users_db"

# 3. Application Auth & Port
export AUTH_USER="admin"
export AUTH_PASS="<YOUR_AUTH_PASSWORD>"
export PORT="8080"
```

### 4. Run the Application

```bash
go run main.go
```

*Don't forget to disable the Public IP when done!*
```bash
gcloud sql instances patch $INSTANCE_NAME --no-assign-ip
```

### 5. Test with Curl

Open a new terminal and run this test script:

```bash
# Verify the service is responding (using Basic Auth)
curl -i -u admin:<YOUR_AUTH_PASSWORD> http://localhost:8080/

# Expected Output: A 200 OK response with the HTML list of users.
```

---

## 🤖 Part 3: AI-Assisted Testing

We will generate unit tests for our handler using mocking.

### 1. The Prompt

If you were using Gemini (or ChatGPT/Claude), you would use this prompt:

> *"Generate a `handlers/user_handler_test.go` file for the provided Go code. Use `net/http/httptest` and `github.com/DATA-DOG/go-sqlmock`. Create table-driven tests for the `ServeHTTP` method of `UserHandler`."*

### 2. The Result (`handlers/user_handler_test.go`)

Create `handlers/user_handler_test.go` with this content:

```go
package handlers

import (
	"errors"
	"net/http"
	"net/http/httptest"
	"regexp"
	"strings"
	"testing"

	"github.com/DATA-DOG/go-sqlmock"
)

func TestUserHandler_ServeHTTP(t *testing.T) {
	// 1. Mock DB
	db, mock, err := sqlmock.New()
	if err != nil {
		t.Fatalf("an error '%s' was not expected when opening a stub database connection", err)
	}
	defer db.Close()

	handler := &UserHandler{DB: db}

	// 2. Test Cases
	tests := []struct {
		name           string
		mockSetup      func()
		expectedStatus int
		expectedBody   string
	}{
		{
			name: "Success",
			mockSetup: func() {
				rows := sqlmock.NewRows([]string{"id", "username", "email"}).
					AddRow(1, "testuser", "test@example.com")
				// We match the query using Regex
				mock.ExpectQuery(regexp.QuoteMeta("SELECT id, username, email FROM users")).
					WillReturnRows(rows)
			},
			expectedStatus: http.StatusOK,
			expectedBody:   `"Username":"testuser"`,
		},
		{
			name: "Database Error",
			mockSetup: func() {
				mock.ExpectQuery(regexp.QuoteMeta("SELECT id, username, email FROM users")).
					WillReturnError(errors.New("db down"))
			},
			expectedStatus: http.StatusInternalServerError,
			expectedBody:   "Query Failed",
		},
	}

	// 3. Execution
	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			tt.mockSetup()

			req := httptest.NewRequest("GET", "/", nil)
			w := httptest.NewRecorder()

			handler.ServeHTTP(w, req)

			if w.Code != tt.expectedStatus {
				t.Errorf("got status %v, want %v", w.Code, tt.expectedStatus)
			}
			if tt.expectedStatus == http.StatusOK && w.Header().Get("Content-Type") != "application/json" {
				t.Errorf("expected Content-Type application/json, got %v", w.Header().Get("Content-Type"))
			}
			if !strings.Contains(w.Body.String(), tt.expectedBody) {
				t.Errorf("got body %v, want %v", w.Body.String(), tt.expectedBody)
			}
		})
	}
}

```

### 3. Run Tests

To run the unit tests, use the standard Go test command. Our current tests use mocks, so they **do not require** a connection to the real database:

```bash
go test ./...
```

> 💡 **Note:** During tests, you may see a log output like `Query error: db down`. This is **expected**; it confirms that the application is correctly catching and logging the simulated database failure in our "Database Error" test case.

---

## 🚀 Part 4: Deployment (Cloud Run)

### 1. Service Account Setup

The app needs an identity to talk to the DB securely.

```bash
# Create SA
gcloud iam service-accounts create workshop-sa --display-name="Workshop SA"

# Grant DB Access
gcloud projects add-iam-policy-binding $PROJECT_ID \
    --member="serviceAccount:workshop-sa@$PROJECT_ID.iam.gserviceaccount.com" \
    --role="roles/cloudsql.client"

```

### 2. Deploy

```bash
# Build the container image
cd go-workshop
gcloud builds submit --tag gcr.io/$PROJECT_ID/go-workshop
cd ..

# Get Private IP
export DB_HOST=$(gcloud sql instances describe $INSTANCE_NAME \
    --flatten="ipAddresses[]" \
    --format="csv[no-heading](ipAddresses.ipAddress, ipAddresses.type)" | grep ",PRIVATE" | cut -d',' -f1)

gcloud run deploy go-service \
    --image gcr.io/$PROJECT_ID/go-workshop \
    --region $REGION \
    --allow-unauthenticated \
    --service-account workshop-sa@$PROJECT_ID.iam.gserviceaccount.com \
    --network=workshop-vpc \
    --subnet=workshop-subnet \
    --set-env-vars DB_HOST="$DB_HOST" \
    --set-env-vars DB_PORT="5432" \
    --set-env-vars DB_USER="go_workshop" \
    --set-env-vars DB_NAME="users_db" \
    --set-env-vars DB_PASS="$DB_PASS" \
    --set-env-vars AUTH_USER="admin" \
    --set-env-vars AUTH_PASS="<YOUR_AUTH_PASSWORD>"

```

---

## 🌐 Part 5: The Gateway (Load Balancer)

Cloud Armor cannot attach directly to Cloud Run; it needs a Global Load Balancer.

### 1. Reserve Static IP

```bash
gcloud compute addresses create workshop-lb-ip --global

```

### 2. Create Serverless Network Endpoint Group (NEG)

This connects the LB to Cloud Run.

```bash
gcloud compute network-endpoint-groups create go-service-neg \
    --region=$REGION \
    --network-endpoint-type=serverless  \
    --cloud-run-service=go-service

```

### 3. Build the Load Balancer

```bash
# Backend Service
gcloud compute backend-services create workshop-backend --global
gcloud compute backend-services add-backend workshop-backend \
    --global \
    --network-endpoint-group=go-service-neg \
    --network-endpoint-group-region=$REGION

# Routing
gcloud compute url-maps create workshop-url-map --default-service workshop-backend
gcloud compute target-http-proxies create workshop-http-proxy --url-map workshop-url-map

# Forwarding Rule (Frontend)
gcloud compute forwarding-rules create workshop-lb-rule \
    --global \
    --target-http-proxy=workshop-http-proxy \
    --ports=80 \
    --address=workshop-lb-ip

```

---

## 🛡️ Part 6: The Shield (Cloud Armor)

### 1. Create Security Policy
We will block SQL Injection attacks. Run script `06_part6_01_security_policy.sh`:

```bash
gcloud compute security-policies create workshop-armor-policy \
    --description "Workshop Security Policy"

# Rule 1: Allow valid traffic
gcloud compute security-policies rules create 1000 \
    --security-policy workshop-armor-policy \
    --action "allow" \
    --src-ip-ranges "0.0.0.0/0"

# Rule 2: Block SQLi (The "Fortress" Rule)
gcloud compute security-policies rules create 9000 \
    --security-policy workshop-armor-policy \
    --expression "evaluatePreconfiguredExpr('sqli-stable')" \
    --action "deny-403"
```

### 2. Activate Policy
Run script `06_part6_02_activate_policy.sh`:

```bash
gcloud compute backend-services update workshop-backend \
    --global \
    --security-policy workshop-armor-policy
```

### 3. Restrict Ingress (Close the Backdoor)
Run script `06_part6_03_restrict_ingress.sh`:

By default, Cloud Run services have a public URL. To ensure all traffic goes through our Load Balancer and is inspected by Cloud Armor, we must restrict ingress to `internal-and-cloud-load-balancing`.

```bash
gcloud run services update go-service \
    --region $REGION \
    --ingress internal-and-cloud-load-balancing
```

*Note: After this, the direct `run.app` URL will return a 403 Forbidden for external users.*

---

## ✅ Part 7: Final Verification

1. **Get your IP:**
```bash
gcloud compute addresses list --global

```


2. **Test 1: Normal Access (Should work)**
Visit `http://[YOUR_LB_IP]/` in your browser or run `curl -u admin:<YOUR_AUTH_PASSWORD> http://[YOUR_LB_IP]/`.
* *Result:* You see a JSON list of users (`cloud_runner`, etc.).


3. **Test 2: Direct Access (Should Fail)**
Visit `https://[YOUR-CLOUD-RUN-URL].run.app`
* *Result:* **403 Forbidden** (Access is restricted to internal/LB only).


4. **Test 3: SQL Injection Attack (Should Fail)**
Run this command:
```bash
curl "http://[YOUR_LB_IP]/?item=1' OR '1'='1"

```


* *Result:* **403 Forbidden** (Blocked by Cloud Armor WAF).

---

## 🔮 Part 8: Next Steps & Recommendations

### CI/CD Pipeline
For production workloads, avoid manual deployments. Set up a Continuous Integration and Continuous Deployment (CI/CD) pipeline to automate testing and deployment.

**Recommended Tools:**
*   [**Cloud Build**](https://cloud.google.com/build/docs): To build container images and run tests.
*   [**Cloud Deploy**](https://cloud.google.com/deploy/docs): To manage progressive rollouts to Cloud Run.

### Useful Documentation
*   [Cloud Run Documentation](https://cloud.google.com/run/docs)
*   [Cloud SQL for PostgreSQL](https://cloud.google.com/sql/docs/postgres)
*   [Global External Application Load Balancer](https://cloud.google.com/load-balancing/docs/https)
*   [Cloud Armor Security Policies](https://cloud.google.com/armor/docs/security-policy-overview)

---

## 🧹 Section 99: Cleanup

To avoid ongoing charges, delete all resources created during this workshop.

```bash
# 1. Delete Load Balancer components
gcloud compute forwarding-rules delete workshop-lb-rule --global --quiet
gcloud compute target-http-proxies delete workshop-http-proxy --quiet
gcloud compute url-maps delete workshop-url-map --quiet
gcloud compute backend-services delete workshop-backend --global --quiet
gcloud compute network-endpoint-groups delete go-service-neg --region=$REGION --quiet
gcloud compute addresses delete workshop-lb-ip --global --quiet

# 2. Delete Cloud Armor Policy
gcloud compute security-policies delete workshop-armor-policy --quiet

# 3. Delete Cloud Run Service
gcloud run services delete go-service --region=$REGION --quiet

# 4. Delete Cloud SQL Instance
gcloud sql instances delete $INSTANCE_NAME --quiet

# 5. Delete Network (VPC & Subnet)
# First, delete the allocated IP range for Private Service Access
gcloud compute addresses delete google-managed-services-default --global --quiet

gcloud compute networks subnets delete workshop-subnet --region=$REGION --quiet
gcloud compute networks delete workshop-vpc --quiet

# 6. Delete Service Account
gcloud iam service-accounts delete workshop-sa@$PROJECT_ID.iam.gserviceaccount.com --quiet
```

---

## ❓ Appendix: Troubleshooting

| Issue | Solution |
| --- | --- |
| **502 Bad Gateway** | The Load Balancer is still provisioning (wait 5 mins) OR the App failed to connect to DB (check logs). |
| **DB Connection Refused** | Check if `INSTANCE_CONNECTION_NAME` env var is correct. Ensure SA has `Cloud SQL Client` role. |
| **403 on Valid Request** | You might have set a default deny rule in Cloud Armor. Ensure Rule 1000 allows `0.0.0.0/0`. |
| **Go Panic** | Check `gcloud logging read`. Often due to missing env vars (DB_USER/DB_NAME). |