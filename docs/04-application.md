# 💻 The Application Code (Go)

The microservice is a simple but architecturally sound Go application.

## Directory Structure
```
go-workshop/
├── Dockerfile
├── go.mod
├── main.go
├── handlers/
│   ├── user_handler.go
│   └── user_handler_test.go
├── middleware/
│   └── basic_auth.go
└── models/
    └── user.go
```

## Key Components

### 1. `models/user.go`
Defines the data structure. Simple struct with JSON tags (implicit in this case, but good practice).

### 2. `handlers/user_handler.go`
*   **Dependency Injection:** The `UserHandler` struct has a field `DB *sql.DB`. We don't create the connection *inside* the handler; we pass it in. This makes unit testing easy because we can pass a mock DB.
*   **JSON Response:** Uses `json.NewEncoder(w).Encode(users)` to stream the response efficiently. Sets `Content-Type: application/json`.

### 3. `middleware/basic_auth.go`
*   **Decorator Pattern:** Wraps the standard `http.Handler`.
*   **Logic:** Checks `r.BasicAuth()`. If valid, calls `m.Next.ServeHTTP`. If not, returns `401 Unauthorized`.
*   **Separation of Concerns:** Auth logic is completely separate from business logic (handlers).

### 4. `main.go` (The Entry Point)
*   **Wiring:** Connects to the database using `pgx` driver.
*   **Configuration:** Reads `DB_HOST`, `DB_PORT`, `DB_USER` from environment variables.
*   **Pipeline:** Wraps the `UserHandler` with `BasicAuth` middleware and starts the server.

## Unit Testing (`handlers/user_handler_test.go`)
We use `go-sqlmock` to simulate database interactions.
*   **No Real DB Required:** The test creates a mock DB connection.
*   **Expectations:** We tell the mock "expect a SELECT query" and "return these rows".
*   **Verification:** We check if the handler returns the expected JSON and status code.

---
[⬅️ Back to Table of Contents](./README.md)
