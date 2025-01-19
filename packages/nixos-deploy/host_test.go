package main

import (
	"testing"

	"github.com/shoenig/test"
)

func TestNewHostSSH(t *testing.T) {
	user := "mjm"
	host := "uranus.home.mattmoriarity.com"

	cfg := Config{SSHOpts: []string{"--foo", "bar"}}
	h := NewHost(cfg, "uranus", "/nix/store/g5dyb9016k8fnz3ng6k50jc7nc5zqhf3-nixos-system-uranus-25.05pre-git.drv", DeployConfig{
		TargetUser: &user,
		TargetHost: &host,
	})

	test.Eq(t, "uranus", h.Name)
	test.Eq(t, "/nix/store/g5dyb9016k8fnz3ng6k50jc7nc5zqhf3-nixos-system-uranus-25.05pre-git.drv", h.DrvPath)
	test.Eq(t, "", h.OutPath)
	test.Eq(t, HostKindSSH, h.Kind)
	test.Eq(t, "mjm", *h.DeployConfig.TargetUser)
	test.Eq(t, "uranus.home.mattmoriarity.com", *h.DeployConfig.TargetHost)
	test.False(t, h.RebootNeeded)
	test.Eq(t, []string{"--foo", "bar"}, h.cfg.SSHOpts)
	test.Eq(t, "mjm@uranus.home.mattmoriarity.com", h.sshTarget)
}

func TestNewHostLocal(t *testing.T) {
	cfg := Config{SSHOpts: []string{"--foo", "bar"}}
	h := NewHost(cfg, "uranus", "/nix/store/g5dyb9016k8fnz3ng6k50jc7nc5zqhf3-nixos-system-uranus-25.05pre-git.drv", DeployConfig{})

	test.Eq(t, "uranus", h.Name)
	test.Eq(t, "/nix/store/g5dyb9016k8fnz3ng6k50jc7nc5zqhf3-nixos-system-uranus-25.05pre-git.drv", h.DrvPath)
	test.Eq(t, "", h.OutPath)
	test.Eq(t, HostKindLocal, h.Kind)
	test.Nil(t, h.DeployConfig.TargetHost)
	test.Nil(t, h.DeployConfig.TargetUser)
	test.False(t, h.RebootNeeded)
	test.Eq(t, []string{"--foo", "bar"}, h.cfg.SSHOpts)
	test.Eq(t, "", h.sshTarget)
}

func TestNewLocalHost(t *testing.T) {
	h := NewLocalHost(
		"uranus",
		"/nix/store/g5dyb9016k8fnz3ng6k50jc7nc5zqhf3-nixos-system-uranus-25.05pre-git.drv",
		"/nix/store/h3big3vbjnk32vf0nb5vi80yq0l9ivxb-nixos-system-uranus-25.05pre-git")

	test.Eq(t, "uranus", h.Name)
	test.Eq(t, "/nix/store/g5dyb9016k8fnz3ng6k50jc7nc5zqhf3-nixos-system-uranus-25.05pre-git.drv", h.DrvPath)
	test.Eq(t, "/nix/store/h3big3vbjnk32vf0nb5vi80yq0l9ivxb-nixos-system-uranus-25.05pre-git", h.OutPath)
	test.Eq(t, HostKindLocal, h.Kind)
	test.Nil(t, h.DeployConfig.TargetHost)
	test.Nil(t, h.DeployConfig.TargetUser)
	test.False(t, h.RebootNeeded)
	test.Nil(t, h.cfg.SSHOpts)
	test.Eq(t, "", h.sshTarget)
}
