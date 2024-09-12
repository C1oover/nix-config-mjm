mod app;
mod config;
mod deploys;
mod tasks;

use axum::extract::State;
use axum::response::IntoResponse;
use axum::routing::{get, post};
use axum::{serve, Router};
use axum_template::RenderHtml;
use config::Config;
use serde::{Deserialize, Serialize};
use tokio::net::TcpListener;
use tokio::try_join;
use tower_http::trace::TraceLayer;
use tracing::Level;
use tracing_subscriber::FmtSubscriber;

#[derive(Deserialize, Serialize)]
struct IndexContext {
    status_cards: StatusCardsContext,
}

async fn index(
    engine: app::Engine,
    State(config): State<Config>,
) -> Result<impl IntoResponse, app::Error> {
    let status_cards = load_status_cards_context(&config).await?;

    Ok(RenderHtml(
        "index.html",
        engine,
        IndexContext { status_cards },
    ))
}

async fn status_cards(
    engine: app::Engine,
    State(config): State<Config>,
) -> Result<impl IntoResponse, app::Error> {
    let status_cards = load_status_cards_context(&config).await?;

    Ok(RenderHtml(
        "status-cards.html",
        engine,
        IndexContext { status_cards },
    ))
}

async fn load_status_cards_context(config: &Config) -> anyhow::Result<StatusCardsContext> {
    let alerts_fut = list_alerts();
    let num_inbox_docs_fut = count_paperless_inbox_docs(&config.paperless_token);
    try_join!(alerts_fut, num_inbox_docs_fut).map(|(alerts, num_inbox_docs)| StatusCardsContext {
        num_alerts: alerts.len() as i32,
        num_inbox_docs,
    })
}

#[tokio::main]
async fn main() {
    let subscriber = FmtSubscriber::builder()
        .with_max_level(Level::TRACE)
        .finish();

    tracing::subscriber::set_global_default(subscriber).unwrap();

    let config: Config = Config::figment().extract().unwrap();

    let app_state = app::new_state(config.clone()).await.unwrap();
    let app = Router::new()
        .route("/", get(index))
        .route("/status-cards", get(status_cards))
        .route("/deploys", get(deploys::index))
        .route("/tasks", get(tasks::index).post(tasks::create_task))
        .route("/tasks/:id/toggle", post(tasks::toggle_task))
        .with_state(app_state)
        .layer(TraceLayer::new_for_http());

    let listener = TcpListener::bind(&config.bind_address).await.unwrap();
    serve(listener, app.into_make_service()).await.unwrap();
}

#[derive(Serialize, Deserialize, Debug)]
struct Alert {
    #[serde(rename(deserialize = "startsAt"))]
    starts_at: String,
}

#[derive(Deserialize, Serialize)]
struct StatusCardsContext {
    num_alerts: i32,
    num_inbox_docs: i32,
}

#[tracing::instrument(ret, err)]
async fn list_alerts() -> anyhow::Result<Vec<Alert>> {
    let client = reqwest::Client::new();
    let alerts = client
        .get("http://alertmanager.service.consul:9093/api/v2/alerts")
        .query(&[("silenced", "false")])
        .send()
        .await?
        .json()
        .await?;

    Ok(alerts)
}

#[tracing::instrument(skip(token), ret, err)]
async fn count_paperless_inbox_docs(token: &str) -> anyhow::Result<i32> {
    let client = reqwest::Client::new();

    let token_header = format!("Token {token}");

    #[derive(Deserialize)]
    struct DocsResponse {
        count: i32,
    }

    let resp = client
        .get("http://paperless.service.consul:28981/api/documents/")
        .query(&[("tags__name__iexact", "inbox")])
        .header("authorization", token_header)
        .send()
        .await?
        .json::<DocsResponse>()
        .await?;

    Ok(resp.count)
}
