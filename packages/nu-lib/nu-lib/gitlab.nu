export def "mr list" [
  --url: string
  --project: string
  --token: string
  --filters: record
] {
  (http get
    --headers [Authorization $"Bearer ($token)"]
    $"($url)/projects/($project)/merge_requests?($filters | url build-query)")
}

export def "mr create" [
  --url: string
  --project: string
  --token: string
  body: record
] {
  (http post
    --content-type application/json
    --headers [Authorization $"Bearer ($token)"]
    $"($url)/projects/($project)/merge_requests"
    $body)
}

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
