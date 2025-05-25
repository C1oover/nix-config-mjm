package main

import (
	"context"
	"encoding/json"
	"fmt"
	"io"
	"iter"
	"log/slog"
	"os"
	"slices"
	"strings"

	"github.com/spiffe/go-spiffe/v2/spiffeid"
	entryv1 "github.com/spiffe/spire-api-sdk/proto/spire/api/server/entry/v1"
	"github.com/spiffe/spire-api-sdk/proto/spire/api/types"
	"google.golang.org/grpc"
	"google.golang.org/grpc/codes"
	"google.golang.org/grpc/credentials/insecure"
	"google.golang.org/protobuf/encoding/protojson"
)

type RunCmd struct {
	Input       *os.File `arg:""`
	APIAddr     string   `default:"unix:/run/spire-server/api.sock"`
	EntriesPath *os.File `optional:""`
}

func (c *RunCmd) Run(ctx context.Context) error {
	defer c.Input.Close()

	var entriesIn []*registrationEntry
	if err := json.NewDecoder(c.Input).Decode(&entriesIn); err != nil {
		return fmt.Errorf("decoding input entries: %w", err)
	}

	var entries []*types.Entry
	for i, e := range entriesIn {
		e2, err := e.ToProto()
		if err != nil {
			return fmt.Errorf("converting entry at index %d to proto: %w", i, err)
		}

		entries = append(entries, e2)
	}

	if c.EntriesPath == nil {
		conn, err := grpc.NewClient(c.APIAddr, grpc.WithTransportCredentials(insecure.NewCredentials()))
		if err != nil {
			return fmt.Errorf("connecting to %q: %w", c.APIAddr, err)
		}
		defer conn.Close()

		entryClient := entryv1.NewEntryClient(conn)
		existingEntries, err := entryClient.ListEntries(ctx, &entryv1.ListEntriesRequest{})
		if err != nil {
			return fmt.Errorf("listing existing entries: %w", err)
		}

		r := diffEntries(existingEntries.Entries, entries)

		createRes, err := entryClient.BatchCreateEntry(ctx, &entryv1.BatchCreateEntryRequest{
			Entries: r.Added,
		})
		if err != nil {
			return fmt.Errorf("batch creating entries: %w", err)
		}

		var count int
		for i, res := range createRes.GetResults() {
			code := codes.Code(res.GetStatus().GetCode())
			if code == codes.OK {
				count++
			} else {
				slog.Warn("failed to create entry", "entry", r.Added[i], "code", code, "msg", res.GetStatus().GetMessage())
			}
		}
		slog.Info("created entries", "count", count)

		updateRes, err := entryClient.BatchUpdateEntry(ctx, &entryv1.BatchUpdateEntryRequest{
			Entries: r.Updated,
			InputMask: &types.EntryMask{
				SpiffeId:  true,
				ParentId:  true,
				Selectors: true,
				DnsNames:  true,
			},
		})
		if err != nil {
			return fmt.Errorf("batch updating entries: %w", err)
		}

		count = 0
		for _, res := range updateRes.GetResults() {
			code := codes.Code(res.GetStatus().GetCode())
			if code == codes.OK {
				count++
			} else {
				slog.Warn("failed to update entry", "entry", res.GetEntry(), "code", code, "msg", res.GetStatus().GetMessage())
			}
		}
		slog.Info("updated entries", "count", count)

		var ids []string
		for _, e := range r.Removed {
			ids = append(ids, e.GetId())
		}

		deleteRes, err := entryClient.BatchDeleteEntry(ctx, &entryv1.BatchDeleteEntryRequest{
			Ids: ids,
		})
		if err != nil {
			return fmt.Errorf("batch deleting entries: %w", err)
		}

		count = 0
		for _, res := range deleteRes.GetResults() {
			code := codes.Code(res.GetStatus().GetCode())
			if code == codes.OK {
				count++
			} else {
				slog.Warn("failed to delete entry", "id", res.GetId(), "code", code, "msg", res.GetStatus().GetMessage())
			}
		}
		slog.Info("deleted entries", "count", count)
	} else {
		defer c.EntriesPath.Close()
		entriesRaw, err := io.ReadAll(c.EntriesPath)
		if err != nil {
			return fmt.Errorf("reading from %q: %w", c.EntriesPath.Name(), err)
		}

		var existingEntries entryv1.ListEntriesResponse
		if err := protojson.Unmarshal(entriesRaw, &existingEntries); err != nil {
			return fmt.Errorf("unmarshalling entries: %w", err)
		}

		r := diffEntries(existingEntries.Entries, entries)

		fmt.Println("added:")
		for _, e := range r.Added {
			fmt.Println(e)
		}

		fmt.Println("updated:")
		for _, e := range r.Updated {
			fmt.Println(e)
		}

		fmt.Println("removed:")
		for _, e := range r.Removed {
			fmt.Println(e)
		}

		fmt.Println("unchanged:")
		for _, e := range r.Unchanged {
			fmt.Println(e)
		}
	}

	return nil
}

type diffResult struct {
	Added     []*types.Entry
	Removed   []*types.Entry
	Updated   []*types.Entry
	Unchanged []*types.Entry
}

func diffEntries(before, after []*types.Entry) diffResult {
	slices.SortFunc(before, entryCompare)
	slices.SortFunc(after, entryCompare)

	var r diffResult

	nextBefore, stopBefore := iter.Pull(slices.Values(before))
	defer stopBefore()
	nextAfter, stopAfter := iter.Pull(slices.Values(after))
	defer stopAfter()

	x, moreBefore := nextBefore()
	y, moreAfter := nextAfter()
	for moreBefore && moreAfter {
		result := entryCompare(x, y)
		if result == 0 {
			if entryNeedsUpdate(x, y) {
				y.Id = x.Id
				r.Updated = append(r.Updated, y)
			} else {
				r.Unchanged = append(r.Unchanged, y)
			}
			x, moreBefore = nextBefore()
			y, moreAfter = nextAfter()
		} else if result < 0 {
			if !strings.HasPrefix(x.GetParentId().GetPath(), "/spire/agent/join_token/") {
				r.Removed = append(r.Removed, x)
			}
			x, moreBefore = nextBefore()
		} else {
			r.Added = append(r.Added, y)
			y, moreAfter = nextAfter()
		}
	}

	for moreBefore {
		r.Removed = append(r.Removed, x)
		x, moreBefore = nextBefore()
	}

	for moreAfter {
		r.Added = append(r.Added, y)
		y, moreAfter = nextAfter()
	}

	return r
}

// this assumes the entries already compared equal by entryCompare, so
// don't need to check those fields
func entryNeedsUpdate(a, b *types.Entry) bool {
	return !slices.Equal(a.GetDnsNames(), b.GetDnsNames())
}

func entryCompare(a, b *types.Entry) int {
	result := spiffeIDCompare(a.GetSpiffeId(), b.GetSpiffeId())
	if result != 0 {
		return result
	}
	result = spiffeIDCompare(a.GetParentId(), b.GetParentId())
	if result != 0 {
		return result
	}
	return slices.CompareFunc(a.GetSelectors(), b.GetSelectors(), selectorCompare)
}

func spiffeIDCompare(a, b *types.SPIFFEID) int {
	result := strings.Compare(a.GetTrustDomain(), b.GetTrustDomain())
	if result == 0 {
		result = strings.Compare(a.GetPath(), b.GetPath())
	}
	return result
}

func selectorCompare(a, b *types.Selector) int {
	result := strings.Compare(a.GetType(), b.GetType())
	if result == 0 {
		result = strings.Compare(a.GetValue(), b.GetValue())
	}
	return result
}

type registrationEntry struct {
	SpiffeID  string                      `json:"spiffe_id"`
	ParentID  string                      `json:"parent_id"`
	Selectors []registrationEntrySelector `json:"selectors"`
	DNSNames  []string                    `json:"dns_names"`
}

func (e registrationEntry) ToProto() (*types.Entry, error) {
	spiffeID, err := spiffeid.FromString(e.SpiffeID)
	if err != nil {
		return nil, err
	}
	parentID, err := spiffeid.FromString(e.ParentID)
	if err != nil {
		return nil, err
	}

	var selectors []*types.Selector
	for _, s := range e.Selectors {
		selectors = append(selectors, &types.Selector{
			Type:  s.Type,
			Value: s.Value,
		})
	}

	return &types.Entry{
		SpiffeId: &types.SPIFFEID{
			TrustDomain: spiffeID.TrustDomain().String(),
			Path:        spiffeID.Path(),
		},
		ParentId: &types.SPIFFEID{
			TrustDomain: parentID.TrustDomain().String(),
			Path:        parentID.Path(),
		},
		Selectors: selectors,
		DnsNames:  e.DNSNames,
	}, nil
}

type registrationEntrySelector struct {
	Type  string `json:"type"`
	Value string `json:"value"`
}
