package main

import (
	_ "embed"
	"io"
	"slices"
	"strings"
	"text/template"
)

//go:embed diff.tmpl
var diffTmplText string
var diffTmpl = template.Must(template.New("diff").Parse(diffTmplText))

type AggregatedDiff struct {
	RebootPackages  []AggregatedVersionChange `json:"reboot_packages"`
	VersionChanges  []AggregatedVersionChange `json:"version_changes"`
	AddedPackages   []AggregatedVersionChange `json:"added_packages"`
	RemovedPackages []AggregatedVersionChange `json:"removed_packages"`
}

type AggregatedVersionChange struct {
	Pname string                 `json:"pname"`
	Hosts []PerHostVersionChange `json:"hosts"`
}

type PerHostVersionChange struct {
	Hostname    string   `json:"hostname"`
	OldVersions []string `json:"old_versions"`
	NewVersions []string `json:"new_versions"`
}

type diffSection struct {
	Heading string
	Changes []AggregatedVersionChange
}

func (d AggregatedDiff) Write(wr io.Writer) error {
	return diffTmpl.Execute(wr, d)
}

func (d AggregatedDiff) Sections() []diffSection {
	secs := []diffSection{
		{"Changes requiring reboot", d.RebootPackages},
		{"Version changes", d.VersionChanges},
		{"Added", d.AddedPackages},
		{"Removed", d.RemovedPackages},
	}

	return slices.DeleteFunc(secs, func(s diffSection) bool {
		return len(s.Changes) == 0
	})
}

func (vc PerHostVersionChange) OldVersionsString() string {
	return strings.Join(vc.OldVersions, ", ")
}

func (vc PerHostVersionChange) NewVersionsString() string {
	return strings.Join(vc.NewVersions, ", ")
}
