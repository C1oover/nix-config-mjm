package nix

import (
	"context"
	"fmt"
	"os"
	"os/exec"
	"strings"
)

type CopyOptions struct {
	Installables []string
	To           string
}

func (n *Real) Copy(ctx context.Context, opts CopyOptions) error {
	args := []string{"copy", "--no-check-sigs"}
	args = append(args, "--to", opts.To)
	args = append(args, opts.Installables...)

	cmd := exec.CommandContext(ctx, "nix", args...)
	cmd.Stderr = os.Stderr
	cmd.Stdout = os.Stdout

	sshOptsStr := strings.Join(n.SSHOpts, " ")
	cmd.Env = append(os.Environ(), "NIX_SSHOPTS="+sshOptsStr)

	if err := cmd.Run(); err != nil {
		return fmt.Errorf("running nix copy: %w", err)
	}
	return nil
}
