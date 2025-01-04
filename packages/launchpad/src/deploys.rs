pub(crate) mod routes;

use anyhow::Result;
use chrono::{DateTime, Utc};
use futures::future::try_join_all;
use gitlab::api::common::SortOrder;
use gitlab::api::projects::repository::commits;
use gitlab::api::projects::{self, deployments::DeploymentOrderBy};
use gitlab::api::projects::{merge_requests, pipelines};
use gitlab::api::AsyncQuery;
use gitlab::AsyncGitlab;
use serde::{Deserialize, Serialize};
use tokio::try_join;

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
        mr.head_pipeline = self.load_pipeline_jobs(mr.head_pipeline).await?;
        Ok(mr)
    }

    #[tracing::instrument(skip(self), ret, err)]
    pub async fn list_deployment_pipelines(self: &Self) -> Result<Vec<AnnotatedPipeline>> {
        let endpoint = pipelines::Pipelines::builder()
            .project(GITLAB_PROJECT)
            .source(pipelines::PipelineSource::Push)
            .ref_("main")
            .build()?;

        let pipelines: Vec<Pipeline> = endpoint.query_async(&self.client).await?;

        Ok(try_join_all(
            pipelines
                .into_iter()
                .map(|pipeline| self.annotate_pipeline(pipeline)),
        )
        .await?)
    }

    async fn annotate_pipeline(self: &Self, pipeline: Pipeline) -> Result<AnnotatedPipeline> {
        let sha = pipeline.sha.clone();
        let (commit, merge_request, pipeline) = try_join!(
            self.get_commit_details(&sha),
            self.get_commit_merge_request(&sha),
            self.load_pipeline_jobs(pipeline)
        )?;

        Ok(AnnotatedPipeline {
            pipeline,
            commit,
            merge_request,
        })
    }

    #[tracing::instrument(skip(self), ret, err)]
    async fn get_commit_details(self: &Self, sha: &str) -> Result<Commit> {
        let endpoint = commits::Commit::builder()
            .project(GITLAB_PROJECT)
            .commit(sha)
            .build()?;

        Ok(endpoint.query_async(&self.client).await?)
    }

    #[tracing::instrument(skip(self), ret, err)]
    async fn get_commit_merge_request(self: &Self, sha: &str) -> Result<Option<MergeRequestBasic>> {
        let endpoint = commits::MergeRequests::builder()
            .project(GITLAB_PROJECT)
            .sha(sha)
            .build()?;

        let mut mrs: Vec<_> = endpoint.query_async(&self.client).await?;
        Ok(mrs.pop())
    }

    #[tracing::instrument(skip(self), ret, err)]
    async fn load_pipeline_jobs(self: &Self, mut pipeline: Pipeline) -> Result<Pipeline> {
        let endpoint = pipelines::PipelineJobs::builder()
            .project(GITLAB_PROJECT)
            .pipeline(pipeline.id)
            .build()?;

        pipeline.jobs = endpoint.query_async(&self.client).await?;
        Ok(pipeline)
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
}

#[derive(Deserialize, Debug)]
struct MergeRequestSimple {
    iid: u64,
}

#[derive(Deserialize, Debug, PartialEq, Eq)]
struct MergeRequestBasic {
    id: u64,
    iid: u64,
    title: String,
    state: MergeRequestState,
    web_url: String,
    created_at: DateTime<Utc>,
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
    sha: String,
    web_url: String,
    created_at: DateTime<Utc>,
    #[serde(skip)]
    jobs: Vec<Job>,
}

#[derive(Debug)]
struct AnnotatedPipeline {
    pipeline: Pipeline,
    commit: Commit,
    merge_request: Option<MergeRequestBasic>,
}

impl AnnotatedPipeline {
    fn title(self: &Self) -> String {
        match &self.merge_request {
            Some(mr) => mr.title.clone(),
            None => self.commit.title.clone(),
        }
    }
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
    title: String,
    message: String,
}
