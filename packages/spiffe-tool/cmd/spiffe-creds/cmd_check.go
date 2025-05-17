package main

import (
	"fmt"
	"io"
	"net"
	"os"
)

type CheckCmd struct {
	SocketPath string `type:"existingfile" default:".data/secrets.sock"`
	Unit       string `default:"example.service"`
	Name       string `arg:""`
}

func (c *CheckCmd) Run() error {
	laddr, err := net.ResolveUnixAddr("unix", "\x00deadbeef/unit/"+c.Unit+"/"+c.Name)
	if err != nil {
		return err
	}

	raddr, err := net.ResolveUnixAddr("unix", c.SocketPath)
	if err != nil {
		return err
	}

	conn, err := net.DialUnix("unix", laddr, raddr)
	if err != nil {
		return fmt.Errorf("dialing %q as %q: %w", raddr, laddr, err)
	}
	defer conn.Close()

	if _, err := io.Copy(os.Stdout, conn); err != nil {
		return fmt.Errorf("copying from socket to stdout: %w", err)
	}

	return nil
}
