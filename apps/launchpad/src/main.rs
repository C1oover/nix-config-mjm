mod app;
mod config;
mod deploys;
mod home;
mod tasks;

use axum::response::IntoResponse;
use axum::routing::get;
use axum::{serve, Router};
use config::Config;
use opentelemetry::{global, trace::TracerProvider};
use opentelemetry_sdk::runtime;
use tokio::net::TcpListener;
use tower_http::trace::TraceLayer;
use tracing::Level;
use tracing_opentelemetry::OpenTelemetryLayer;
use tracing_subscriber::{layer::SubscriberExt, util::SubscriberInitExt};

#[tokio::main]
async fn main() {
    let config: Config = Config::figment().extract().unwrap();
    init_tracing(&config);

    let app_state = app::new_state(config.clone()).await.unwrap();
    sqlx::migrate!().run(&app_state.pool).await.unwrap();

    let app = Router::new()
        .route("/healthz", get(health))
        .merge(home::routes::router())
        .merge(deploys::routes::router())
        .merge(tasks::routes::router())
        .with_state(app_state)
        .layer(TraceLayer::new_for_http());

    let listener = TcpListener::bind(&config.bind_address).await.unwrap();
    serve(listener, app.into_make_service()).await.unwrap();
}

fn init_tracing(config: &Config) {
    let otlp_exporter = opentelemetry_otlp::new_exporter().tonic();
    let provider = opentelemetry_otlp::new_pipeline()
        .tracing()
        .with_exporter(otlp_exporter)
        .install_batch(runtime::Tokio)
        .unwrap();

    global::set_tracer_provider(provider.clone());
    let tracer = provider.tracer("launchpad");

    let fmt_layer = tracing_subscriber::fmt::layer();

    let registry = tracing_subscriber::registry()
        .with(tracing_subscriber::filter::LevelFilter::from_level(
            Level::DEBUG,
        ))
        .with(OpenTelemetryLayer::new(tracer));

    if config.enable_pretty_output {
        registry.with(fmt_layer.pretty()).init();
    } else {
        registry.with(fmt_layer).init();
    }
}

async fn health() -> impl IntoResponse {
    "OK"
}
