use crate::{deploys::GitLabClient, netbox};
use anyhow::Result;

#[tracing::instrument(skip(gitlab_client, netbox_token), fields(update_needed), err)]
pub async fn update_dns_records(gitlab_client: &GitLabClient, netbox_token: &str) -> Result<()> {
    let (current_hosts_file, new_hosts_file) = tokio::try_join!(
        gitlab_client.get_hosts_file(),
        build_hosts_file(netbox_token)
    )?;

    if current_hosts_file != new_hosts_file {
        tracing::Span::current().record("update_needed", true);
        gitlab_client.update_hosts_file(&new_hosts_file).await?;
    } else {
        tracing::Span::current().record("update_needed", false);
    }

    Ok(())
}

#[derive(serde::Serialize)]
struct AddressEntry {
    name: String,
    family: i64,
    address: String,
}

#[tracing::instrument(skip(netbox_token), fields(hosts.count) err, ret)]
async fn build_hosts_file(netbox_token: &str) -> Result<String> {
    let hosts = netbox::list_hosts(netbox_token, ".home.mattmoriarity.com").await?;
    tracing::Span::current().record("hosts.count", hosts.len());

    let entries = hosts
        .into_iter()
        .map(|h| {
            let name = h
                .dns_name
                .strip_suffix(".home.mattmoriarity.com")
                .expect("string should have domain name as suffix")
                .to_string();

            let family = h
                .family
                .expect("expected address to have a family")
                .value
                .expect("expected family to have a value");

            let mut address = h.address;
            address.truncate(address.len() - 3);

            AddressEntry {
                name,
                family,
                address,
            }
        })
        .collect::<Vec<_>>();

    Ok(serde_json::to_string_pretty(&entries)?)
}
