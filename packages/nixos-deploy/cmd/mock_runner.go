package cmd

import "context"

type MockRunner struct {
	Outputs [][]byte
	History [][]string
}

func (r *MockRunner) Execute(ctx context.Context, name string, args ...string) error {
	c := []string{name}
	c = append(c, args...)
	r.History = append(r.History, c)
	return nil
}

func (r *MockRunner) ExecuteOutput(ctx context.Context, name string, args ...string) ([]byte, error) {
	c := []string{name}
	c = append(c, args...)
	r.History = append(r.History, c)

	o := r.Outputs[0]
	r.Outputs = r.Outputs[1:]
	return o, nil
}
