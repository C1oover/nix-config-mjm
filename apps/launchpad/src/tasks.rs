use axum::{
    extract::{Path, State},
    response::IntoResponse,
    Form,
};
use chrono::{DateTime, NaiveDateTime, Utc};
use maud::{html, Markup, PreEscaped};
use serde::{Deserialize, Serialize};
use sqlx::{types::Json, PgPool};
use tokio::try_join;

use crate::app;

#[tracing::instrument(skip(pool))]
pub async fn index(State(pool): State<PgPool>) -> Result<impl IntoResponse, app::Error> {
    let (tasks, reminders) = try_join!(list_tasks(&pool), reminder_list(&pool))?;

    Ok(app::layout(
        "Tasks",
        html! {
            h1 { "Tasks" }

            ul #task-list .list-group .mb-2 {
                (render_task_list(&tasks))
            }

            .d-grid .gap-2 .d-md-block .mb-4 {
                button
                    .btn.btn-primary
                    type="button"
                    data-bs-toggle="modal"
                    data-bs-target="#new-task-modal" {
                    "New task"
                }
            }

            h1 { "Reminder" }

            ul #reminder-list .list-group .mb-2 {
                (render_reminder_list(&reminders))
            }

            .d-grid .gap-2 .d-md-block {
                button
                    .btn.btn-primary
                    type="button"
                    data-bs-toggle="modal"
                    data-bs-target="#new-reminder-modal" {
                    "New reminder"
                }
            }

            (render_new_task_modal())
            (render_new_reminder_modal())
        },
    ))
}

#[derive(Deserialize, Debug)]
pub struct NewTaskForm {
    description: String,
    tags: String,
}

#[tracing::instrument(skip(pool))]
pub async fn create_task(
    State(pool): State<PgPool>,
    Form(form): Form<NewTaskForm>,
) -> Result<impl IntoResponse, app::Error> {
    // TODO better error handling/validation
    task_insert(&pool, form).await?;

    let tasks = list_tasks(&pool).await?;

    Ok(html! {
        (render_task_list(&tasks))

        script type="text/javascript" {
            (PreEscaped(r##"
                bootstrap.Modal.getInstance("#new-task-modal").hide();
            "##))
        }

        div hx-swap="innerHTML:#new-task-modal" {
            (render_new_task_modal())
        }
    })
}

#[tracing::instrument(skip(pool))]
pub async fn edit_task(
    State(pool): State<PgPool>,
    Path(id): Path<i64>,
) -> Result<impl IntoResponse, app::Error> {
    let task = task_get(&pool, id).await?;

    Ok(app::layout(
        "Edit task",
        html! {
            h1 { "Edit task" }

            form
                hx-put={ "/tasks/" (task.id) }
                hx-push-url="/tasks"
                hx-swap="outerHTML"
                hx-target="body" {

                .mb-3 {
                    label .form-label for="edit-task-description" {
                        "Description"
                    }
                    input
                        #edit-task-description
                        .form-control
                        name="description"
                        type="text"
                        value=(task.description)
                        autocomplete="off";
                }

                .mb-3 {
                    label .form-label for="edit-task-tags" {
                        "Tags"
                    }
                    input
                        #edit-task-tags
                        .form-control
                        name="tags"
                        type="text"
                        value=(task.tags_string())
                        autocomplete="off";
                }

                .d-grid .gap-2 .d-md-block {
                    button .btn.btn-primary .me-md-2 {
                        "Save"
                    }
                    a .btn.btn-secondary .me-md-2 href="/tasks" {
                        "Cancel"
                    }
                    button
                        .btn.btn-outline-danger
                        type="button"
                        hx-delete={ "/tasks/" (task.id) }
                        hx-confirm="Are you sure you want to delete this task?" {
                        "Delete"
                    }
                }
            }
        },
    ))
}

#[derive(Deserialize, Serialize, Debug)]
pub struct UpdateTaskForm {
    description: String,
    tags: String,
}

#[tracing::instrument(skip(pool))]
pub async fn update_task(
    State(pool): State<PgPool>,
    Path(id): Path<i64>,
    Form(form): Form<UpdateTaskForm>,
) -> Result<impl IntoResponse, app::Error> {
    task_update(&pool, id, form).await?;

    Ok(index(State(pool)).await?)
}

#[tracing::instrument(skip(pool))]
pub async fn toggle_task(
    State(pool): State<PgPool>,
    Path(id): Path<i64>,
) -> Result<impl IntoResponse, app::Error> {
    task_toggle(&pool, id).await?;

    let tasks = list_tasks(&pool).await?;

    Ok(render_task_list(&tasks))
}

#[tracing::instrument(skip(pool))]
pub async fn delete_task(
    State(pool): State<PgPool>,
    Path(id): Path<i64>,
) -> Result<impl IntoResponse, app::Error> {
    task_delete(&pool, id).await?;

    Ok(index(State(pool)).await?)
}

#[derive(Deserialize, Debug)]
pub struct CreateReminderForm {
    description: String,
    tags: String,
    remind_at: String,
    snooze_minutes: i64,
    repeat_interval: String,
}

#[tracing::instrument(skip(pool))]
pub async fn create_reminder(
    State(pool): State<PgPool>,
    Form(form): Form<CreateReminderForm>,
) -> Result<impl IntoResponse, app::Error> {
    reminder_create(&pool, &form).await?;

    let reminders = reminder_list(&pool).await?;

    Ok(html! {
        (render_reminder_list(&reminders))

        script type="text/javascript" {
            (PreEscaped(r##"
                bootstrap.Modal.getInstance("#new-reminder-modal").hide();
            "##))
        }

        div hx-swap="innerHTML:#new-reminder-modal" {
            (render_new_reminder_modal())
        }
    })
}

fn render_task_list(tasks: &[Task]) -> Markup {
    html! {
        @for task in tasks {
            li .list-group-item .d-flex .justify-content-between .align-items-start {
                input
                    #{ "task-check-" (task.id) }
                    .form-check-input
                    .me-2
                    type="checkbox"
                    value=""
                    checked[task.is_completed()]
                    hx-post={ "/tasks/" (task.id) "/toggle"}
                    hx-target="#task-list";

                div .me-auto {
                    label
                        .form-check-label
                        .me-auto
                        .text-secondary-emphasis[task.is_completed()]
                        .text-decoration-line-through[task.is_completed()]
                        for={ "task-check-" (task.id) } {
                        (task.description)
                    }

                    @if !task.tags.is_empty() {
                        div {
                            @for tag in &task.tags {
                                span .badge .text-bg-secondary .me-1 {
                                    (tag)
                                }
                            }
                        }
                    }
                }

                a .btn.btn-primary.btn-sm href={ "/tasks/" (task.id) "/edit" } {
                    "Edit"
                }
            }
        }
    }
}

fn render_reminder_list(reminders: &[Reminder]) -> Markup {
    html! {
        @for reminder in reminders {
            li .list-group-item .d-flex .justify-content-between .align-items-start {
                div .me-auto {
                    (reminder.description)

                    @if !reminder.tags.is_empty() {
                        div {
                            @for tag in &reminder.tags {
                                span .badge .text-bg-secondary .me-1 {
                                    (tag)
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}

fn render_new_task_modal() -> Markup {
    html! {
        #new-task-modal
            .modal .fade
            aria-hidden="true"
            aria-labelledby="new-task-modal-title"
            tabindex="-1" {

            .modal-dialog .modal-fullscreen-md-down {
                .modal-content {
                    form
                        hx-post="/tasks"
                        hx-target="#task-list" {
                        .modal-header {
                            h1 #new-task-modal-title .modal-title .fs-5 {
                                "New task"
                            }
                            button .btn-close type="button" data-bs-dismiss="modal" aria-label="Close" {}
                        }
                        .modal-body {
                            .mb-3 {
                                label .form-label for="new-task-description" { "Description" }
                                input
                                    #new-task-description
                                    .form-control
                                    name="description"
                                    type="text"
                                    autocomplete="off";
                            }

                            .mb-3 {
                                label .form-label for="new-task-tags" { "Tags" }
                                input
                                    #new-task-tags
                                    .form-control
                                    name="tags"
                                    type="text"
                                    autocomplete="off";
                            }
                        }
                        .modal-footer {
                            button .btn.btn-secondary type="button" data-bs-dismiss="modal" { "Close" }
                            button .btn.btn-primary { "Save" }
                        }
                    }
                }
            }
        }
    }
}

fn render_new_reminder_modal() -> Markup {
    let remind_at = Utc::now().format("%Y-%m-%dT%H:%M");

    html! {
        #new-reminder-modal
            .modal .fade
            aria-hidden="true"
            aria-labelledby="new-reminder-modal-title"
            tabindex="-1" {

            .modal-dialog .modal-fullscreen-md-down {
                .modal-content {
                    form
                        hx-post="/reminders"
                        hx-target="#reminder-list" {
                        .modal-header {
                            h1 #new-reminder-modal-title .modal-title .fs-5 {
                                "New reminder"
                            }
                            button .btn-close type="button" data-bs-dismiss="modal" aria-label="Close" {}
                        }
                        .modal-body {
                            .mb-3 {
                                label .form-label for="new-reminder-description" { "Description" }
                                input
                                    #new-reminder-description
                                    .form-control
                                    name="description"
                                    type="text"
                                    autocomplete="off";
                            }

                            .mb-3 {
                                label .form-label for="new-reminder-tags" { "Tags" }
                                input
                                    #new-reminder-tags
                                    .form-control
                                    name="tags"
                                    type="text"
                                    autocomplete="off";
                            }

                            .mb-3 {
                                label .form-label for="new-reminder-remind-at" { "Remind at" }
                                input
                                    #new-reminder-remind-at
                                    .form-control
                                    name="remind_at"
                                    type="datetime-local"
                                    value=(remind_at);
                            }

                            .mb-3 {
                                label .form-label for="new-reminder-snooze-minutes" { "Snooze minutes" }
                                input
                                    #new-reminder-snooze-minutes
                                    .form-control
                                    name="snooze_minutes"
                                    type="number"
                                    value="10"
                                    autocomplete="off";
                            }

                            .mb-3 {
                                label .form-label for="new-reminder-repeat-interval" { "Repeat every" }
                                input
                                    #new-reminder-repeat-interval
                                    .form-control
                                    name="repeat_interval"
                                    type="text"
                                    value=""
                                    autocomplete="off";
                            }
                        }
                        .modal-footer {
                            button .btn.btn-secondary type="button" data-bs-dismiss="modal" { "Close" }
                            button .btn.btn-primary { "Save" }
                        }
                    }
                }
            }
        }
    }
}

#[derive(Serialize)]
struct Task {
    id: i64,
    description: String,
    tags: Vec<String>,
    completed_at: Option<DateTime<Utc>>,
    created_at: DateTime<Utc>,
    updated_at: DateTime<Utc>,
}

impl Task {
    fn is_completed(self: &Task) -> bool {
        match self.completed_at {
            None => false,
            Some(_) => true,
        }
    }

    fn tags_string(self: &Task) -> String {
        self.tags.join(", ")
    }
}

#[tracing::instrument(skip(pool))]
async fn list_tasks(pool: &PgPool) -> anyhow::Result<Vec<Task>> {
    Ok(sqlx::query_as!(
        Task,
        r#"
SELECT id, description, tags, completed_at, created_at, updated_at
FROM tasks
ORDER BY
    (CASE WHEN completed_at IS NULL THEN 0 ELSE 1 END),
    (CASE WHEN completed_at IS NULL THEN created_at ELSE completed_at END)
        "#
    )
    .fetch_all(pool)
    .await?)
}

#[tracing::instrument(skip(pool))]
async fn task_insert(pool: &PgPool, t: NewTaskForm) -> anyhow::Result<Task> {
    Ok(sqlx::query_as!(
        Task,
        r#"
INSERT INTO tasks
(description, tags)
VALUES
($1, $2)
RETURNING *
        "#,
        t.description,
        &split_tags(&t.tags)
    )
    .fetch_one(pool)
    .await?)
}

#[tracing::instrument(skip(pool))]
async fn task_get(pool: &PgPool, id: i64) -> anyhow::Result<Task> {
    Ok(sqlx::query_as!(
        Task,
        r#"
SELECT id, description, tags, completed_at, created_at, updated_at
FROM tasks
WHERE id = $1
        "#,
        id
    )
    .fetch_one(pool)
    .await?)
}

#[tracing::instrument(skip(pool))]
async fn task_toggle(pool: &PgPool, id: i64) -> anyhow::Result<Task> {
    Ok(sqlx::query_as!(
        Task,
        r#"
UPDATE tasks
SET completed_at = (CASE WHEN completed_at IS NULL THEN current_timestamp ELSE NULL END)
WHERE id = $1
RETURNING *
        "#,
        id
    )
    .fetch_one(pool)
    .await?)
}

#[tracing::instrument(skip(pool))]
async fn task_update(pool: &PgPool, id: i64, t: UpdateTaskForm) -> anyhow::Result<Task> {
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
        &split_tags(&t.tags)
    )
    .fetch_one(pool)
    .await?)
}

#[tracing::instrument(skip(pool))]
async fn task_delete(pool: &PgPool, id: i64) -> anyhow::Result<()> {
    sqlx::query!(
        r#"
DELETE FROM tasks
WHERE id = $1
        "#,
        id
    )
    .execute(pool)
    .await?;

    Ok(())
}

fn split_tags(s: &str) -> Vec<String> {
    s.split(",")
        .map(|s| s.trim().to_string())
        .filter(|s| !s.is_empty())
        .collect()
}

#[derive(Debug)]
struct Reminder {
    id: i64,
    description: String,
    tags: Vec<String>,
    state: ReminderState,
    remind_at: DateTime<Utc>,
    snooze_minutes: i64,
    repeat_interval: Option<Json<RepeatInterval>>,
}

#[derive(sqlx::Type, Debug)]
#[sqlx(type_name = "reminder_state", rename_all = "snake_case")]
enum ReminderState {
    Pending,
    Firing,
    Completed,
}

#[derive(Deserialize, Serialize, Debug)]
struct RepeatInterval {
    months: i32,
    weeks: i32,
    days: i32,
}

async fn reminder_list(pool: &PgPool) -> anyhow::Result<Vec<Reminder>> {
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
ORDER BY remind_at
        "#
    )
    .fetch_all(pool)
    .await?)
}

async fn reminder_create(pool: &PgPool, t: &CreateReminderForm) -> anyhow::Result<Reminder> {
    let tags = split_tags(&t.tags);
    let remind_at = NaiveDateTime::parse_from_str(&t.remind_at, "%Y-%m-%dT%H:%M")?
        // TODO this should actually use the local timezone from the user
        .and_local_timezone(Utc)
        .unwrap();
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
        &t.description,
        &tags,
        &remind_at,
        t.snooze_minutes
    )
    .fetch_one(pool)
    .await?)
}
