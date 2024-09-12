use crate::{config::Config, deploys};
use anyhow::Result;
use axum::extract::FromRef;
use axum::http::StatusCode;
use axum::response::{IntoResponse, Response};
use sqlx::PgPool;
use tera::Tera;

#[tracing::instrument(skip(config))]
pub async fn new_state(config: Config) -> Result<State> {
    let tera = Tera::new("templates/**/*.html")?;

    let gitlab_client = deploys::GitLabClient::new(config.gitlab_token.clone()).await;

    let pool = PgPool::connect(&config.database_url).await?;

    Ok(State {
        config,
        engine: axum_template::engine::Engine::from(tera),
        pool,
        gitlab_client,
    })
}

pub type Engine = axum_template::engine::Engine<Tera>;

#[derive(Clone, FromRef)]
pub struct State {
    config: Config,
    engine: Engine,
    pool: PgPool,
    gitlab_client: deploys::GitLabClient,
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

impl IntoResponse for Error {
    fn into_response(self) -> Response {
        (
            StatusCode::INTERNAL_SERVER_ERROR,
            format!("Something went wrong: {}", self.0),
        )
            .into_response()
    }
}
