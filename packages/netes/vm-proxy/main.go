package main

import (
	"bufio"
	"fmt"
	"io"
	"log/slog"
	"net"
	"os"
	"strings"
	"time"
)

func main() {
	src := os.Args[1]
	dst := os.Args[2]

	l, err := listen(src)
	if err != nil {
		slog.Error("listening to source", "addr", src, "error", err)
		os.Exit(1)
	}
	defer l.Close()

	for {
		s, err := l.Accept()
		if err != nil {
			slog.Error("accepting new connection", "error", err)
			os.Exit(1)
		}

		d, err := dial(dst)
		if err != nil {
			slog.Warn("connecting to destination", "addr", dst, "error", err)
			s.Close()
			continue
		}

		go func() {
			defer s.Close()
			defer d.Close()

			df, err := d.(*net.UnixConn).File()
			if err != nil {
				slog.Error("getting file from dest conn", "error", err)
				return
			}
			defer df.Close()

			io.Copy(df, s)
		}()

		go func() {
			defer s.Close()
			defer d.Close()

			sf, err := s.(*net.UnixConn).File()
			if err != nil {
				slog.Error("getting file from source conn", "error", err)
				return
			}
			defer sf.Close()

			io.Copy(sf, d)
		}()
	}
}

// valid addresses:
// - unix:$path
// - vsock:$path:$port

func listen(a string) (net.Listener, error) {
	cmps := strings.SplitN(a, ":", 2)
	network := cmps[0]
	addr := cmps[1]

	if network == "vsock" {
		network = "unix"
		cmps = strings.Split(addr, ":")
		addr = cmps[0] + "_" + cmps[1]
	}

	if network == "unix" {
		os.Remove(addr)
	}

	return net.Listen(network, addr)
}

func dial(a string) (net.Conn, error) {
	cmps := strings.SplitN(a, ":", 2)
	network := cmps[0]
	addr := cmps[1]
	var vsockPort string

	if network == "vsock" {
		network = "unix"
		cmps = strings.Split(addr, ":")
		addr = cmps[0]
		vsockPort = cmps[1]
	}

	c, err := net.DialTimeout(network, addr, 10*time.Second)
	if err != nil {
		return nil, err
	}

	if vsockPort != "" {
		fmt.Fprintf(c, "CONNECT %s\n", vsockPort)
		scan := bufio.NewScanner(c)
		scan.Scan()
		if !strings.HasPrefix(scan.Text(), "OK ") {
			defer c.Close()
			return nil, fmt.Errorf("unexpected response from vsock connect: %s", scan.Text())
		}
	}

	return c, nil
}
