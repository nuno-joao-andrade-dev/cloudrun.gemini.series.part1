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