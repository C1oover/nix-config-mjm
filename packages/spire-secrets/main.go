package main

import (
	"context"
	"flag"
	"fmt"
	"io"
	"log/slog"
	"net"
	"path"
	"strings"
	"time"

	"net/http"
	"os"

	"github.com/coreos/go-systemd/v22/activation"
	"github.com/coreos/go-systemd/v22/daemon"
	"github.com/hashicorp/vault/api"
	"github.com/spiffe/go-spiffe/v2/spiffeid"
	"github.com/spiffe/go-spiffe/v2/spiffetls/tlsconfig"
	"github.com/spiffe/go-spiffe/v2/svid/jwtsvid"
	"github.com/spiffe/go-spiffe/v2/workloadapi"
)

var (
	secretPrefix = flag.String("prefix", "", "prefix to prepend to credential key")
)

func main() {
	flag.Parse()
	slog.Info("started", "args", os.Args)

	switch flag.Arg(0) {
	case "server":
		if err := runServer(); err != nil {
			slog.Error("run server failed", "error", err)
			os.Exit(1)
		}
	case "client":
		if err := runClient(); err != nil {
			slog.Error("run client failed", "error", err)
			os.Exit(1)
		}

	default:
		slog.Error("unexpected command", "cmd", flag.Arg(0))
	}
}

func runServer() error {
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
	c, err := newVaultClient(ctx)
	if err != nil {
		return fmt.Errorf("creating vault client: %w", err)
	}

	daemon.SdNotify(false, daemon.SdNotifyReady)

	connCh := make(chan net.Conn, 1)
	go func() {
		for {
			conn, err := l.Accept()
			if err != nil {
				slog.WarnContext(ctx, "failed to accept new connection", "error", err)
				continue
			}

			connCh <- conn
		}
	}()

	for {
		slog.InfoContext(ctx, "waiting for connection")
		select {
		case conn := <-connCh:
			go handleConn(ctx, c, conn)
		case <-time.After(15 * time.Second):
			slog.InfoContext(ctx, "no new connections for a bit, exiting")
			os.Exit(0)
		}
	}
}

func handleConn(ctx context.Context, c *api.Client, conn net.Conn) {
	defer conn.Close()

	slog.InfoContext(ctx, "handling incoming connection", "local_addr", conn.LocalAddr(), "remote_addr", conn.RemoteAddr())

	addrComps := strings.Split(conn.RemoteAddr().String(), "/")
	if len(addrComps) != 4 {
		slog.ErrorContext(ctx, "unexpected format for remote address", "components", len(addrComps))
		return
	}

	key := addrComps[3]
	key = strings.ReplaceAll(key, "__", "/")
	key = path.Join(*secretPrefix, key)

	slog.InfoContext(ctx, "fetching secret", "cred_key", addrComps[3], "path", key)
	scrt, err := c.KVv2("kv").Get(ctx, path.Dir(key))
	if err != nil {
		slog.ErrorContext(ctx, "failed to fetch secret", "error", err)
		return
	}

	data, ok := scrt.Data[path.Base(key)]
	if !ok {
		slog.ErrorContext(ctx, "key missing from secret", "path", path.Dir(key), "key", path.Base(key))
		return
	}

	fmt.Fprintf(conn, "%v", data)
	slog.InfoContext(ctx, "wrote secret")
}

func runClient() error {
	sockPath := flag.Arg(1)
	slog.Info("running client", "path", sockPath)

	laddr, _ := net.ResolveUnixAddr("unix", "\x00deadbeef/unit/example.service/"+flag.Arg(2))
	raddr, _ := net.ResolveUnixAddr("unix", sockPath)
	conn, err := net.DialUnix("unix", laddr, raddr)
	if err != nil {
		return fmt.Errorf("dialing %q as %q: %w", raddr, laddr, err)
	}
	defer conn.Close()

	slog.Info("connected")

	if _, err := io.Copy(os.Stdout, conn); err != nil {
		return fmt.Errorf("copying from socket: %w", err)
	}

	slog.Info("done")

	return nil
}

func newVaultClient(ctx context.Context) (*api.Client, error) {
	spiffeSocket := os.Getenv("SPIFFE_ENDPOINT_SOCKET")
	if spiffeSocket == "" {
		// if no spiffe socket, assume this is called from somewhere where the
		// vault cli is being used, and try to read the token it stores
		homeDir, err := os.UserHomeDir()
		if err != nil {
			return nil, fmt.Errorf("getting user home dir: %w", err)
		}

		tokenBytes, err := os.ReadFile(path.Join(homeDir, ".vault-token"))
		if err != nil {
			return nil, fmt.Errorf("reading vault token from file: %w", err)
		}

		c, err := api.NewClient(nil)
		if err != nil {
			return nil, fmt.Errorf("creating vault client: %w", err)
		}
		c.SetToken(strings.TrimSpace(string(tokenBytes)))
		return c, nil
	} else {
		wc, err := workloadapi.New(ctx)
		if err != nil {
			return nil, fmt.Errorf("creating workload api client: %w", err)
		}
		defer wc.Close()

		source, err := workloadapi.NewX509Source(ctx, workloadapi.WithClient(wc))
		if err != nil {
			return nil, fmt.Errorf("creating x509 source: %w", err)
		}
		defer source.Close()

		serverID := spiffeid.RequireFromString("spiffe://home.mattmoriarity.com/svc/vault")

		vaultConfig := api.DefaultConfig()
		transport := vaultConfig.HttpClient.Transport.(*http.Transport)
		transport.TLSClientConfig = tlsconfig.TLSClientConfig(source, tlsconfig.AuthorizeID(serverID))

		c, err := api.NewClient(vaultConfig)
		if err != nil {
			return nil, fmt.Errorf("creating vault client: %w", err)
		}

		jwtSource, err := workloadapi.NewJWTSource(ctx)
		if err != nil {
			return nil, fmt.Errorf("creating jwt source: %w", err)
		}
		defer jwtSource.Close()

		svid, err := jwtSource.FetchJWTSVID(ctx, jwtsvid.Params{
			Audience: os.Getenv("VAULT_ADDR"),
		})
		if err != nil {
			return nil, fmt.Errorf("fetching jwt svid: %w", err)
		}

		req := map[string]any{
			"role": "spiffe",
			"jwt":  svid.Marshal(),
		}
		resp, err := c.Logical().WriteWithContext(ctx, "auth/spiffe/login", req)
		if err != nil {
			return nil, fmt.Errorf("authorizing vault with jwt token: %w", err)
		}

		c.SetToken(resp.Auth.ClientToken)
		return c, err
	}
}
