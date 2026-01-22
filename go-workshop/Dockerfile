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
