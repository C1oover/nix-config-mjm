use axum::extract::State;
use axum::response::IntoResponse;
use gitlab::api::common::SortOrder;
use gitlab::api::projects::merge_requests::MergeRequestState;
use gitlab::api::projects::{self, deployments::DeploymentOrderBy};
use gitlab::api::AsyncQuery;
use gitlab::AsyncGitlab;
use maud::html;
use serde::{Deserialize, Serialize};
use tokio::try_join;

use crate::app;

pub async fn index(State(client): State<GitLabClient>) -> Result<impl IntoResponse, app::Error> {
    let (update_mr, deploys) =
        try_join!(client.get_update_merge_request(), client.list_deployments())?;

    Ok(app::layout(
        "Deploys",
        html! {
            h1 { "Deploys" }

            @if let Some(mr) = update_mr {
                p .alert .alert-primary .mt-3 role="alert" {
                    "There is an outstanding update "
                    a href={ "https://git.midna.dev/mjm/nix-config/-/merge_requests/" (mr.iid) } target="_blank" {
                        "merge request"
                    }
                    "."
                }
            }

            ul .list-group {
                @for deploy in &deploys {
                    li .list-group-item {
                        (deploy.deployable.name)
                        " - "
                        (deploy.deployable.commit.message)
                    }
                }
            }
        },
    ))
}

#[derive(Clone, Debug)]
pub struct GitLabClient {
    client: AsyncGitlab,
}

impl GitLabClient {
    pub async fn new<T: Into<String>>(token: T) -> Self {
        let client = gitlab::GitlabBuilder::new("git.midna.dev", token)
            .build_async()
            .await
            .unwrap();
        GitLabClient { client }
    }

    #[tracing::instrument]
    async fn get_update_merge_request(self: &Self) -> anyhow::Result<Option<MergeRequest>> {
        let endpoint = projects::merge_requests::MergeRequests::builder()
            .project("mjm/nix-config")
            .source_branch("npins-update")
            .target_branch("main")
            .state(MergeRequestState::Opened)
            .build()?;

        let mut mrs: Vec<MergeRequest> = endpoint.query_async(&self.client).await?;
        Ok(mrs.pop())
    }

    #[tracing::instrument]
    async fn list_deployments(self: &Self) -> anyhow::Result<Vec<Deployment>> {
        let endpoint = projects::deployments::Deployments::builder()
            .project("mjm/nix-config")
            .order_by(DeploymentOrderBy::CreatedAt)
            .sort(SortOrder::Descending)
            .build()?;

        Ok(endpoint.query_async(&self.client).await?)
    }
}

#[derive(Deserialize, Serialize, Debug)]
struct MergeRequest {
    id: i64,
    iid: i64,
    title: String,
}

#[derive(Deserialize, Serialize, Debug)]
struct Deployment {
    id: i64,
    sha: String,
    // TODO should be an enum
    status: String,
    // TODO created_at/updated_at
    deployable: Job,
}

#[derive(Deserialize, Serialize, Debug)]
struct Job {
    name: String,
    stage: String,
    // TODO should be an enum
    status: String,
    web_url: String,
    // TODO created_at/started_at/finished_at
    commit: Commit,
}

#[derive(Deserialize, Serialize, Debug)]
struct Commit {
    id: String,
    message: String,
}
