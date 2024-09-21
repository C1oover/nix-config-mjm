use axum::{extract::State, response::IntoResponse, routing::get, Router};
use maud::{html, Markup};
use tokio::try_join;

use crate::{app, config::Config, home};

pub fn router() -> Router<app::State> {
    Router::new()
        .route("/", get(index))
        .route("/status-cards", get(status_cards))
}

#[tracing::instrument(skip(config))]
async fn index(State(config): State<Config>) -> Result<impl IntoResponse, app::Error> {
    let status_cards = load_status_cards(&config).await?;

    Ok(app::layout(
        "Welcome!",
        html! {
            .row .gy-2 hx-get="/status-cards" hx-trigger="every 30s" {
                (render_status_cards(status_cards))
            }
        },
    ))
}

#[tracing::instrument(skip(config))]
async fn status_cards(State(config): State<Config>) -> Result<impl IntoResponse, app::Error> {
    let status_cards = load_status_cards(&config).await?;

    Ok(render_status_cards(status_cards))
}

fn render_status_cards(status_cards: StatusCards) -> Markup {
    html! {
        .col-sm {
            .card {
                .card-body {
                    h5 .card-title { "Alerts firing" }
                    p {
                        (status_cards.num_alerts)
                        " alert"
                        @if status_cards.num_alerts == 1 { "" } @else { "s" }
                    }
                    a .btn .btn-primary href="https://graphs.midna.dev/alerting/list?search=state:firing" {
                        "View firing alerts"
                    }
                }
            }
        }

        .col-sm {
            .card {
                .card-body {
                    h5 .card-title { "Paperless inbox" }
                    p {
                        (status_cards.num_inbox_docs)
                        " document"
                        @if status_cards.num_inbox_docs == 1 { "" } @else { "s" }
                    }
                    a .btn .btn-primary href="https://paper.midna.dev/view/1" {
                        "View inbox documents"
                    }
                }
            }
        }
    }
}

#[derive(Debug)]
struct StatusCards {
    num_alerts: i32,
    num_inbox_docs: i32,
}

#[tracing::instrument(skip(config), ret, err)]
async fn load_status_cards(config: &Config) -> anyhow::Result<StatusCards> {
    let alerts_fut = home::list_alerts();
    let num_inbox_docs_fut = home::count_paperless_inbox_docs(&config.paperless_token);
    try_join!(alerts_fut, num_inbox_docs_fut).map(|(alerts, num_inbox_docs)| StatusCards {
        num_alerts: alerts.len() as i32,
        num_inbox_docs,
    })
}
