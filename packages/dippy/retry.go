package main

import "log/slog"

func Retry(times int, f func() error) error {
	err := f()
	if times == 0 {
		return err
	}

	if err != nil {
		slog.Warn("retrying failed operation", "attempts_remaining", times, "error", err)
		times--
		return Retry(times, f)
	}
	return nil
}
