pub(crate) mod routes;

use anyhow::Result;
use serde::{Deserialize, Serialize};

#[derive(Serialize, Deserialize, Debug)]
struct Alert {
    #[serde(rename(deserialize = "startsAt"))]
    starts_at: String,
}

#[tracing::instrument(ret, err)]
pub async fn list_alerts() -> Result<Vec<Alert>> {
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
pub async fn count_paperless_inbox_docs(token: &str) -> Result<i32> {
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
