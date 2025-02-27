package main

import (
	"bytes"
	"testing"

	"github.com/shoenig/test/must"
)

func TestFormatDiffEmpty(t *testing.T) {
	d := AggregatedDiff{}
	var b bytes.Buffer
	must.NoError(t, d.Write(&b))
	must.Eq(t, ``, b.String())
}

func TestFormatDiffSingleSection(t *testing.T) {
	d := AggregatedDiff{
		VersionChanges: []AggregatedVersionChange{
			{
				Pname: "cpupower",
				Hosts: []PerHostVersionChange{
					{
						Hostname:    "arges",
						OldVersions: []string{"6.6.72"},
						NewVersions: []string{"6.12.10"},
					},
					{
						Hostname:    "brontes",
						OldVersions: []string{"6.6.72"},
						NewVersions: []string{"6.12.10"},
					},
					{
						Hostname:    "steropes",
						OldVersions: []string{"6.6.72"},
						NewVersions: []string{"6.12.10"},
					},
				},
			},
		},
	}

	var b bytes.Buffer
	must.NoError(t, d.Write(&b))
	must.Eq(t, `## Version changes

- **cpupower**
  - `+"`arges`"+`: 6.6.72 -> 6.12.10
  - `+"`brontes`"+`: 6.6.72 -> 6.12.10
  - `+"`steropes`"+`: 6.6.72 -> 6.12.10

`, b.String())
}

func TestFormaDiffMultipleSections(t *testing.T) {
	d := AggregatedDiff{
		RebootPackages: []AggregatedVersionChange{
			{
				Pname: "linux",
				Hosts: []PerHostVersionChange{
					{
						Hostname:    "arges",
						OldVersions: []string{"6.6.72", "6.6.72-modules", "6.6.72-modules-shrunk"},
						NewVersions: []string{"6.12.10", "6.12.10-modules", "6.12.10-modules-shrunk"},
					},
					{
						Hostname:    "brontes",
						OldVersions: []string{"6.6.72", "6.6.72-modules", "6.6.72-modules-shrunk"},
						NewVersions: []string{"6.12.10", "6.12.10-modules", "6.12.10-modules-shrunk"},
					},
					{
						Hostname:    "steropes",
						OldVersions: []string{"6.6.72", "6.6.72-modules", "6.6.72-modules-shrunk"},
						NewVersions: []string{"6.12.10", "6.12.10-modules", "6.12.10-modules-shrunk"},
					},
				},
			},
		},
		VersionChanges: []AggregatedVersionChange{
			{
				Pname: "cpupower",
				Hosts: []PerHostVersionChange{
					{
						Hostname:    "arges",
						OldVersions: []string{"6.6.72"},
						NewVersions: []string{"6.12.10"},
					},
					{
						Hostname:    "brontes",
						OldVersions: []string{"6.6.72"},
						NewVersions: []string{"6.12.10"},
					},
					{
						Hostname:    "steropes",
						OldVersions: []string{"6.6.72"},
						NewVersions: []string{"6.12.10"},
					},
				},
			},
		},
		AddedPackages: []AggregatedVersionChange{
			{
				Pname: "chroot-realpath",
				Hosts: []PerHostVersionChange{
					{
						Hostname:    "arges",
						NewVersions: []string{"0.1.0"},
					},
					{
						Hostname:    "brontes",
						NewVersions: []string{"0.1.0"},
					},
					{
						Hostname:    "steropes",
						NewVersions: []string{"0.1.0"},
					},
				},
			},
		},
		RemovedPackages: []AggregatedVersionChange{
			{
				Pname: "nixos-small-patched",
				Hosts: []PerHostVersionChange{
					{
						Hostname:    "arges",
						NewVersions: []string{""},
					},
					{
						Hostname:    "brontes",
						NewVersions: []string{""},
					},
					{
						Hostname:    "steropes",
						NewVersions: []string{""},
					},
				},
			},
		},
	}

	var b bytes.Buffer
	must.NoError(t, d.Write(&b))
	must.Eq(t, `## Changes requiring reboot

- **linux**
  - `+"`arges`"+`: 6.6.72, 6.6.72-modules, 6.6.72-modules-shrunk -> 6.12.10, 6.12.10-modules, 6.12.10-modules-shrunk
  - `+"`brontes`"+`: 6.6.72, 6.6.72-modules, 6.6.72-modules-shrunk -> 6.12.10, 6.12.10-modules, 6.12.10-modules-shrunk
  - `+"`steropes`"+`: 6.6.72, 6.6.72-modules, 6.6.72-modules-shrunk -> 6.12.10, 6.12.10-modules, 6.12.10-modules-shrunk

## Version changes

- **cpupower**
  - `+"`arges`"+`: 6.6.72 -> 6.12.10
  - `+"`brontes`"+`: 6.6.72 -> 6.12.10
  - `+"`steropes`"+`: 6.6.72 -> 6.12.10

## Added

- **chroot-realpath**
  - `+"`arges`"+`: 0.1.0
  - `+"`brontes`"+`: 0.1.0
  - `+"`steropes`"+`: 0.1.0

## Removed

- **nixos-small-patched**
  - `+"`arges`"+`: 
  - `+"`brontes`"+`: 
  - `+"`steropes`"+`: 

`, b.String())
}
