package main

import (
	"context"
	"crypto/rand"
	"fmt"
	"net/http"

	"github.com/coreos/go-oidc/v3/oidc"
	"golang.org/x/oauth2"
)

type ServerConfig struct {
	TrustDomain      string
	BaseURL          string
	OIDCProviderURL  string
	OIDCClientID     string
	OIDCClientSecret string
}

type Server struct {
	oauthConfig  oauth2.Config
	oidcProvider *oidc.Provider
	verifier     *oidc.IDTokenVerifier
	cfg          *ServerConfig
	srv          *http.Server
}

func NewServer(ctx context.Context, cfg *ServerConfig) (*Server, error) {
	oidcProvider, err := oidc.NewProvider(ctx, cfg.OIDCProviderURL)
	if err != nil {
		return nil, fmt.Errorf("creating oidc provider: %w", err)
	}

	oauthConfig := oauth2.Config{
		ClientID:     cfg.OIDCClientID,
		ClientSecret: cfg.OIDCClientSecret,
		RedirectURL:  cfg.BaseURL + "/callback",
		Endpoint:     oidcProvider.Endpoint(),
		Scopes:       []string{oidc.ScopeOpenID, "profile"},
	}
	oidcVerifier := oidcProvider.Verifier(&oidc.Config{
		ClientID: cfg.OIDCClientID,
	})

	s := &Server{
		oauthConfig:  oauthConfig,
		oidcProvider: oidcProvider,
		verifier:     oidcVerifier,
		cfg:          cfg,
	}

	mux := http.NewServeMux()
	mux.HandleFunc("GET /login", s.handleLogin)
	mux.HandleFunc("GET /callback", s.handleCallback)

	s.srv = &http.Server{Handler: mux}
	return s, nil
}

func (s *Server) Serve(addr string) error {
	s.srv.Addr = addr
	return s.srv.ListenAndServe()
}

func (s *Server) handleLogin(w http.ResponseWriter, r *http.Request) {
	state := rand.Text()
	http.SetCookie(w, &http.Cookie{
		HttpOnly: true,
		Name:     "oidc_state",
		Value:    state,
	})
	http.Redirect(w, r, s.oauthConfig.AuthCodeURL(state), http.StatusFound)
}

func (s *Server) handleCallback(w http.ResponseWriter, r *http.Request) {
	stateCookie, err := r.Cookie("oidc_state")
	if err != nil {
		http.Error(w, err.Error(), http.StatusBadRequest)
		return
	}
	state := stateCookie.Value

	if state == "" {
		http.Error(w, "oidc_state cookie value is empty", http.StatusBadRequest)
		return
	}

	if state != r.URL.Query().Get("state") {
		http.Error(w, "cookie state doesn't match callback state", http.StatusBadRequest)
		return
	}

	ctx := r.Context()
	token, err := s.oauthConfig.Exchange(ctx, r.URL.Query().Get("code"))
	if err != nil {
		http.Error(w, err.Error(), http.StatusInternalServerError)
		return
	}

	idTokenStr, ok := token.Extra("id_token").(string)
	if !ok {
		http.Error(w, "could not get id_token from oauth2 response", http.StatusInternalServerError)
		return
	}

	idToken, err := s.verifier.Verify(ctx, idTokenStr)
	if err != nil {
		http.Error(w, err.Error(), http.StatusForbidden)
		return
	}

	userInfo, err := s.oidcProvider.UserInfo(ctx, oauth2.StaticTokenSource(token))
	if err != nil {
		http.Error(w, err.Error(), http.StatusForbidden)
		return
	}

	var claims struct {
		PreferredUsername string `json:"preferred_username"`
	}
	if err := userInfo.Claims(&claims); err != nil {
		http.Error(w, err.Error(), http.StatusInternalServerError)
		return
	}

	fmt.Fprintf(w, "sub: %s\npreferred_username: %s\n", idToken.Subject, claims.PreferredUsername)
}
