pub(crate) mod routes;

use anyhow::Result;
use chrono::{DateTime, Utc};
use futures::future::try_join_all;
use gitlab::api::common::SortOrder;
use gitlab::api::projects::{self, deployments::DeploymentOrderBy};
use gitlab::api::projects::{merge_requests, pipelines};
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

    #[tracing::instrument(skip(self), ret, err)]
    pub async fn list_open_merge_requests(self: &Self) -> Result<Vec<MergeRequest>> {
        let endpoint = merge_requests::MergeRequests::builder()
            .project(GITLAB_PROJECT)
            .target_branch("main")
            .state(merge_requests::MergeRequestState::Opened)
            .view(merge_requests::MergeRequestView::Simple)
            .build()?;

        let simple_mrs: Vec<MergeRequestSimple> = endpoint.query_async(&self.client).await?;

        Ok(try_join_all(simple_mrs.iter().map(|mr| self.get_merge_request(mr.iid))).await?)
    }

    #[tracing::instrument(skip(self), ret, err)]
    async fn get_merge_request(self: &Self, iid: u64) -> Result<MergeRequest> {
        let endpoint = merge_requests::MergeRequest::builder()
            .project(GITLAB_PROJECT)
            .merge_request(iid)
            .build()?;

        let mut mr: MergeRequest = endpoint.query_async(&self.client).await?;

        let jobs_endpoint = pipelines::PipelineJobs::builder()
            .project(GITLAB_PROJECT)
            .pipeline(mr.head_pipeline.id)
            .build()?;

        mr.head_pipeline.jobs = jobs_endpoint.query_async(&self.client).await?;

        Ok(mr)
    }

    #[tracing::instrument(skip(self), ret, err)]
    pub async fn list_deployments(self: &Self) -> Result<Vec<Deployment>> {
        let endpoint = projects::deployments::Deployments::builder()
            .project(GITLAB_PROJECT)
            .order_by(DeploymentOrderBy::CreatedAt)
            .sort(SortOrder::Descending)
            .build()?;

        Ok(endpoint.query_async(&self.client).await?)
    }

    #[tracing::instrument(skip(self), ret, err)]
    pub async fn get_hosts_file(self: &Self) -> Result<String> {
        let endpoint = projects::repository::files::FileRaw::builder()
            .project(GITLAB_PROJECT)
            .file_path("services/dns-server/hosts.json")
            .build()?;

        Ok(String::from_utf8(
            raw(endpoint).query_async(&self.client).await?,
        )?)
    }

    #[tracing::instrument(skip(self), err)]
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

#[derive(Deserialize, Debug)]
struct MergeRequestSimple {
    iid: u64,
}

#[derive(Deserialize, Serialize, Debug)]
struct MergeRequest {
    id: i64,
    iid: i64,
    title: String,
    state: MergeRequestState,
    web_url: String,
    created_at: DateTime<Utc>,
    head_pipeline: Pipeline,
}

#[derive(Deserialize, Serialize, Debug, PartialEq, Eq)]
#[serde(rename_all = "snake_case")]
enum MergeRequestState {
    Opened,
    Closed,
    Locked,
    Merged,
}

#[derive(Deserialize, Serialize, Debug, PartialEq, Eq)]
struct Pipeline {
    id: u64,
    iid: u64,
    #[serde(skip)]
    jobs: Vec<Job>,
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

#[derive(Deserialize, Serialize, Debug, PartialEq, Eq)]
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
            "build nixos hosts" => "NixOS".to_string(),
            "apply terranix changes" => "Infra".to_string(),
            "build tofu changes" => "Infra".to_string(),
            name => name.to_string(),
        }
    }
}

#[derive(Serialize, Deserialize, Debug, PartialEq, Eq)]
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

#[derive(Deserialize, Serialize, Debug, PartialEq, Eq)]
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
