pub(crate) mod routes;

use anyhow::Result;
use chrono::{DateTime, Utc};
use gitlab::api::common::SortOrder;
use gitlab::api::projects::merge_requests::MergeRequestState;
use gitlab::api::projects::{self, deployments::DeploymentOrderBy};
use gitlab::api::{raw, AsyncQuery};
use gitlab::AsyncGitlab;
use serde::{Deserialize, Serialize};

const GITLAB_PROJECT: &str = "mjm/nix-config";

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
            .project(GITLAB_PROJECT)
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
            .project(GITLAB_PROJECT)
            .order_by(DeploymentOrderBy::CreatedAt)
            .sort(SortOrder::Descending)
            .build()?;

        Ok(endpoint.query_async(&self.client).await?)
    }

    #[tracing::instrument(skip(self), ret)]
    pub async fn get_hosts_file(self: &Self) -> Result<String> {
        let endpoint = projects::repository::files::FileRaw::builder()
            .project(GITLAB_PROJECT)
            .file_path("services/dns-server/hosts.json")
            .build()?;

        Ok(String::from_utf8(
            raw(endpoint).query_async(&self.client).await?,
        )?)
    }

    #[tracing::instrument(skip(self))]
    pub async fn update_hosts_file(self: &Self, content: &str) -> Result<()> {
        let endpoint = projects::repository::files::UpdateFile::builder()
            .project(GITLAB_PROJECT)
            .file_path("services/dns-server/hosts.json")
            .content(content.as_bytes())
            .branch("main")
            .commit_message("dns-server: update host records")
            .author_name("Homelab Automation")
            .author_email("homelab@matt.mattmoriarity.com")
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
