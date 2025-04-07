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
use opentelemetry_sdk::trace as sdktrace;
use tokio::net::{TcpListener, UnixListener};
use tower_http::trace::TraceLayer;
use tracing::Level;
use tracing_opentelemetry::OpenTelemetryLayer;
use tracing_subscriber::{prelude::*, EnvFilter};

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
    let tracer_provider = init_tracing(&config);

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
            match listenfd.take_tcp_listener(0) {
                Ok(maybe_listener) => {
                    let tcp_listener = match maybe_listener {
                        Some(listener) => {
                            listener.set_nonblocking(true).unwrap();
                            TcpListener::from_std(listener).unwrap()
                        }
                        None => TcpListener::bind(&config.bind_address).await.unwrap(),
                    };

                    serve(tcp_listener, app.into_make_service()).await.unwrap();
                }
                Err(_) => {
                    let unix_listener =
                        UnixListener::from_std(listenfd.take_unix_listener(0).unwrap().unwrap())
                            .unwrap();
                    serve(unix_listener, app.into_make_service()).await.unwrap();
                }
            };

            tracer_provider.shutdown().unwrap();
        }
        Command::ProcessReminders => {
            let app_state = app::new_state(config.clone()).await.unwrap();

            tasks::Reminder::process_outstanding(&app_state.pool, &config.reminders_topic)
                .await
                .expect("failed to process outstanding reminders");

            tracer_provider.shutdown().unwrap();
        }
    }
}

fn init_tracing(config: &Config) -> sdktrace::SdkTracerProvider {
    let otlp_exporter = opentelemetry_otlp::SpanExporter::builder()
        .with_http()
        .build()
        .unwrap();
    let provider = sdktrace::SdkTracerProvider::builder()
        .with_batch_exporter(otlp_exporter)
        .build();

    let tracer = provider.tracer("launchpad");
    global::set_tracer_provider(provider.clone());

    let fmt_layer = tracing_subscriber::fmt::layer();

    let registry = tracing_subscriber::registry()
        .with(
            OpenTelemetryLayer::new(tracer).with_filter(
                EnvFilter::new("info")
                    .add_directive("hyper=off".parse().unwrap())
                    .add_directive("opentelemetry=off".parse().unwrap())
                    .add_directive("hyper_util=off".parse().unwrap()),
            ),
        )
        .with(tracing_subscriber::filter::LevelFilter::from_level(
            Level::DEBUG,
        ));

    if config.enable_pretty_output {
        registry.with(fmt_layer.pretty()).init();
    } else {
        registry.with(fmt_layer).init();
    }

    provider
}

async fn health() -> impl IntoResponse {
    "OK"
}
