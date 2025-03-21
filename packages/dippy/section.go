package main

import (
	"fmt"
	"os"
	"time"
)

type logSection string

var sectionIdx int

func sectionStart(header string, collapsed bool) logSection {
	if !*ciSections {
		return ""
	}

	s := logSection(fmt.Sprintf("section%d", sectionIdx))
	sectionIdx++

	now := time.Now().Unix()
	var c string
	if collapsed {
		c = "[collapsed=true]"
	}
	fmt.Fprintf(os.Stderr, "\033[0Ksection_start:%d:%s%s\r\033[0K\033[1;35m%s\033[0m\n", now, s, c, header)

	return s
}

func sectionEnd(s logSection) {
	if !*ciSections {
		return
	}

	now := time.Now().Unix()
	fmt.Fprintf(os.Stderr, "\033[0Ksection_end:%d:%s\r\033[0K", now, s)
}
