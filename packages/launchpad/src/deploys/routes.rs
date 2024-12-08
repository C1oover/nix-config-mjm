use axum::{extract::State, response::IntoResponse, routing::get, Router};
use maud::html;
use tokio::try_join;

use crate::app;

use super::GitLabClient;

pub fn router() -> Router<app::State> {
    Router::new().route("/deploys", get(index))
}

#[tracing::instrument(skip(client))]
async fn index(State(client): State<GitLabClient>) -> Result<impl IntoResponse, app::Error> {
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
