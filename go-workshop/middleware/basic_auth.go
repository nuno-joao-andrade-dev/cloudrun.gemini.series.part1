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
