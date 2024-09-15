use axum::{
    extract::{Path, State},
    response::IntoResponse,
    Form,
};
use chrono::{DateTime, Utc};
use maud::{html, Markup, PreEscaped};
use serde::{Deserialize, Serialize};
use sqlx::PgPool;

use crate::app;

pub async fn index(State(pool): State<PgPool>) -> Result<impl IntoResponse, app::Error> {
    let tasks = list_tasks(&pool).await?;

    Ok(app::layout(
        "Tasks",
        html! {
            h1 { "Tasks" }

            ul #task-list .list-group .mb-2 {
                (render_task_list(&tasks))
            }

            .d-grid .gap-2 .d-md-block {
                button
                    .btn.btn-primary
                    type="button"
                    data-bs-toggle="modal"
                    data-bs-target="#new-task-modal" {
                    "New task"
                }
            }

            (render_new_task_modal())
        },
    ))
}

#[derive(Deserialize, Debug)]
pub struct NewTaskForm {
    description: String,
}

#[tracing::instrument(skip(pool))]
pub async fn create_task(
    State(pool): State<PgPool>,
    Form(form): Form<NewTaskForm>,
) -> Result<impl IntoResponse, app::Error> {
    // TODO better error handling/validation
    insert_task(&pool, form).await?;

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

                .d-grid .gap-2 .d-md-block {
                    button .btn.btn-primary {
                        "Save"
                    }
                }
            }
        },
    ))
}

#[derive(Deserialize, Serialize, Debug)]
pub struct UpdateTaskForm {
    description: String,
}

pub async fn update_task(
    State(pool): State<PgPool>,
    Path(id): Path<i64>,
    Form(form): Form<UpdateTaskForm>,
) -> Result<impl IntoResponse, app::Error> {
    task_update(&pool, id, form).await?;

    Ok(index(State(pool)).await?)
}

pub async fn toggle_task(
    State(pool): State<PgPool>,
    Path(id): Path<i64>,
) -> Result<impl IntoResponse, app::Error> {
    task_toggle(&pool, id).await?;

    let tasks = list_tasks(&pool).await?;

    Ok(render_task_list(&tasks))
}

fn render_task_list(tasks: &[Task]) -> Markup {
    html! {
        @for task in tasks {
            li .list-group-item .d-flex .justify-content-between .align-items-start {
                .me-auto {
                    input
                        #{ "task-check-" (task.id) }
                        .form-check-input
                        .me-1
                        type="checkbox"
                        value=""
                        checked[task.completed]
                        hx-post={ "/tasks/" (task.id) "/toggle"}
                        hx-target="#task-list";
                    " "
                    label
                        .form-check-label
                        .text-secondary-emphasis[task.completed]
                        .text-decoration-line-through[task.completed]
                        for={ "task-check-" (task.id) } {
                        (task.description)
                    }
                }

                a .btn.btn-primary.btn-sm href={ "/tasks/" (task.id) "/edit" } {
                    "Edit"
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
    completed: bool,
    created_at: DateTime<Utc>,
    updated_at: DateTime<Utc>,
}

#[tracing::instrument(skip(pool))]
async fn list_tasks(pool: &PgPool) -> anyhow::Result<Vec<Task>> {
    Ok(sqlx::query_as!(
        Task,
        r#"
SELECT id, description, completed, created_at, updated_at
FROM tasks
ORDER BY created_at
        "#
    )
    .fetch_all(pool)
    .await?)
}

#[tracing::instrument(skip(pool))]
async fn insert_task(pool: &PgPool, t: NewTaskForm) -> anyhow::Result<Task> {
    Ok(sqlx::query_as!(
        Task,
        r#"
INSERT INTO tasks
(description)
VALUES
($1)
RETURNING *
        "#,
        t.description
    )
    .fetch_one(pool)
    .await?)
}

#[tracing::instrument(skip(pool))]
async fn task_get(pool: &PgPool, id: i64) -> anyhow::Result<Task> {
    Ok(sqlx::query_as!(
        Task,
        r#"
SELECT id, description, completed, created_at, updated_at
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
SET completed = NOT completed
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
SET description = $2
WHERE id = $1
RETURNING *
        "#,
        id,
        t.description
    )
    .fetch_one(pool)
    .await?)
}
