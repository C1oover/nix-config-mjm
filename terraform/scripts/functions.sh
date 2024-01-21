link_tf_config() {
  ln -sf "$TF_CONFIG" terraform/config.tf.json
}

tofu() {
  (cd terraform && command tofu "$@")
}
