use axum::{extract::State, response::IntoResponse, routing::get, Router};
use chrono_humanize::{Accuracy, HumanTime, Tense};
use maud::{html, Markup};
use tokio::try_join;

use crate::{app, deploys::JobStatus};

use super::{GitLabClient, MergeRequest};

pub fn router() -> Router<app::State> {
    Router::new().route("/deploys", get(index))
}

#[tracing::instrument(skip(client))]
async fn index(State(client): State<GitLabClient>) -> Result<impl IntoResponse, app::Error> {
    let (mrs, deploys) = try_join!(client.list_open_merge_requests(), client.list_deployments())?;

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
                    @let (title, _desc) = deploy.deployable.commit.split_message();
                    li
                        .list-group-item
                        .list-group-item-danger[deploy.is_failed()]
                        .list-group-item-secondary[deploy.is_blocked()] {

                        a href=(deploy.deployable.web_url) target="_blank"
                            .text-decoration-none .text-reset {

                            div {
                                span .fw-bold { (title) }
                            }

                            div {
                                span .badge .text-bg-secondary {
                                    (deploy.deployable.friendly_name())
                                }
                            }
                        }
                    }
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

                ul .list-unstyled {
                    @for job in &mr.head_pipeline.jobs {
                        li {
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
}
