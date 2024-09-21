pub(crate) mod routes;

use anyhow::{bail, Result};
use chrono::{DateTime, Utc};
use serde::{Deserialize, Serialize};
use sqlx::{types::Json, Acquire, PgConnection, PgExecutor, PgPool, Postgres};

#[derive(Serialize, Debug)]
pub struct Task {
    pub id: i64,
    pub description: String,
    pub tags: Vec<String>,
    pub completed_at: Option<DateTime<Utc>>,
    pub reminder_id: Option<i64>,
    pub notify_at: Option<DateTime<Utc>>,
    pub created_at: DateTime<Utc>,
    pub updated_at: DateTime<Utc>,
}

impl Task {
    pub fn is_completed(self: &Task) -> bool {
        self.completed_at.is_some()
    }

    pub fn tags_string(self: &Task) -> String {
        self.tags.join(", ")
    }

    #[tracing::instrument(skip(e), ret, err)]
    pub async fn list<'e, E: PgExecutor<'e>>(e: E) -> Result<Vec<Task>> {
        Ok(sqlx::query_as!(
            Task,
            r#"
SELECT *
FROM tasks
WHERE (
    completed_at IS NULL OR completed_at > current_timestamp - interval '1 day'
)
ORDER BY
    (CASE WHEN completed_at IS NULL THEN 0 ELSE 1 END),
    (CASE WHEN completed_at IS NULL THEN created_at ELSE completed_at END)
            "#
        )
        .fetch_all(e)
        .await?)
    }

    #[tracing::instrument(skip(e), ret, err)]
    async fn get<'e, E: PgExecutor<'e>>(e: E, id: i64) -> Result<Task> {
        Ok(sqlx::query_as!(
            Task,
            r#"
SELECT *
FROM tasks
WHERE id = $1
            "#,
            id
        )
        .fetch_one(e)
        .await?)
    }

    #[tracing::instrument(skip(e), ret, err)]
    pub async fn insert<'e, E: PgExecutor<'e>>(e: E, t: &TaskInsertInput) -> Result<Task> {
        Ok(sqlx::query_as!(
            Task,
            r#"
INSERT INTO tasks
(description, tags, reminder_id, notify_at)
VALUES
($1, $2, $3, $4)
RETURNING *
            "#,
            &t.description,
            &t.tags,
            t.reminder_id,
            t.notify_at,
        )
        .fetch_one(e)
        .await?)
    }

    #[tracing::instrument(skip(conn), ret, err)]
    async fn toggle<'a, A: Acquire<'a, Database = Postgres>>(conn: A, id: i64) -> Result<Task> {
        let mut tx = conn.begin().await?;

        let task = Self::get(&mut *tx, id).await?;
        let result = match task.reminder_id {
            Some(reminder_id) => Self::toggle_reminder_task(&mut *tx, &task, reminder_id).await?,
            None => Self::toggle_simple_task(&mut *tx, id).await?,
        };

        tx.commit().await?;

        Ok(result)
    }

    #[tracing::instrument(skip(conn), ret, err)]
    async fn toggle_simple_task(conn: &mut PgConnection, id: i64) -> Result<Task> {
        Ok(sqlx::query_as!(
            Task,
            r#"
UPDATE tasks
SET completed_at = (CASE WHEN completed_at IS NULL THEN current_timestamp ELSE NULL END),
    updated_at = current_timestamp
WHERE id = $1
RETURNING *
            "#,
            id
        )
        .fetch_one(&mut *conn)
        .await?)
    }

    #[tracing::instrument(skip(conn), ret, err)]
    async fn toggle_reminder_task(
        conn: &mut PgConnection,
        task: &Task,
        reminder_id: i64,
    ) -> Result<Task> {
        if task.is_completed() {
            bail!("cannot uncomplete an already completed reminder");
        }

        let updated_task = sqlx::query_as!(
            Task,
            r#"
UPDATE tasks
SET completed_at = current_timestamp,
    updated_at = current_timestamp
WHERE id = $1
RETURNING *
            "#,
            task.id
        )
        .fetch_one(&mut *conn)
        .await?;

        let reminder = Reminder::get(&mut *conn, reminder_id).await?;
        match reminder.repeat_interval {
            None => {
                sqlx::query!(
                    r#"
UPDATE reminders
SET state = 'completed',
    updated_at = current_timestamp
WHERE id = $1
                    "#,
                    reminder.id
                )
                .execute(&mut *conn)
                .await?;
            }
            //   if repeat interval, advance remind_at and set back to pending
            Some(_) => todo!("repeating reminders aren't implemented yet"),
        }

        Ok(updated_task)
    }

    #[tracing::instrument(skip(e), ret, err)]
    async fn update<'e, E: PgExecutor<'e>>(e: E, id: i64, t: &TaskUpdateInput) -> Result<Task> {
        Ok(sqlx::query_as!(
            Task,
            r#"
UPDATE tasks
SET description = $2,
    tags = $3
WHERE id = $1
RETURNING *
            "#,
            id,
            t.description,
            &t.tags,
        )
        .fetch_one(e)
        .await?)
    }

    #[tracing::instrument(skip(e), err)]
    async fn delete<'e, E: PgExecutor<'e>>(e: E, id: i64) -> Result<()> {
        sqlx::query!(
            r#"
DELETE FROM tasks
WHERE id = $1
            "#,
            id
        )
        .execute(e)
        .await?;

        Ok(())
    }
}

#[derive(Debug)]
pub struct TaskInsertInput {
    description: String,
    tags: Vec<String>,
    reminder_id: Option<i64>,
    notify_at: Option<DateTime<Utc>>,
}

#[derive(Debug)]
pub struct TaskUpdateInput {
    pub description: String,
    pub tags: Vec<String>,
}

pub fn split_tags(s: &str) -> Vec<String> {
    s.split(",")
        .map(|s| s.trim().to_string())
        .filter(|s| !s.is_empty())
        .collect()
}

#[derive(Debug)]
pub struct Reminder {
    pub id: i64,
    pub description: String,
    pub tags: Vec<String>,
    pub state: ReminderState,
    pub remind_at: DateTime<Utc>,
    pub snooze_minutes: i64,
    pub repeat_interval: Option<Json<RepeatInterval>>,
}

#[derive(sqlx::Type, Debug)]
#[sqlx(type_name = "reminder_state", rename_all = "snake_case")]
pub enum ReminderState {
    Pending,
    Firing,
    Completed,
}

#[derive(Deserialize, Serialize, Debug)]
pub struct RepeatInterval {
    pub months: i32,
    pub weeks: i32,
    pub days: i32,
}

impl Reminder {
    fn is_firing(self: &Self) -> bool {
        self.state.is_firing()
    }

    pub fn tags_string(self: &Self) -> String {
        self.tags.join(", ")
    }

    #[tracing::instrument(skip(e), ret, err)]
    pub async fn list<'e, E: PgExecutor<'e>>(e: E) -> Result<Vec<Reminder>> {
        Ok(sqlx::query_as!(
            Reminder,
            r#"
SELECT id,
       description,
       tags,
       state as "state: _",
       remind_at,
       snooze_minutes,
       repeat_interval as "repeat_interval: _"
FROM reminders
WHERE state IN ('pending', 'firing')
ORDER BY remind_at
            "#
        )
        .fetch_all(e)
        .await?)
    }

    #[tracing::instrument(skip(e), ret, err)]
    async fn list_outstanding<'e, E: PgExecutor<'e>>(e: E) -> Result<Vec<Reminder>> {
        Ok(sqlx::query_as!(
            Reminder,
            r#"
SELECT id,
       description,
       tags,
       state as "state: _",
       remind_at,
       snooze_minutes,
       repeat_interval as "repeat_interval: _"
FROM reminders
WHERE state = 'pending'
AND remind_at < current_timestamp
            "#
        )
        .fetch_all(e)
        .await?)
    }

    #[tracing::instrument(skip(e), ret, err)]
    async fn get<'e, E: PgExecutor<'e>>(e: E, id: i64) -> Result<Reminder> {
        Ok(sqlx::query_as!(
            Reminder,
            r#"
SELECT id,
       description,
       tags,
       state as "state: _",
       remind_at,
       snooze_minutes,
       repeat_interval as "repeat_interval: _"
FROM reminders
WHERE id = $1
            "#,
            id
        )
        .fetch_one(e)
        .await?)
    }

    #[tracing::instrument(skip(e), ret, err)]
    async fn insert<'e, E: PgExecutor<'e>>(e: E, r: &ReminderInsertInput) -> Result<Reminder> {
        // TODO repeat interval

        Ok(sqlx::query_as!(
            Reminder,
            r#"
INSERT INTO reminders
(description, tags, remind_at, snooze_minutes)
VALUES
($1, $2, $3, $4)
RETURNING
id, description, tags, state as "state: _", remind_at, snooze_minutes, repeat_interval as "repeat_interval: _"
            "#,
            &r.description,
            &r.tags,
            &r.remind_at,
            r.snooze_minutes
        )
        .fetch_one(e)
        .await?)
    }

    #[tracing::instrument(skip(conn), ret, err)]
    async fn update(conn: &mut PgConnection, id: i64, r: &ReminderUpdateInput) -> Result<Reminder> {
        // TODO repeat interval

        Ok(sqlx::query_as!(
            Reminder,
            r#"
UPDATE reminders
SET description = $2,
    tags = $3,
    remind_at = $4,
    snooze_minutes = $5
WHERE id = $1
RETURNING
id, description, tags, state as "state: _", remind_at, snooze_minutes, repeat_interval as "repeat_interval: _"
            "#,
            id,
            &r.description,
            &r.tags,
            &r.remind_at,
            r.snooze_minutes
        ).fetch_one(&mut *conn)
        .await?)
    }

    #[tracing::instrument(skip(e), ret, err)]
    async fn set_current_task<'e, E: PgExecutor<'e>>(
        e: E,
        id: i64,
        task_id: i64,
    ) -> Result<Reminder> {
        Ok(sqlx::query_as!(
            Reminder,
            r#"
UPDATE reminders
SET current_task_id = $2,
    state = 'firing',
    updated_at = current_timestamp
WHERE id = $1
RETURNING
id, description, tags, state as "state: _", remind_at, snooze_minutes, repeat_interval as "repeat_interval: _"
            "#,
            id,
            task_id
        )
        .fetch_one(e)
        .await?)
    }

    #[tracing::instrument(skip(pool), err)]
    pub async fn process_outstanding(pool: &PgPool) -> Result<()> {
        let mut tx = pool.begin().await?;

        let reminders = Self::list_outstanding(&mut *tx).await?;
        if reminders.is_empty() {
            return Ok(());
        }

        let now = Utc::now();

        for reminder in reminders.iter() {
            let task = Task::insert(
                &mut *tx,
                &TaskInsertInput {
                    description: reminder.description.clone(),
                    tags: reminder.tags.clone(),
                    reminder_id: Some(reminder.id),
                    notify_at: Some(now),
                },
            )
            .await?;

            Self::set_current_task(&mut *tx, reminder.id, task.id).await?;
        }

        // TODO notify for reminder tasks

        Ok(tx.commit().await?)
    }
}

impl ReminderState {
    fn is_firing(self: &Self) -> bool {
        match self {
            Self::Firing => true,
            _ => false,
        }
    }
}

#[derive(Debug)]
struct ReminderInsertInput {
    description: String,
    tags: Vec<String>,
    remind_at: DateTime<Utc>,
    snooze_minutes: i64,
    repeat_interval: Option<RepeatInterval>,
}

#[derive(Debug)]
struct ReminderUpdateInput {
    description: String,
    tags: Vec<String>,
    remind_at: DateTime<Utc>,
    snooze_minutes: i64,
    repeat_interval: Option<RepeatInterval>,
}
