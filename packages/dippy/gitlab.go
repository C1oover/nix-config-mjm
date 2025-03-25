package main

import (
	"context"
	"fmt"

	"gitlab.com/gitlab-org/api/client-go"
)

type createMergeRequestNoteArgs struct {
	BaseURL        string
	Token          string
	Project        int
	MergeRequestID int
	Body           string
}

func createMergeRequestNote(ctx context.Context, args *createMergeRequestNoteArgs) error {
	c, err := gitlab.NewClient(args.Token, gitlab.WithBaseURL(args.BaseURL))
	if err != nil {
		return fmt.Errorf("creating gitlab client: %w", err)
	}

	if _, _, err := c.Notes.CreateMergeRequestNote(args.Project, args.MergeRequestID, &gitlab.CreateMergeRequestNoteOptions{
		Body: gitlab.Ptr(args.Body),
	}, gitlab.WithContext(ctx)); err != nil {
		return fmt.Errorf("creating merge request note: %w", err)
	}

	return nil
}
