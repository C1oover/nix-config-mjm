ALTER TABLE tasks
    ADD COLUMN reminder_id bigint REFERENCES reminders (id) ON DELETE SET NULL,
    ADD COLUMN notify_at timestamptz;

ALTER TABLE reminders
    ADD COLUMN current_task_id bigint REFERENCES tasks (id) ON DELETE SET NULL;
