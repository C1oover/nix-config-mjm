package main

import (
	"context"
	"crypto/tls"
	"crypto/x509"
	"encoding/json"
	"fmt"
	"net"
	"net/http"
	"os/signal"
	"strings"
	"sync/atomic"
	"syscall"
	"time"

	"git.deuxfleurs.fr/garage-sdk/garage-admin-sdk-golang"
	"github.com/coreos/go-systemd/v22/activation"
	"github.com/coreos/go-systemd/v22/daemon"
	"github.com/spiffe/go-spiffe/v2/spiffeid"
	"github.com/spiffe/go-spiffe/v2/spiffetls/tlsconfig"
	"github.com/spiffe/go-spiffe/v2/workloadapi"
	"go.opentelemetry.io/contrib/instrumentation/net/http/otelhttp"
	"go.opentelemetry.io/otel/attribute"
	"go.opentelemetry.io/otel/codes"
	"go.opentelemetry.io/otel/trace"
)

type ServeCmd struct {
	AdminToken      []byte `name:"admin-token-file" type:"filecontent" default:"${creds_dir}/garage_admin_token"`
	GarageAdminAddr string `default:"127.0.0.1:3903"`
	TrustDomain     string `default:"home.mattmoriarity.com"`
}

func (c *ServeCmd) Run(ctx context.Context) error {
	listeners, err := activation.Listeners()
	if err != nil {
		return fmt.Errorf("getting socket listeners: %w", err)
	}

	if len(listeners) != 1 {
		return fmt.Errorf("incorrect number of listeners (expected 1, got %d)", len(listeners))
	}
	l := listeners[0]
	defer l.Close()

	ctx, stop := signal.NotifyContext(ctx, syscall.SIGINT, syscall.SIGTERM)
	defer stop()

	source, err := workloadapi.NewX509Source(ctx)
	if err != nil {
		return fmt.Errorf("creating x509 source: %w", err)
	}
	defer source.Close()

	adminToken := strings.TrimSpace(string(c.AdminToken))
	rCtx, stopRequests := context.WithCancel(context.Background())
	rCtx = context.WithValue(rCtx, garage.ContextAccessToken, adminToken)

	gConfig := garage.NewConfiguration()
	gConfig.Host = c.GarageAdminAddr
	g := garage.NewAPIClient(gConfig)

	trustDomain := spiffeid.RequireTrustDomainFromString(c.TrustDomain)
	tlsConfig := tlsconfig.MTLSServerConfig(source, source, tlsconfig.AuthorizeMemberOf(trustDomain))
	tlsListen := tls.NewListener(l, tlsConfig)

	h := &proxyHandler{Garage: g}

	srv := &http.Server{
		Handler:     h.Handler(),
		BaseContext: func(_ net.Listener) context.Context { return rCtx },
	}
	go func() {
		if err := srv.Serve(tlsListen); err != nil && err != http.ErrServerClosed {
			panic(err)
		}
	}()

	daemon.SdNotify(false, daemon.SdNotifyReady)
	<-ctx.Done()
	stop()
	h.isShuttingDown.Store(true)

	time.Sleep(5 * time.Second)
	shutdownCtx, cancel := context.WithTimeout(context.Background(), 15*time.Second)
	defer cancel()

	err = srv.Shutdown(shutdownCtx)
	stopRequests()
	if err != nil {
		time.Sleep(5 * time.Second)
	}

	return nil
}

type proxyHandler struct {
	Garage         *garage.APIClient
	isShuttingDown atomic.Bool
}

func (h *proxyHandler) Handler() http.Handler {
	m := http.NewServeMux()
	m.Handle("GET /healthz", otelhttp.WithRouteTag("GET /healthz", http.HandlerFunc(h.checkHealth)))
	m.Handle("/creds", otelhttp.WithRouteTag("/creds", http.HandlerFunc(h.getCreds)))
	return otelhttp.NewHandler(m, "Handler")
}

func (h *proxyHandler) getCreds(w http.ResponseWriter, r *http.Request) {
	ctx := r.Context()
	span := trace.SpanFromContext(ctx)

	spiffeID, err := getSPIFFEIDFromCerts(ctx, r.TLS.PeerCertificates)
	if err != nil {
		span.RecordError(err)
		span.SetStatus(codes.Error, err.Error())
		http.Error(w, fmt.Sprintf("error getting spiffe id from request: %v", err), http.StatusInternalServerError)
		return
	}

	span.SetAttributes(attribute.Stringer("spiffe.id", spiffeID))

	// TODO make these expire or be short-lived in some way
	keyInfo, err := h.getKeyForSPIFFEID(ctx, spiffeID)
	if err != nil {
		span.RecordError(err)
		span.SetStatus(codes.Error, err.Error())
		http.Error(w, fmt.Sprintf("error fetching key from garage: %v", err), http.StatusInternalServerError)
		return
	}

	keyID := keyInfo.GetAccessKeyId()
	secretKey := keyInfo.GetSecretAccessKey()

	span.SetAttributes(attribute.String("garage.key_id", keyID))

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
		span.RecordError(err)
		span.SetStatus(codes.Error, err.Error())
		http.Error(w, fmt.Sprintf("error marshalling json response: %v", err), http.StatusInternalServerError)
		return
	}

	w.Header().Add("Content-Type", "application/json")
	w.Write(out)
}

func getSPIFFEIDFromCerts(ctx context.Context, certs []*x509.Certificate) (spiffeid.ID, error) {
	ctx, span := tracer.Start(ctx, "getSPIFFEIDFromCerts", trace.WithAttributes(attribute.Int("cert.count", len(certs))))
	defer span.End()

	if len(certs) == 0 {
		err := fmt.Errorf("no certs in https request")
		span.RecordError(err)
		span.SetStatus(codes.Error, err.Error())
		return spiffeid.ID{}, err
	}

	cert := certs[0]
	uris := cert.URIs
	span.SetAttributes(attribute.Int("cert.uri.count", len(uris)))
	if len(uris) != 1 {
		err := fmt.Errorf("wrong number of uris in certificate, expected 1, got %d", len(uris))
		span.RecordError(err)
		span.SetStatus(codes.Error, err.Error())
		return spiffeid.ID{}, err
	}

	uri := uris[0]
	span.SetAttributes(attribute.Stringer("cert.uri", uri))

	spiffeID, err := spiffeid.FromURI(uri)
	if err != nil {
		span.RecordError(err)
		span.SetStatus(codes.Error, err.Error())
		return spiffeid.ID{}, fmt.Errorf("uri %q found in certificate is not a valid spiffe id: %w", uri, err)
	}

	span.SetAttributes(attribute.Stringer("spiffe.id", spiffeID))
	return spiffeID, nil
}

func (h *proxyHandler) getKeyForSPIFFEID(ctx context.Context, id spiffeid.ID) (*garage.KeyInfo, error) {
	ctx, span := tracer.Start(ctx, "getKeyForSPIFFEID",
		trace.WithAttributes(attribute.Stringer("spiffe.id", id)))
	defer span.End()

	keys, _, err := h.Garage.KeyApi.ListKeys(ctx).Execute()
	if err != nil {
		return nil, fmt.Errorf("fetching list of keys from garage: %w", err)
	}

	span.SetAttributes(attribute.Int("key.count", len(keys)))

	idStr := id.String()
	for _, k := range keys {
		span.AddEvent("check candidate key", trace.WithAttributes(attribute.String("key.id", k.GetId()), attribute.String("key.name", k.GetName())))
		if k.GetName() == idStr {
			span.SetAttributes(attribute.String("key.id", k.GetId()), attribute.String("key.name", k.GetName()))

			key, _, err := h.Garage.KeyApi.GetKey(ctx).Id(k.GetId()).ShowSecretKey("true").Execute()
			if err != nil {
				span.RecordError(err)
				span.SetStatus(codes.Error, err.Error())
				return nil, fmt.Errorf("fetching key info for key id %q: %w", k.GetId(), err)
			}

			return key, nil
		}
	}

	return nil, fmt.Errorf("no matching key found for spiffe id %q", idStr)
}

func (h *proxyHandler) checkHealth(w http.ResponseWriter, r *http.Request) {
	if h.isShuttingDown.Load() {
		http.Error(w, "Server is shutting down", http.StatusServiceUnavailable)
		return
	}

	w.WriteHeader(http.StatusOK)
	fmt.Fprint(w, "OK")
}
