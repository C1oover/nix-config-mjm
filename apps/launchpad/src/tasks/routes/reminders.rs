use axum::{extract::State, response::IntoResponse, routing::post, Form, Router};
use chrono::{NaiveDateTime, Utc};
use chrono_tz::Tz;
use maud::{html, PreEscaped};
use serde::Deserialize;
use sqlx::PgPool;

use crate::{
    app,
    tasks::{routes::partials, split_tags, Reminder, ReminderInsertInput},
};

pub fn router() -> Router<app::State> {
    Router::new().route("/reminders", post(create))
}

#[derive(Deserialize, Debug)]
struct CreateForm {
    description: String,
    tags: String,
    remind_at: String,
    snooze_minutes: i64,
    repeat_interval: String,
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
            // TODO
            repeat_interval: None,
        })
    }
}

#[tracing::instrument(skip(pool))]
async fn create(
    State(pool): State<PgPool>,
    State(tz): State<Tz>,
    Form(form): Form<CreateForm>,
) -> Result<impl IntoResponse, app::Error> {
    Reminder::insert(&pool, &form.as_input(tz)?).await?;

    let reminders = Reminder::list(&pool).await?;

    Ok(html! {
        (partials::reminder_list(&reminders))

        script type="text/javascript" {
            (PreEscaped(r##"
                bootstrap.Modal.getInstance("#new-reminder-modal").hide();
            "##))
        }

        div hx-swap-oob="innerHTML:#new-reminder-modal" {
            (partials::new_reminder_modal())
        }
    })
}
