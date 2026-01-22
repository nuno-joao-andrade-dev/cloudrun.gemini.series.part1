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
