mod partials;
mod reminders;
mod tasks;

use axum::Router;

use crate::app;

pub fn router() -> Router<app::State> {
    Router::new()
        .merge(tasks::router())
        .merge(reminders::router())
}
