use axum::{extract::State, response::IntoResponse, routing::get, Router};
use chrono_humanize::{Accuracy, HumanTime, Tense};
use maud::{html, Markup};
use tokio::try_join;

use crate::{app, deploys::JobStatus};

use super::{AnnotatedPipeline, GitLabClient, Job, MergeRequest};

pub fn router() -> Router<app::State> {
    Router::new().route("/deploys", get(index))
}

#[tracing::instrument(skip(client))]
async fn index(State(client): State<GitLabClient>) -> Result<impl IntoResponse, app::Error> {
    let (mrs, deploys) = try_join!(
        client.list_open_merge_requests(),
        client.list_deployment_pipelines()
    )?;

    Ok(app::layout(
        "Deploys",
        html! {
            h1 .mb-4 { "Deploys" }

            @if !mrs.is_empty() {
                h2 .mb-3 { "Open merge requests"}

                ul .list-group .mb-4 {
                    @for mr in &mrs {
                        (merge_request_row(&mr))
                    }
                }
            }

            h2 .mb-3 { "Recent deployments" }

            ul .list-group {
                @for deploy in &deploys {
                    (deployment_row(deploy))
                }
            }
        },
    ))
}

fn merge_request_row(mr: &MergeRequest) -> Markup {
    html! {
        li
            .list-group-item {

            a
                href=(mr.web_url)
                target="_blank"
                .text-decoration-none
                .text-reset {

                div .d-flex .w-100 .justify-content-between {
                    h5 { (mr.title) }
                    small {
                        "opened "
                        (HumanTime::from(mr.created_at).to_text_en(Accuracy::Rough, Tense::Past))
                    }
                }

                (pipeline_jobs_list(&mr.head_pipeline.jobs))
            }
        }
    }
}

fn deployment_row(deploy: &AnnotatedPipeline) -> Markup {
    html! {
        li
            .list-group-item {

            a
                href=(deploy.pipeline.web_url)
                target="_blank"
                .text-decoration-none
                .text-reset {

                div .d-flex .w-100 .justify-content-between {
                    h5 {
                        @if deploy.merge_request.is_some() {
                            i .bi-sign-merge-right {}
                        } @else {
                            i .bi-file-earmark-diff {}
                        }
                        " "
                        (deploy.title())
                    }
                    small {
                        (HumanTime::from(deploy.pipeline.created_at).to_text_en(Accuracy::Rough, Tense::Past))
                    }
                }

                (pipeline_jobs_list(&deploy.pipeline.jobs))
            }
        }
    }
}

fn pipeline_jobs_list(jobs: &[Job]) -> Markup {
    html! {
        ul .list-unstyled {
            @for job in jobs {
                li {
                    a
                        href=(job.web_url)
                        target="_blank"
                        .text-decoration-none
                        .text-reset {

                        @match job.status {
                            JobStatus::Success => i .bi-check-circle-fill .text-success {},
                            JobStatus::Failed => i .bi-x-circle-fill .text-danger {},
                            JobStatus::Running => i .bi-record-circle .text-primary {},
                            _ => i .bi-question-circle-fill .text-secondary {},
                        }
                        " "
                        span { (job.friendly_name()) }
                        " - "
                        @match (job.started_at, job.finished_at) {
                            (Some(started_at), Some(finished_at)) => {
                                span {
                                    "finished "
                                    time { (HumanTime::from(finished_at).to_text_en(Accuracy::Rough, Tense::Past)) }
                                    " (took "
                                    (HumanTime::from(finished_at - started_at).to_text_en(Accuracy::Rough, Tense::Present))
                                    ")"
                                }
                            },
                            (Some(started_at), None) => {
                                span {
                                    "started "
                                    time { (HumanTime::from(started_at).to_text_en(Accuracy::Rough, Tense::Past)) }
                                }
                            },
                            (None, _) => {
                                span { "not yet started" }
                            },
                        }
                    }
                }
            }
        }
    }
}
