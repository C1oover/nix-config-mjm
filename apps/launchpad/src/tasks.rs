use axum::{
    extract::{Path, State},
    response::IntoResponse,
    Form,
};
use axum_template::RenderHtml;
use chrono::{DateTime, Utc};
use serde::{Deserialize, Serialize};
use sqlx::PgPool;

use crate::app;

#[derive(Serialize)]
struct IndexContext {
    tasks: Vec<Task>,
}

pub async fn index(
    engine: app::Engine,
    State(pool): State<PgPool>,
) -> Result<impl IntoResponse, app::Error> {
    let tasks = list_tasks(&pool).await?;
    Ok(RenderHtml(
        "tasks/index.html",
        engine,
        IndexContext { tasks },
    ))
}

#[derive(Deserialize, Debug)]
pub struct NewTaskForm {
    description: String,
}

#[derive(Serialize)]
struct CreateTaskContext {
    tasks: Vec<Task>,
}

#[tracing::instrument(skip(engine, pool))]
pub async fn create_task(
    engine: app::Engine,
    State(pool): State<PgPool>,
    Form(form): Form<NewTaskForm>,
) -> Result<impl IntoResponse, app::Error> {
    // TODO better error handling/validation
    insert_task(&pool, form).await?;

    let tasks = list_tasks(&pool).await?;

    Ok(RenderHtml(
        "tasks/create-task.html",
        engine,
        CreateTaskContext { tasks },
    ))
}

#[derive(Serialize)]
struct ToggleTaskContext {
    tasks: Vec<Task>,
}

pub async fn toggle_task(
    engine: app::Engine,
    State(pool): State<PgPool>,
    Path(id): Path<i64>,
) -> Result<impl IntoResponse, app::Error> {
    task_toggle(&pool, id).await?;

    let tasks = list_tasks(&pool).await?;

    Ok(RenderHtml(
        "tasks/toggle-task.html",
        engine,
        ToggleTaskContext { tasks },
    ))
}

#[derive(Serialize)]
struct Task {
    id: i64,
    description: String,
    completed: bool,
    created_at: DateTime<Utc>,
    updated_at: DateTime<Utc>,
}

#[tracing::instrument(skip(pool))]
async fn list_tasks(pool: &PgPool) -> anyhow::Result<Vec<Task>> {
    Ok(sqlx::query_as!(
        Task,
        r#"
SELECT id, description, completed, created_at, updated_at
FROM tasks
ORDER BY created_at
        "#
    )
    .fetch_all(pool)
    .await?)
}

#[tracing::instrument(skip(pool))]
async fn insert_task(pool: &PgPool, t: NewTaskForm) -> anyhow::Result<Task> {
    Ok(sqlx::query_as!(
        Task,
        r#"
INSERT INTO tasks
(description)
VALUES
($1)
RETURNING *
        "#,
        t.description
    )
    .fetch_one(pool)
    .await?)
}

#[tracing::instrument(skip(pool))]
async fn task_toggle(pool: &PgPool, id: i64) -> anyhow::Result<Task> {
    Ok(sqlx::query_as!(
        Task,
        r#"
UPDATE tasks
SET completed = NOT completed
WHERE id = $1
RETURNING *
        "#,
        id
    )
    .fetch_one(pool)
    .await?)
}
