package main

import (
	"context"
	"testing"

	"git.midna.dev/mjm/nix-config/packages/dippy/cmd"
	"git.midna.dev/mjm/nix-config/packages/dippy/nix"
	"github.com/shoenig/test"
	"github.com/shoenig/test/must"
)

type mockNix struct {
	lastBuild struct {
		drvPaths []string
		useNom   bool
	}
}

func (n *mockNix) Realise(_ context.Context, drvPaths []string, useNom bool) error {
	n.lastBuild.drvPaths = drvPaths
	n.lastBuild.useNom = useNom
	return nil
}

func (n *mockNix) EvalJobs(_ context.Context, opts nix.EvalJobsOptions) ([]nix.EvalJobResult, error) {
	return nil, nil
}

func (n *mockNix) EvalJSON(_ context.Context, dst interface{}, opts nix.EvalOptions) error {
	return nil
}

func (n *mockNix) Copy(_ context.Context, opts nix.CopyOptions) error {
	return nil
}

func TestNewHostSSH(t *testing.T) {
	user := "mjm"
	host := "uranus.home.mattmoriarity.com"

	cfg := Config{}
	h := NewHost(
		cfg,
		"uranus",
		"x86_64-linux",
		"/nix/store/g5dyb9016k8fnz3ng6k50jc7nc5zqhf3-nixos-system-uranus-25.05pre-git.drv",
		"/nix/store/h3big3vbjnk32vf0nb5vi80yq0l9ivxb-nixos-system-uranus-25.05pre-git",
		DeployConfig{
			TargetUser: &user,
			TargetHost: &host,
		})

	test.Eq(t, "uranus", h.Name)
	test.Eq(t, "/nix/store/g5dyb9016k8fnz3ng6k50jc7nc5zqhf3-nixos-system-uranus-25.05pre-git.drv", h.DrvPath)
	test.Eq(t, "/nix/store/h3big3vbjnk32vf0nb5vi80yq0l9ivxb-nixos-system-uranus-25.05pre-git", h.OutPath)
	test.Eq(t, "mjm", *h.DeployConfig.TargetUser)
	test.Eq(t, "uranus.home.mattmoriarity.com", *h.DeployConfig.TargetHost)
	test.False(t, h.RebootNeeded)
	test.False(t, h.IsLocal())
	test.True(t, h.IsRemote())
	test.False(t, h.IsDarwin())
}

func TestNewHostLocal(t *testing.T) {
	cfg := Config{}
	h := NewHost(
		cfg,
		"uranus",
		"x86_64-linux",
		"/nix/store/g5dyb9016k8fnz3ng6k50jc7nc5zqhf3-nixos-system-uranus-25.05pre-git.drv",
		"/nix/store/h3big3vbjnk32vf0nb5vi80yq0l9ivxb-nixos-system-uranus-25.05pre-git",
		DeployConfig{})

	test.Eq(t, "uranus", h.Name)
	test.Eq(t, "/nix/store/g5dyb9016k8fnz3ng6k50jc7nc5zqhf3-nixos-system-uranus-25.05pre-git.drv", h.DrvPath)
	test.Eq(t, "/nix/store/h3big3vbjnk32vf0nb5vi80yq0l9ivxb-nixos-system-uranus-25.05pre-git", h.OutPath)
	test.Nil(t, h.DeployConfig.TargetHost)
	test.Nil(t, h.DeployConfig.TargetUser)
	test.False(t, h.RebootNeeded)
	test.True(t, h.IsLocal())
	test.False(t, h.IsRemote())
	test.False(t, h.IsDarwin())
}

func TestNewHostLocalDarwin(t *testing.T) {
	cfg := Config{}
	h := NewHost(
		cfg,
		"athena",
		"aarch64-darwin",
		"/nix/store/fn5mp1b73w45q3a9qnh3wp3zl8mpzvw1-darwin-system-25.05.drv",
		"/nix/store/dwxkv6qrqs31sj084shp5pfswmarl4mw-darwin-system-25.05",
		DeployConfig{})

	test.Eq(t, "athena", h.Name)
	test.Eq(t, "/nix/store/fn5mp1b73w45q3a9qnh3wp3zl8mpzvw1-darwin-system-25.05.drv", h.DrvPath)
	test.Eq(t, "/nix/store/dwxkv6qrqs31sj084shp5pfswmarl4mw-darwin-system-25.05", h.OutPath)
	test.Nil(t, h.DeployConfig.TargetHost)
	test.Nil(t, h.DeployConfig.TargetUser)
	test.False(t, h.RebootNeeded)
	test.True(t, h.IsLocal())
	test.False(t, h.IsRemote())
	test.True(t, h.IsDarwin())
}

func TestBuildWithoutNom(t *testing.T) {
	n := &mockNix{}
	cfg := Config{
		Nix: n,
	}
	h := NewHost(
		cfg,
		"uranus",
		"x86_64-linux",
		"/nix/store/g5dyb9016k8fnz3ng6k50jc7nc5zqhf3-nixos-system-uranus-25.05pre-git.drv",
		"/nix/store/h3big3vbjnk32vf0nb5vi80yq0l9ivxb-nixos-system-uranus-25.05pre-git",
		DeployConfig{})
	ctx := context.Background()

	must.NoError(t, h.Build(ctx, false))
	test.Eq(t, []string{"/nix/store/g5dyb9016k8fnz3ng6k50jc7nc5zqhf3-nixos-system-uranus-25.05pre-git.drv"}, n.lastBuild.drvPaths)
	test.False(t, n.lastBuild.useNom)
}

func TestBuildWithNom(t *testing.T) {
	n := &mockNix{}
	cfg := Config{
		Nix: n,
	}
	h := NewHost(
		cfg,
		"uranus",
		"x86_64-linux",
		"/nix/store/g5dyb9016k8fnz3ng6k50jc7nc5zqhf3-nixos-system-uranus-25.05pre-git.drv",
		"/nix/store/h3big3vbjnk32vf0nb5vi80yq0l9ivxb-nixos-system-uranus-25.05pre-git",
		DeployConfig{})
	ctx := context.Background()

	must.NoError(t, h.Build(ctx, true))
	test.Eq(t, []string{"/nix/store/g5dyb9016k8fnz3ng6k50jc7nc5zqhf3-nixos-system-uranus-25.05pre-git.drv"}, n.lastBuild.drvPaths)
	test.True(t, n.lastBuild.useNom)
}

func TestPushToAttic(t *testing.T) {
	r := &cmd.MockRunner{}
	cfg := Config{Runner: r}
	h := NewHost(
		cfg,
		"uranus",
		"x86_64-linux",
		"/nix/store/g5dyb9016k8fnz3ng6k50jc7nc5zqhf3-nixos-system-uranus-25.05pre-git.drv",
		"/nix/store/h3big3vbjnk32vf0nb5vi80yq0l9ivxb-nixos-system-uranus-25.05pre-git",
		DeployConfig{})
	ctx := context.Background()

	must.NoError(t, h.PushToAttic(ctx))
	test.Eq(t, [][]string{{
		"attic", "push", "homelab", "/nix/store/h3big3vbjnk32vf0nb5vi80yq0l9ivxb-nixos-system-uranus-25.05pre-git",
	}}, r.History)
}

func TestCheckRebootNeeded(t *testing.T) {
	t.Run("ssh host", func(t *testing.T) {
		r := &cmd.MockRunner{}
		cfg := Config{
			Runner: &cmd.MockRunner{},
			RemoteRunner: func(host, user string) (cmd.Runner, error) {
				return r, nil
			},
		}
		user := "mjm"
		host := "uranus.home.mattmoriarity.com"
		h := NewHost(
			cfg,
			"uranus",
			"x86_64-linux",
			"/nix/store/g5dyb9016k8fnz3ng6k50jc7nc5zqhf3-nixos-system-uranus-25.05pre-git.drv",
			"/nix/store/h3big3vbjnk32vf0nb5vi80yq0l9ivxb-nixos-system-uranus-25.05pre-git",
			DeployConfig{
				TargetUser: &user,
				TargetHost: &host,
			})
		ctx := context.Background()

		r.Outputs = [][]byte{
			[]byte(`{"reboot_needed": true}`),
		}
		must.NoError(t, h.CheckRebootNeeded(ctx))
		test.Eq(t, [][]string{{
			"/nix/store/h3big3vbjnk32vf0nb5vi80yq0l9ivxb-nixos-system-uranus-25.05pre-git/bin/nvd-json",
			"reboot-check",
			"/nix/store/h3big3vbjnk32vf0nb5vi80yq0l9ivxb-nixos-system-uranus-25.05pre-git",
		}}, r.History)
		test.True(t, h.RebootNeeded)
	})

	t.Run("ssh host not needed", func(t *testing.T) {
		r := &cmd.MockRunner{}
		cfg := Config{
			Runner: &cmd.MockRunner{},
			RemoteRunner: func(host, user string) (cmd.Runner, error) {
				return r, nil
			},
		}
		user := "mjm"
		host := "uranus.home.mattmoriarity.com"
		h := NewHost(
			cfg,
			"uranus",
			"x86_64-linux",
			"/nix/store/g5dyb9016k8fnz3ng6k50jc7nc5zqhf3-nixos-system-uranus-25.05pre-git.drv",
			"/nix/store/h3big3vbjnk32vf0nb5vi80yq0l9ivxb-nixos-system-uranus-25.05pre-git",
			DeployConfig{
				TargetUser: &user,
				TargetHost: &host,
			})
		ctx := context.Background()

		r.Outputs = [][]byte{
			[]byte(`{"reboot_needed": false}`),
		}
		must.NoError(t, h.CheckRebootNeeded(ctx))
		test.False(t, h.RebootNeeded)
	})

	t.Run("local host", func(t *testing.T) {
		r := &cmd.MockRunner{}
		cfg := Config{Runner: r}
		h := NewHost(
			cfg,
			"uranus",
			"x86_64-linux",
			"/nix/store/g5dyb9016k8fnz3ng6k50jc7nc5zqhf3-nixos-system-uranus-25.05pre-git.drv",
			"/nix/store/h3big3vbjnk32vf0nb5vi80yq0l9ivxb-nixos-system-uranus-25.05pre-git",
			DeployConfig{})
		ctx := context.Background()

		r.Outputs = [][]byte{
			[]byte(`{"reboot_needed": true}`),
		}
		must.NoError(t, h.CheckRebootNeeded(ctx))
		test.Eq(t, [][]string{{
			"/nix/store/h3big3vbjnk32vf0nb5vi80yq0l9ivxb-nixos-system-uranus-25.05pre-git/bin/nvd-json",
			"reboot-check",
			"/nix/store/h3big3vbjnk32vf0nb5vi80yq0l9ivxb-nixos-system-uranus-25.05pre-git",
		}}, r.History)
		test.True(t, h.RebootNeeded)
	})

	t.Run("darwin host", func(t *testing.T) {
		r := &cmd.MockRunner{}
		cfg := Config{Runner: r}
		h := NewHost(
			cfg,
			"athena",
			"aarch64-darwin",
			"/nix/store/fn5mp1b73w45q3a9qnh3wp3zl8mpzvw1-darwin-system-25.05.drv",
			"/nix/store/dwxkv6qrqs31sj084shp5pfswmarl4mw-darwin-system-25.05",
			DeployConfig{})
		ctx := context.Background()

		must.NoError(t, h.CheckRebootNeeded(ctx))
		test.SliceEmpty(t, r.History)
		test.False(t, h.RebootNeeded)
	})
}

const testDiffOutput string = `
{
  "left": "/nix/store/wdlgy4gsy7bp0bzchjapf9mkh56i8m4z-nixos-system-leto-25.05beta747941.ceaea203f3ae",
  "right": "/nix/store/sv332lwsg9fify6y1ymlk70qif4kn6ar-nixos-system-leto-25.05beta748220.f6c5b2b731ab",
  "version_changes": [
    {
      "pname": "nixos-system-leto",
      "old_versions": [
        "25.05beta747941.ceaea203f3ae"
      ],
      "new_versions": [
        "25.05beta748220.f6c5b2b731ab"
      ]
    },
    {
      "pname": "prometheus",
      "old_versions": [
        "3.0.1"
      ],
      "new_versions": [
        "3.1.0"
      ]
    },
    {
      "pname": "python3.12-rapidfuzz",
      "old_versions": [
        "3.12.0"
      ],
      "new_versions": [
        "3.12.1"
      ]
    }
  ],
  "added_packages": [],
  "removed_packages": [],
  "reboot_packages": []
}
`

func TestHostDiff(t *testing.T) {
	t.Run("ssh host", func(t *testing.T) {
		r := &cmd.MockRunner{}
		cfg := Config{
			Runner: &cmd.MockRunner{},
			RemoteRunner: func(host, user string) (cmd.Runner, error) {
				return r, nil
			},
		}
		user := "mjm"
		host := "uranus.home.mattmoriarity.com"
		h := NewHost(
			cfg,
			"uranus",
			"x86_64-linux",
			"/nix/store/g5dyb9016k8fnz3ng6k50jc7nc5zqhf3-nixos-system-uranus-25.05pre-git.drv",
			"/nix/store/h3big3vbjnk32vf0nb5vi80yq0l9ivxb-nixos-system-uranus-25.05pre-git",
			DeployConfig{
				TargetUser: &user,
				TargetHost: &host,
			})
		ctx := context.Background()

		r.Outputs = [][]byte{
			[]byte(testDiffOutput),
		}
		output, err := h.Diff(ctx)
		must.NoError(t, err)
		test.Eq(t, [][]string{
			{
				"/nix/store/h3big3vbjnk32vf0nb5vi80yq0l9ivxb-nixos-system-uranus-25.05pre-git/bin/nvd-json",
				"diff",
				"/run/current-system",
				"/nix/store/h3big3vbjnk32vf0nb5vi80yq0l9ivxb-nixos-system-uranus-25.05pre-git",
			},
		}, r.History)
		test.Eq(t, testDiffOutput, string(output))
	})

	t.Run("local host", func(t *testing.T) {
		r := &cmd.MockRunner{}
		cfg := Config{Runner: r}
		h := NewHost(
			cfg,
			"uranus",
			"x86_64-linux",
			"/nix/store/g5dyb9016k8fnz3ng6k50jc7nc5zqhf3-nixos-system-uranus-25.05pre-git.drv",
			"/nix/store/h3big3vbjnk32vf0nb5vi80yq0l9ivxb-nixos-system-uranus-25.05pre-git",
			DeployConfig{})
		ctx := context.Background()

		r.Outputs = [][]byte{
			[]byte(testDiffOutput),
		}
		output, err := h.Diff(ctx)
		must.NoError(t, err)
		test.Eq(t, [][]string{{
			"/nix/store/h3big3vbjnk32vf0nb5vi80yq0l9ivxb-nixos-system-uranus-25.05pre-git/bin/nvd-json",
			"diff",
			"/run/current-system",
			"/nix/store/h3big3vbjnk32vf0nb5vi80yq0l9ivxb-nixos-system-uranus-25.05pre-git",
		}}, r.History)
		test.Eq(t, testDiffOutput, string(output))
	})
}
