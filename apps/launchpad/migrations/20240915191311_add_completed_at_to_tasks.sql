ALTER TABLE tasks ADD COLUMN completed_at timestamptz;

UPDATE tasks SET completed_at = current_timestamp WHERE completed = true;

ALTER TABLE tasks DROP COLUMN completed;
