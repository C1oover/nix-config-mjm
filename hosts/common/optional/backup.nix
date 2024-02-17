{
  vault-secrets.templates.restic-backup-env.text = ''
    AWS_DEFAULT_REGION=home
    {{ with secret "kv/restic" }}
    AWS_ACCESS_KEY_ID={{ .Data.data.garage_key_id }}
    AWS_SECRET_ACCESS_KEY={{ .Data.data.garage_secret_key }}
    {{ end }}
  '';
}
