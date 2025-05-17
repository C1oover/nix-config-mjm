package main

import (
	"context"
	"fmt"
	"log/slog"
	"net"
	"os/signal"
	"path"
	"strings"
	"syscall"
	"time"

	"github.com/coreos/go-systemd/v22/activation"
	"github.com/hashicorp/vault/api"
	"go.opentelemetry.io/otel/attribute"
	"go.opentelemetry.io/otel/codes"
	"go.opentelemetry.io/otel/trace"
)

type ServeCmd struct {
	Paths   []string          `name:"path"`
	Aliases map[string]string `name:"alias" mapsep:" " env:"SECRET_ALIASES"`

	vault *api.Client
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

	c.vault, err = newVaultClient(ctx)
	if err != nil {
		return fmt.Errorf("creating vault client: %w", err)
	}

	connCh := make(chan net.Conn, 1)
	go func() {
		for {
			select {
			case <-ctx.Done():
				return
			default:
				conn, err := l.Accept()
				if err != nil {
					slog.WarnContext(ctx, "failed to accept new connection", "error", err)
					continue
				}

				connCh <- conn
			}
		}
	}()

	go func() {
		for {
			slog.InfoContext(ctx, "waiting for connection")
			select {
			case conn := <-connCh:
				go c.handleConn(ctx, conn)
			case <-time.After(15 * time.Second):
				slog.InfoContext(ctx, "no new connections for a bit, exiting")
				stop()
				return
			case <-ctx.Done():
				slog.Info("terminating")
				return
			}
		}
	}()

	<-ctx.Done()
	stop()

	return nil
}

func (c *ServeCmd) handleConn(ctx context.Context, conn net.Conn) {
	defer conn.Close()

	ctx, span := tracer.Start(ctx, "HandleConn",
		trace.WithAttributes(
			attribute.Stringer("net.addr.local", conn.LocalAddr()),
			attribute.Stringer("net.addr.remote", conn.RemoteAddr())))
	defer span.End()

	addr, err := parseSystemdAddr(conn.RemoteAddr().String())
	if err != nil {
		span.RecordError(err)
		span.SetStatus(codes.Error, err.Error())
		return
	}
	span.SetAttributes(attribute.String("systemd.unit", addr.Unit), attribute.String("systemd.cred.name", addr.Name))

	key, err := c.resolveAlias(addr)
	if err != nil {
		span.RecordError(err)
		span.SetStatus(codes.Error, err.Error())
		return
	}
	if key == "" {
		key, err = c.resolvePath(addr)
		if err != nil {
			span.RecordError(err)
			span.SetStatus(codes.Error, err.Error())
			return
		}
	}

	vaultPath := path.Dir(key)
	vaultKey := path.Base(key)
	span.SetAttributes(attribute.String("vault.kv.path", vaultPath), attribute.String("vault.kv.key", vaultKey))

	scrt, err := c.vault.KVv2("kv").Get(ctx, vaultPath)
	if err != nil {
		span.RecordError(err)
		span.SetStatus(codes.Error, err.Error())
		return
	}

	data, ok := scrt.Data[vaultKey]
	if !ok {
		err := fmt.Errorf("key %q is missing from secret at %q", vaultKey, vaultPath)
		span.RecordError(err)
		span.SetStatus(codes.Error, err.Error())
		return
	}

	fmt.Fprintf(conn, "%v", data)
}

type systemdAddr struct {
	Unit string
	Name string
}

func parseSystemdAddr(s string) (systemdAddr, error) {
	cmps := strings.Split(s, "/")
	if len(cmps) != 4 {
		return systemdAddr{}, fmt.Errorf("address %q should have four slash-separated components", s)
	}

	if cmps[1] != "unit" {
		return systemdAddr{}, fmt.Errorf("second component of %q should be %q", s, "unit")
	}

	return systemdAddr{
		Unit: cmps[2],
		Name: cmps[3],
	}, nil
}

func (a systemdAddr) AliasKey() string {
	return a.Unit + "/" + a.Name
}

func (c *ServeCmd) resolveAlias(addr systemdAddr) (string, error) {
	if keyPath, ok := c.Aliases[addr.AliasKey()]; ok {
		cmps := strings.SplitN(keyPath, "/", 2)
		svcName := cmps[0]
		for _, p := range c.Paths {
			if path.Base(p) == svcName {
				return path.Join(p, cmps[1]), nil
			}
		}

		return "", fmt.Errorf("credential named %q aliased to %q did not match any configured services (%v)", addr.Name, keyPath, c.Paths)
	}

	return "", nil
}

func (c *ServeCmd) resolvePath(addr systemdAddr) (string, error) {
	cmps := strings.SplitN(addr.Name, "_", 2)
	if len(cmps) < 2 {
		return "", fmt.Errorf("credential name %q is missing service prefix", addr.Name)
	}
	svcName := cmps[0]
	for _, p := range c.Paths {
		if path.Base(p) == svcName {
			suffix := strings.ReplaceAll(cmps[1], "__", "/")
			return path.Join(p, suffix), nil
		}
	}

	return "", fmt.Errorf("credential named %q did not match any configured services (%v)", addr.Name, c.Paths)
}
