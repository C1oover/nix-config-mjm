mod app;
mod config;
mod deploys;
mod home;
mod tasks;

use axum::response::IntoResponse;
use axum::routing::get;
use axum::{serve, Router};
use clap::{Parser, Subcommand};
use config::Config;
use listenfd::ListenFd;
use opentelemetry::{global, trace::TracerProvider};
use opentelemetry_sdk::runtime;
use tokio::net::TcpListener;
use tower_http::trace::TraceLayer;
use tracing::Level;
use tracing_opentelemetry::OpenTelemetryLayer;
use tracing_subscriber::{layer::SubscriberExt, util::SubscriberInitExt};

#[derive(Parser)]
#[command(name = "launchpad")]
#[command(version, about, long_about = None)]
struct Cli {
    #[command(subcommand)]
    command: Command,
}

#[derive(Subcommand)]
enum Command {
    #[command(about = "Start the HTTP server")]
    Serve,

    #[command(about = "Process outstanding reminders and send notifications")]
    ProcessReminders,
}

#[tokio::main]
async fn main() {
    let cli = Cli::parse();

    let config: Config = Config::figment().extract().unwrap();
    init_tracing(&config);

    match &cli.command {
        Command::Serve => {
            let app_state = app::new_state(config.clone()).await.unwrap();
            sqlx::migrate!().run(&app_state.pool).await.unwrap();

            let app = Router::new()
                .route("/healthz", get(health))
                .merge(home::routes::router())
                .merge(deploys::routes::router())
                .merge(tasks::routes::router())
                .with_state(app_state)
                .layer(TraceLayer::new_for_http());

            let mut listenfd = ListenFd::from_env();
            let listener = match listenfd.take_tcp_listener(0).unwrap() {
                Some(listener) => {
                    listener.set_nonblocking(true).unwrap();
                    TcpListener::from_std(listener).unwrap()
                }
                None => TcpListener::bind(&config.bind_address).await.unwrap(),
            };

            serve(listener, app.into_make_service()).await.unwrap();
        }
        Command::ProcessReminders => {
            let app_state = app::new_state(config.clone()).await.unwrap();

            tasks::Reminder::process_outstanding(&app_state.pool, &config.reminders_topic)
                .await
                .expect("failed to process outstanding reminders");

            global::shutdown_tracer_provider();
        }
    }
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
        .with(OpenTelemetryLayer::new(tracer))
        .with(tracing_subscriber::filter::LevelFilter::from_level(
            Level::DEBUG,
        ));

    if config.enable_pretty_output {
        registry.with(fmt_layer.pretty()).init();
    } else {
        registry.with(fmt_layer).init();
    }
}

async fn health() -> impl IntoResponse {
    "OK"
}
