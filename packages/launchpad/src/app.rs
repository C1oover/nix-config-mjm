use std::fmt::Display;

use crate::{config::Config, deploys};
use anyhow::Result;
use axum::extract::FromRef;
use axum::http::StatusCode;
use axum::response::{IntoResponse, Response};
use chrono_tz::Tz;
use maud::{html, Markup, DOCTYPE};
use sqlx::PgPool;

#[tracing::instrument(skip(config))]
pub async fn new_state(config: Config) -> Result<State> {
    let gitlab_client = deploys::GitLabClient::new(config.gitlab_token.clone()).await;
    let pool = PgPool::connect(&config.database_url).await?;
    let tz: Tz = config.local_time_zone.parse()?;

    Ok(State {
        config,
        pool,
        gitlab_client,
        local_time_zone: tz,
    })
}

#[derive(Clone, FromRef)]
pub struct State {
    pub config: Config,
    pub pool: PgPool,
    pub gitlab_client: deploys::GitLabClient,
    pub local_time_zone: Tz,
}

pub struct Error(anyhow::Error);

impl<E> From<E> for Error
where
    E: Into<anyhow::Error>,
{
    fn from(value: E) -> Self {
        Self(value.into())
    }
}

impl Display for Error {
    fn fmt(self: &Self, f: &mut std::fmt::Formatter<'_>) -> std::fmt::Result {
        self.0.fmt(f)
    }
}

impl IntoResponse for Error {
    fn into_response(self) -> Response {
        (
            StatusCode::INTERNAL_SERVER_ERROR,
            format!("Something went wrong: {}", self.0),
        )
            .into_response()
    }
}

pub fn layout(title: &str, content: Markup) -> Markup {
    html! {
        (DOCTYPE)
        html data-bs-theme="dark" {
            head {
                title { (title) " - Launchpad" }
                script
                    src="https://unpkg.com/htmx.org@2.0.2/dist/htmx.js"
                    integrity="sha384-yZq+5izaUBKcRgFbxgkRYwpHhHHCpp5nseXp0MEQ1A4MTWVMnqkmcuFez8x5qfxr"
                    crossorigin="anonymous" {}
                link
                    href="https://cdn.jsdelivr.net/npm/bootstrap@5.3.3/dist/css/bootstrap.min.css"
                    rel="stylesheet"
                    integrity="sha384-QWTKZyjpPEjISv5WaRU9OFeRpok6YctnYmDr5pNlyT2bRjXh0JMhjY6hW+ALEwIH"
                    crossorigin="anonymous";
                link
                    rel="stylesheet"
                    href="https://cdn.jsdelivr.net/npm/bootstrap-icons@1.11.3/font/bootstrap-icons.min.css";
                meta charset="utf-8";
                meta name="viewport" content="width=device-width, initial-scale=1";
            }
            body {
                (navbar())
                .container { (content) }
                script
                    src="https://cdn.jsdelivr.net/npm/bootstrap@5.3.3/dist/js/bootstrap.bundle.min.js"
                    integrity="sha384-YvpcrYf0tY3lHB60NNkmXc5s9fDVZLESaAA55NDzOxhy9GkcIdslK1eN7N6jIeHz"
                    crossorigin="anonymous" {}
            }
        }
    }
}

fn navbar() -> Markup {
    html! {
        nav .navbar .navbar-expand-lg .bg-body-tertiary .mb-3 {
            .container-fluid {
                a .navbar-brand href="/" { "Launchpad" }
                button .navbar-toggler
                    type="button"
                    data-bs-toggle="collapse"
                    data-bs-target="#navbar-items"
                    aria-controls="navbar-items"
                    aria-expanded="false"
                    aria-label="Toggle navigation" {
                    span.navbar-toggler-icon {}
                }
                #navbar-items .collapse .navbar-collapse {
                    ul .navbar-nav {
                        li .nav-item {
                            a .nav-link href="/deploys" { "Deploys" }
                        }
                        li .nav-item {
                            a .nav-link href="/backups" { "Backups" }
                        }
                        li .nav-item {
                            a .nav-link href="/tasks" { "Tasks" }
                        }
                    }
                }
            }
        }
    }
}
