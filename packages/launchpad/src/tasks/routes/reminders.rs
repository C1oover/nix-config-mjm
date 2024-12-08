use axum::{
    extract::{Path, State},
    response::{IntoResponse, Redirect},
    routing::{get, post, put},
    Form, Router,
};
use chrono::{NaiveDateTime, Utc};
use chrono_tz::Tz;
use maud::html;
use serde::Deserialize;
use serde_with::serde_as;
use sqlx::PgPool;

use crate::{
    app,
    tasks::{
        routes::partials, split_tags, Reminder, ReminderInsertInput, ReminderUpdateInput,
        RepeatInterval,
    },
};

pub fn router() -> Router<app::State> {
    Router::new()
        .route("/reminders", post(create))
        .route("/reminders/:id", put(update).delete(delete))
        .route("/reminders/:id/edit", get(edit))
}

#[serde_as]
#[derive(Deserialize, Debug)]
struct CreateForm {
    description: String,
    tags: String,
    remind_at: String,
    snooze_minutes: i64,
    #[serde_as(as = "serde_with::NoneAsEmptyString")]
    repeat_days: Option<i32>,
    #[serde_as(as = "serde_with::NoneAsEmptyString")]
    repeat_weeks: Option<i32>,
    #[serde_as(as = "serde_with::NoneAsEmptyString")]
    repeat_months: Option<i32>,
}

impl CreateForm {
    fn as_input(self: &Self, tz: Tz) -> anyhow::Result<ReminderInsertInput> {
        let tags = split_tags(&self.tags);
        let remind_at = NaiveDateTime::parse_from_str(&self.remind_at, "%Y-%m-%dT%H:%M")?
            .and_local_timezone(tz)
            .unwrap()
            .with_timezone(&Utc);

        Ok(ReminderInsertInput {
            description: self.description.clone(),
            tags,
            remind_at,
            snooze_minutes: self.snooze_minutes,
            repeat_interval: RepeatInterval::new(
                self.repeat_days,
                self.repeat_weeks,
                self.repeat_months,
            ),
        })
    }
}

#[tracing::instrument(skip(pool, tz))]
async fn create(
    State(pool): State<PgPool>,
    State(tz): State<Tz>,
    Form(form): Form<CreateForm>,
) -> Result<impl IntoResponse, app::Error> {
    Reminder::insert(&pool, &form.as_input(tz)?).await?;

    let reminders = Reminder::list(&pool).await?;

    Ok(html! {
        div hx-swap-oob="innerHTML:#reminder-list" {
            (partials::reminder_list(&reminders))
        }
        (partials::hide_modal("new-reminder-modal"))
        (partials::new_reminder_modal(&tz))
    })
}

#[tracing::instrument(skip(pool, tz))]
async fn edit(
    State(pool): State<PgPool>,
    State(tz): State<Tz>,
    Path(id): Path<i64>,
) -> Result<impl IntoResponse, app::Error> {
    let reminder = Reminder::get(&pool, id).await?;
    let remind_at = reminder
        .remind_at
        .with_timezone(&tz)
        .format("%Y-%m-%dT%H:%M");

    Ok(app::layout(
        "Edit reminder",
        html! {
            h1 { "Edit reminder" }

            form
                hx-put={ "/reminders/" (reminder.id) }
                hx-push-url="/tasks"
                hx-swap="outerHTML"
                hx-target="body" {

                .mb-3 {
                    label .form-label for="edit-reminder-description" { "Description" }
                    input
                        #edit-reminder-description
                        .form-control
                        name="description"
                        type="text"
                        value=(reminder.description)
                        autocomplete="off";
                }

                .mb-3 {
                    label .form-label for="edit-reminder-tags" { "Tags" }
                    input
                        #edit-reminder-tags
                        .form-control
                        name="tags"
                        type="text"
                        value=(reminder.tags_string())
                        autocomplete="off";
                }

                .mb-3 {
                    label .form-label for="edit-reminder-remind-at" { "Remind at" }
                    input
                        #edit-reminder-remind-at
                        .form-control
                        name="remind_at"
                        type="datetime-local"
                        value=(remind_at)
                        autocomplete="off";
                }

                .mb-3 {
                    label .form-label for="edit-reminder-snooze-minutes" { "Snooze minutes" }
                    input
                        #edit-reminder-snooze-minutes
                        .form-control
                        name="snooze_minutes"
                        type="number"
                        value=(reminder.snooze_minutes)
                        autocomplete="off";
                }

                .mb-3 {
                    label .form-label for="edit-reminder-repeat-days" { "Repeat every" }

                    .row {
                        .col-sm .mb-2 {
                            .input-group {
                                input
                                    #edit-reminder-repeat-days
                                    .form-control
                                    name="repeat_days"
                                    type="number"
                                    value=(match &reminder.repeat_interval {
                                        Some(ri) => if ri.days == 0 { "".to_string() } else { ri.days.to_string() },
                                        None => "".to_string()
                                    })
                                    autocomplete="off";

                                span .input-group-text { "days" }
                            }
                        }

                        .col-sm .mb-2 {
                            .input-group {
                                input
                                    #edit-reminder-repeat-weeks
                                    .form-control
                                    name="repeat_weeks"
                                    type="number"
                                    value=(match &reminder.repeat_interval {
                                        Some(ri) => if ri.weeks == 0 { "".to_string() } else { ri.weeks.to_string() },
                                        None => "".to_string()
                                    })
                                    autocomplete="off";

                                span .input-group-text { "weeks" }
                            }
                        }

                        .col-sm .mb-2 {
                            .input-group {
                                input
                                    #edit-reminder-repeat-months
                                    .form-control
                                    name="repeat_months"
                                    type="number"
                                    value=(match &reminder.repeat_interval {
                                        Some(ri) => if ri.months == 0 { "".to_string() } else { ri.months.to_string() },
                                        None => "".to_string()
                                    })
                                    autocomplete="off";

                                span .input-group-text { "months" }
                            }
                        }
                    }
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
                        hx-delete={ "/reminders/" (reminder.id) }
                        hx-confirm="Are you sure you want to delete this reminder?" {
                        "Delete"
                    }
                }
            }
        },
    ))
}

#[serde_as]
#[derive(Deserialize, Debug)]
struct UpdateForm {
    description: String,
    tags: String,
    remind_at: String,
    snooze_minutes: i64,
    #[serde_as(as = "serde_with::NoneAsEmptyString")]
    #[serde(default)]
    repeat_days: Option<i32>,
    #[serde_as(as = "serde_with::NoneAsEmptyString")]
    #[serde(default)]
    repeat_weeks: Option<i32>,
    #[serde_as(as = "serde_with::NoneAsEmptyString")]
    #[serde(default)]
    repeat_months: Option<i32>,
}

impl UpdateForm {
    fn as_input(self: &Self, tz: Tz) -> anyhow::Result<ReminderUpdateInput> {
        let remind_at = NaiveDateTime::parse_from_str(&self.remind_at, "%Y-%m-%dT%H:%M")?
            .and_local_timezone(tz)
            .unwrap()
            .with_timezone(&Utc);

        Ok(ReminderUpdateInput {
            description: self.description.clone(),
            tags: split_tags(&self.tags),
            remind_at,
            snooze_minutes: self.snooze_minutes,
            repeat_interval: RepeatInterval::new(
                self.repeat_days,
                self.repeat_weeks,
                self.repeat_months,
            ),
        })
    }
}

#[tracing::instrument(skip(pool, tz), err)]
async fn update(
    State(pool): State<PgPool>,
    State(tz): State<Tz>,
    Path(id): Path<i64>,
    Form(form): Form<UpdateForm>,
) -> Result<impl IntoResponse, app::Error> {
    let mut conn = pool.acquire().await?;
    Reminder::update(&mut conn, id, &form.as_input(tz)?).await?;

    Ok(Redirect::to("/tasks"))
}

#[tracing::instrument(skip(pool), err)]
async fn delete(
    State(pool): State<PgPool>,
    Path(id): Path<i64>,
) -> Result<impl IntoResponse, app::Error> {
    let mut conn = pool.acquire().await?;
    Reminder::delete(&mut conn, id).await?;

    Ok(Redirect::to("/tasks"))
}
