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
            .row .gy-2 .mb-4 hx-get="/status-cards" hx-trigger="every 30s" {
                (render_status_cards(status_cards))
            }

            .row .gy-2 {
                (render_app_links())
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

fn render_app_links() -> Markup {
    html! {
        .col-sm {
            .list-group {
                (app_link("Consul", "boxes", "https://consul.midna.dev/"))
                (app_link("Vault", "safe-fill", "https://vault.midna.dev/"))
                (app_link("Proxmox", "motherboard-fill", "https://proxmox.midna.dev/"))
                (app_link("GitLab", "code-slash", "https://git.midna.dev/"))
                (app_link("NetBox", "diagram-3-fill", "https://netbox.midna.dev/"))
            }
        }

        .col-sm {
            .list-group {
                (app_link("Grafana", "graph-up", "https://graphs.midna.dev/"))
                (app_link("Prometheus", "rulers", "https://metrics.midna.dev/"))
            }
        }

        .col-sm {
            .list-group {
                (app_link("Linkding", "bookmarks-fill", "https://links.midna.dev/"))
                (app_link("Miniflux", "newspaper", "https://feeds.midna.dev/"))
                (app_link("Vaultwarden", "lock-fill", "https://pass.midna.dev/"))
                (app_link("Home Assistant", "house-gear-fill", "https://home.midna.dev/"))
                (app_link("Music Assistant", "music-note-list", "https://tunes.midna.dev/"))
                (app_link("Jellyfin", "film", "https://media.midna.dev/"))
                (app_link("Peertube", "camera-reels-fill", "https://tube.midna.dev/"))
                (app_link("Invidious", "collection-play-fill", "https://yt.midna.dev/"))
            }
        }
    }
}

fn app_link(name: &str, icon: &str, href: &str) -> Markup {
    html! {
        a
            .list-group-item
            .list-group-item-action
            href=(href)
            target="_blank" {

            i .me-2 .{ "bi-" (icon) } {}
            " "
            (name)
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
