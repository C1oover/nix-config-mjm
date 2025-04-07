use axum::{
    extract::{Path, State},
    response::{IntoResponse, Redirect},
    routing::{get, post, put},
    Form, Router,
};
use chrono_tz::Tz;
use maud::{html, PreEscaped};
use serde::Deserialize;
use sqlx::PgPool;
use tokio::try_join;

use crate::{
    app,
    tasks::{routes::partials, split_tags, Reminder, Task, TaskInsertInput, TaskUpdateInput},
};

pub fn router() -> Router<app::State> {
    Router::new()
        .route("/tasks", get(index).post(create))
        .route("/tasks/{id}", put(update).delete(delete))
        .route("/tasks/{id}/edit", get(edit))
        .route("/tasks/{id}/snooze", get(snooze_form).post(snooze))
        .route("/tasks/{id}/toggle", post(toggle))
}

#[tracing::instrument(skip(pool))]
async fn index(
    State(pool): State<PgPool>,
    State(tz): State<Tz>,
) -> Result<impl IntoResponse, app::Error> {
    let (tasks, reminders) = try_join!(Task::list(&pool), Reminder::list(&pool))?;

    Ok(app::layout(
        "Tasks",
        html! {
            h1 { "Tasks" }

            ul #task-list .list-group .mb-2 {
                (partials::task_list(&tasks))
            }

            .d-grid .gap-2 .d-md-block .mb-4 {
                button
                    .btn.btn-primary
                    type="button"
                    data-bs-toggle="modal"
                    data-bs-target="#new-task-modal" {

                    i .bi-plus-circle-fill { }
                    " New task"
                }
            }

            h1 { "Reminders" }

            ul #reminder-list .list-group .mb-2 {
                (partials::reminder_list(&reminders))
            }

            .d-grid .gap-2 .d-md-block {
                button
                    .btn.btn-primary
                    type="button"
                    data-bs-toggle="modal"
                    data-bs-target="#new-reminder-modal" {

                    i .bi-plus-circle-fill { }
                    " New reminder"
                }
            }

            (partials::modal_container("new-task-modal", partials::new_task_modal()))
            (partials::new_reminder_modal(&tz))
        },
    ))
}

#[derive(Deserialize, Debug)]
struct CreateForm {
    description: String,
    tags: String,
}

impl CreateForm {
    fn as_input(self: &Self) -> TaskInsertInput {
        TaskInsertInput {
            description: self.description.clone(),
            tags: split_tags(&self.tags),
            reminder_id: None,
            notify_at: None,
        }
    }
}

#[tracing::instrument(skip(pool))]
async fn create(
    State(pool): State<PgPool>,
    Form(form): Form<CreateForm>,
) -> Result<impl IntoResponse, app::Error> {
    // TODO better error handling/validation
    Task::insert(&pool, &form.as_input()).await?;

    let tasks = Task::list(&pool).await?;

    Ok(html! {
        div hx-swap-oob="innerHTML:#task-list" {
            (partials::task_list(&tasks))
        }
        (partials::hide_modal("new-task-modal"))
        (partials::new_task_modal())
    })
}

#[tracing::instrument(skip(pool))]
async fn edit(
    State(pool): State<PgPool>,
    Path(id): Path<i64>,
) -> Result<impl IntoResponse, app::Error> {
    let task = Task::get(&pool, id).await?;

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

#[derive(Deserialize, Debug)]
struct UpdateForm {
    description: String,
    tags: String,
}

impl UpdateForm {
    fn as_input(self: &Self) -> TaskUpdateInput {
        TaskUpdateInput {
            description: self.description.clone(),
            tags: split_tags(&self.tags),
        }
    }
}

#[tracing::instrument(skip(pool))]
async fn update(
    State(pool): State<PgPool>,
    Path(id): Path<i64>,
    Form(form): Form<UpdateForm>,
) -> Result<impl IntoResponse, app::Error> {
    Task::update(&pool, id, &form.as_input()).await?;

    Ok(Redirect::to("/tasks"))
}

#[tracing::instrument(skip(pool))]
async fn snooze_form(
    State(pool): State<PgPool>,
    Path(id): Path<i64>,
) -> Result<impl IntoResponse, app::Error> {
    let task = Task::get(&pool, id).await?;

    Ok(html! {
        (partials::modal_container("snooze-task-modal", html! {
            .modal-dialog .modal-fullscreen-md-down {
                .modal-content {
                    form hx-post={ "/tasks/" (task.id) "/snooze" } {
                        .modal-header {
                            h1 #snooze-task-modal-title .modal-title .fs-5 {
                                "Snooze task"
                            }
                            button .btn-close type="button" data-bs-dismiss="modal" aria-label="Close" {}
                        }

                        .modal-body {
                            .mb-3 {
                                label .form-label for="snooze-task-minutes" { "Minutes" }
                                input
                                    #snooze-task-minutes
                                    .form-control
                                    name="minutes"
                                    type="number"
                                    value="10"
                                    step="5"
                                    autocomplete="off";
                            }
                        }

                        .modal-footer {
                            button .btn.btn-secondary type="button" data-bs-dismiss="modal" { "Close" }
                            button .btn.btn-primary { "Snooze" }
                        }
                    }
                }
            }
        }))

        script type="text/javascript" {
            (PreEscaped(r##"
                bootstrap.Modal.getOrCreateInstance("#snooze-task-modal").show();
            "##))
        }
    })
}

#[derive(Deserialize, Debug)]
struct SnoozeForm {
    minutes: i64,
}

#[tracing::instrument(skip(pool))]
async fn snooze(
    State(pool): State<PgPool>,
    Path(id): Path<i64>,
    Form(form): Form<SnoozeForm>,
) -> Result<impl IntoResponse, app::Error> {
    let mut conn = pool.acquire().await?;
    Task::snooze(&mut conn, id, form.minutes).await?;

    let tasks = Task::list(&pool).await?;

    Ok(html! {
        div hx-swap-oob="innerHTML:#task-list" {
            (partials::task_list(&tasks))
        }

        (partials::hide_modal("snooze-task-modal"))
        script type="text/javascript" {
            (PreEscaped(r##"
                htmx.remove(htmx.find("#snooze-task-modal"), 1000);
            "##))
        }
    })
}

#[tracing::instrument(skip(pool))]
async fn toggle(
    State(pool): State<PgPool>,
    Path(id): Path<i64>,
) -> Result<impl IntoResponse, app::Error> {
    Task::toggle(&pool, id).await?;
    let (tasks, reminders) = try_join!(Task::list(&pool), Reminder::list(&pool))?;

    Ok(html! {
        (partials::task_list(&tasks))

        div hx-swap-oob="innerHTML:#reminder-list" {
            (partials::reminder_list(&reminders))
        }
    })
}

#[tracing::instrument(skip(pool))]
async fn delete(
    State(pool): State<PgPool>,
    Path(id): Path<i64>,
) -> Result<impl IntoResponse, app::Error> {
    Task::delete(&pool, id).await?;

    Ok(Redirect::to("/tasks"))
}
