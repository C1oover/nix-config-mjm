use anyhow::{anyhow, Result};
use graphql_client::{GraphQLQuery, Response};

#[derive(GraphQLQuery)]
#[graphql(
    schema_path = "src/netbox-schema.json",
    query_path = "src/netbox-hostnames.graphql",
    response_derives = "Debug"
)]
struct HostnamesQuery;

#[tracing::instrument(err)]
pub async fn list_hosts(
    token: &str,
    domain: &str,
) -> Result<Vec<hostnames_query::HostnamesQueryIpAddressList>> {
    let client = reqwest::Client::new();
    let token_header = format!("Token {token}");

    let variables = hostnames_query::Variables {
        domain: Some(String::from(domain)),
    };

    let body = HostnamesQuery::build_query(variables);
    let resp = client
        .post("http://netbox.service.consul:8000/graphql/")
        .header("authorization", token_header)
        .json(&body)
        .send()
        .await?
        .json::<Response<hostnames_query::ResponseData>>()
        .await?;

    let data = resp.data.ok_or(anyhow!("no response data returned"))?;

    Ok(data.ip_address_list.unwrap())
}
