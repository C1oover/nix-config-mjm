pub(crate) mod routes;

use anyhow::Result;
use chrono::{DateTime, Utc};
use gitlab::api::common::SortOrder;
use gitlab::api::projects::merge_requests::MergeRequestState;
use gitlab::api::projects::{self, deployments::DeploymentOrderBy};
use gitlab::api::AsyncQuery;
use gitlab::AsyncGitlab;
use serde::{Deserialize, Serialize};

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

    #[tracing::instrument(skip(self))]
    pub async fn get_update_merge_request(self: &Self) -> Result<Option<MergeRequest>> {
        let endpoint = projects::merge_requests::MergeRequests::builder()
            .project("mjm/nix-config")
            .source_branch("npins-update")
            .target_branch("main")
            .state(MergeRequestState::Opened)
            .build()?;

        let mut mrs: Vec<MergeRequest> = endpoint.query_async(&self.client).await?;
        Ok(mrs.pop())
    }

    #[tracing::instrument(skip(self), ret)]
    pub async fn list_deployments(self: &Self) -> Result<Vec<Deployment>> {
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
    status: DeploymentStatus,
    created_at: DateTime<Utc>,
    updated_at: DateTime<Utc>,
    deployable: Job,
}

impl Deployment {
    fn is_failed(self: &Self) -> bool {
        match self.status {
            DeploymentStatus::Failed | DeploymentStatus::Canceled => true,
            _ => false,
        }
    }

    fn is_blocked(self: &Self) -> bool {
        self.status == DeploymentStatus::Blocked
    }
}

#[derive(Deserialize, Serialize, Debug, PartialEq, Eq)]
#[serde(rename_all = "snake_case")]
enum DeploymentStatus {
    Success,
    Running,
    Failed,
    Canceled,
    Skipped,
    Created,
    Blocked,
    #[serde(other)]
    Unknown,
}

#[derive(Deserialize, Serialize, Debug)]
struct Job {
    name: String,
    stage: String,
    status: JobStatus,
    web_url: String,
    created_at: DateTime<Utc>,
    started_at: Option<DateTime<Utc>>,
    finished_at: Option<DateTime<Utc>>,
    commit: Commit,
}

impl Job {
    fn friendly_name(self: &Self) -> String {
        match self.name.as_str() {
            "deploy nixos hosts" => "NixOS".to_string(),
            "apply terranix changes" => "Infra".to_string(),
            name => name.to_string(),
        }
    }
}

#[derive(Serialize, Deserialize, Debug)]
#[serde(rename_all = "snake_case")]
enum JobStatus {
    Created,
    Pending,
    Running,
    Failed,
    Success,
    Canceled,
    Skipped,
    WaitingForResource,
    Manual,
    #[serde(other)]
    Unknown,
}

#[derive(Deserialize, Serialize, Debug)]
struct Commit {
    id: String,
    message: String,
}

impl Commit {
    fn split_message(self: &Self) -> (String, Option<String>) {
        match self.message.bytes().position(|c| c == b'\n') {
            None => (self.message.clone(), None),
            Some(idx) => {
                let (first, rest) = self.message.split_at(idx);
                // it's possible for the trimmed last component to be an empty string,
                // which should probably be None rather than Some("")
                (first.to_string(), Some(rest.trim().to_string()))
            }
        }
    }
}
