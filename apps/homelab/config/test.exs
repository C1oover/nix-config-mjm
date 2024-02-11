import Config

config :homelab, Oban, testing: :inline

# We don't run a server during test. If one is required,
# you can enable the server option below.
config :homelab, HomelabWeb.Endpoint,
  http: [ip: {127, 0, 0, 1}, port: 4002],
  secret_key_base: "N4hI+0VxC7M2Kt3ODedoGw3x1u0frAModU/+/1zw1xzgFAnPIS2G+MBG8fV7yJNL",
  server: false

# In test we don't send emails.
config :homelab, Homelab.Mailer, adapter: Swoosh.Adapters.Test

# Disable swoosh api client as it is only required for production adapters.
config :swoosh, :api_client, false

# Print only warnings and errors during test
config :logger, level: :warning

# Initialize plugs at runtime for faster test compilation
config :phoenix, :plug_init_mode, :runtime
