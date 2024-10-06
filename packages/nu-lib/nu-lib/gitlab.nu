export def "mr note create" [
  --url: string
  --project: string
  --token: string
  --mr: string
  --body: string
] {
  let body = { body: $body };
  (http post
    --content-type application/json
    --headers [Authorization $"Bearer ($token)"]
    $"($url)/projects/($project)/merge_requests/($mr)/notes"
    $body)
}
