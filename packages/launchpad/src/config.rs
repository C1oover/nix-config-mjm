use figment::Figment;
use figment_file_provider_adapter::FileAdapter;
use serde::Deserialize;

#[derive(Deserialize, Debug, Clone)]
pub struct Config {
    #[serde(default = "default_bind_address")]
    pub bind_address: String,
    pub database_url: String,
    pub gitlab_token: String,
    pub reminders_topic: String,
    pub paperless_token: String,
    #[serde(default = "default_local_time_zone")]
    pub local_time_zone: String,
    #[serde(default = "default_enable_pretty_output")]
    pub enable_pretty_output: bool,
}

impl Config {
    pub fn figment() -> Figment {
        use figment::providers::Env;

        Figment::new().merge(FileAdapter::wrap(Env::prefixed("LAUNCHPAD_")))
    }
}

fn default_bind_address() -> String {
    "127.0.0.1:8000".to_string()
}

fn default_local_time_zone() -> String {
    "America/Denver".to_string()
}

fn default_enable_pretty_output() -> bool {
    true
}
