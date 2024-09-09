use figment::Figment;
use figment_file_provider_adapter::FileAdapter;
use serde::Deserialize;

#[derive(Deserialize, Debug, Clone)]
pub struct Config {
    #[serde(default = "default_bind_address")]
    pub bind_address: String,
    pub gitlab_token: String,
    pub paperless_token: String,
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
