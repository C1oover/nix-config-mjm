package main

import (
	"context"
	"crypto/tls"
	"crypto/x509"
	"encoding/json"
	"fmt"
	"log/slog"
	"net"
	"net/http"
	"os"
	"path"
	"strings"
	"time"

	"git.deuxfleurs.fr/garage-sdk/garage-admin-sdk-golang"
	"github.com/coreos/go-systemd/v22/activation"
	"github.com/coreos/go-systemd/v22/daemon"
	"github.com/spiffe/go-spiffe/v2/spiffeid"
	"github.com/spiffe/go-spiffe/v2/spiffetls/tlsconfig"
	"github.com/spiffe/go-spiffe/v2/workloadapi"
)

func main() {
	if err := run(); err != nil {
		slog.Error("run server failed", "error", err)
		os.Exit(1)
	}
}

func run() error {
	listeners, err := activation.Listeners()
	if err != nil {
		return fmt.Errorf("getting socket listeners: %w", err)
	}

	if len(listeners) != 1 {
		return fmt.Errorf("incorrect number of listeners (expected 1, got %d)", len(listeners))
	}
	l := listeners[0]
	defer l.Close()

	ctx := context.Background()
	source, err := workloadapi.NewX509Source(ctx)
	if err != nil {
		return fmt.Errorf("creating x509 source: %w", err)
	}
	defer source.Close()

	adminTokenFile := path.Join(os.Getenv("CREDENTIALS_DIRECTORY"), "garage_admin_token")
	b, err := os.ReadFile(adminTokenFile)
	if err != nil {
		return fmt.Errorf("reading admin token from %q: %w", adminTokenFile, err)
	}
	adminToken := strings.TrimSpace(string(b))
	ctx = context.WithValue(ctx, garage.ContextAccessToken, adminToken)

	gConfig := garage.NewConfiguration()
	gConfig.Host = "127.0.0.1:3903"
	g := garage.NewAPIClient(gConfig)

	trustDomain := spiffeid.RequireTrustDomainFromString("home.mattmoriarity.com")
	tlsConfig := tlsconfig.MTLSServerConfig(source, source, tlsconfig.AuthorizeMemberOf(trustDomain))
	tlsListen := tls.NewListener(l, tlsConfig)

	h := &proxyHandler{Garage: g}

	daemon.SdNotify(false, daemon.SdNotifyReady)
	srv := &http.Server{
		Handler:     h.Handler(),
		BaseContext: func(_ net.Listener) context.Context { return ctx },
	}
	return srv.Serve(tlsListen)
}

type proxyHandler struct {
	Garage *garage.APIClient
}

func (h *proxyHandler) Handler() http.Handler {
	m := http.NewServeMux()
	m.HandleFunc("GET /healthz", h.checkHealth)
	m.HandleFunc("/creds", h.getCreds)
	return m
}

func (h *proxyHandler) getCreds(w http.ResponseWriter, r *http.Request) {
	spiffeID, err := getSPIFFEIDFromCerts(r.TLS.PeerCertificates)
	if err != nil {
		slog.ErrorContext(r.Context(), "error getting spiffe id from request", "error", err)
		w.WriteHeader(500)
		fmt.Fprintf(w, "error getting spiffe id from request: %v", err)
		return
	}

	slog.InfoContext(r.Context(), "received request", "spiffe_id", spiffeID)

	// TODO make these expire or be short-lived in some way
	keyInfo, err := h.getKeyForSPIFFEID(r.Context(), spiffeID)
	if err != nil {
		slog.ErrorContext(r.Context(), "error fetching key from garage", "error", err)
		w.WriteHeader(500)
		fmt.Fprintf(w, "error fetching key from garage: %v", err)
		return
	}

	keyID := keyInfo.GetAccessKeyId()
	secretKey := keyInfo.GetSecretAccessKey()

	slog.InfoContext(r.Context(), "found matching garage key", "key_id", keyID)

	resp := struct {
		Version         int
		AccessKeyId     string
		SecretAccessKey string
		Token           string
		Expiration      time.Time
	}{
		1,
		keyID,
		secretKey,
		"",
		time.Now().Add(time.Hour),
	}

	out, err := json.Marshal(resp)
	if err != nil {
		slog.ErrorContext(r.Context(), "error marshalling json response", "error", err)
		w.WriteHeader(500)
		fmt.Fprintf(w, "error marshalling json response: %v", err)
		return
	}

	w.Header().Add("Content-Type", "application/json")
	w.Write(out)
}

func getSPIFFEIDFromCerts(certs []*x509.Certificate) (spiffeid.ID, error) {
	if len(certs) == 0 {
		return spiffeid.ID{}, fmt.Errorf("no certs in https request")
	}

	cert := certs[0]
	uris := cert.URIs
	if len(uris) != 1 {
		return spiffeid.ID{}, fmt.Errorf("wrong number of uris in certificate, expected 1, got %d", len(uris))
	}

	uri := uris[0]
	spiffeID, err := spiffeid.FromURI(uri)
	if err != nil {
		return spiffeid.ID{}, fmt.Errorf("uri %q found in certificate is not a valid spiffe id: %w", uri, err)
	}

	return spiffeID, nil
}

func (h *proxyHandler) getKeyForSPIFFEID(ctx context.Context, id spiffeid.ID) (*garage.KeyInfo, error) {
	keys, _, err := h.Garage.KeyApi.ListKeys(ctx).Execute()
	if err != nil {
		return nil, fmt.Errorf("fetching list of keys from garage: %w", err)
	}

	idStr := id.String()
	slog.InfoContext(ctx, "fetched keys from garage", "key_count", len(keys))
	for _, k := range keys {
		slog.DebugContext(ctx, "found candidate key", "id", k.GetId(), "name", k.GetName())
		if k.GetName() == idStr {
			slog.InfoContext(ctx, "found desired key", "id", k.GetId(), "name", k.GetName())

			key, _, err := h.Garage.KeyApi.GetKey(ctx).Id(k.GetId()).ShowSecretKey("true").Execute()
			if err != nil {
				return nil, fmt.Errorf("fetching key info for key id %q: %w", k.GetId(), err)
			}

			return key, nil
		}
	}

	return nil, fmt.Errorf("no matching key found for spiffe id %q", idStr)
}

func (proxyHandler) checkHealth(w http.ResponseWriter, r *http.Request) {
	w.WriteHeader(http.StatusOK)
	fmt.Fprint(w, "OK")
}
