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
