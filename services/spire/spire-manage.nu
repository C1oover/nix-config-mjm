
# Examples:
#
# spire-manage register svc sonarr --parent-node chaos --tunnel sonarr --consul-dns
# spire-manage register svc sonarr --tunnel sonarr-metrics --consul-dns
# spire-manage register svc sonarr --creds
# spire-manage register svc sonarr --certs


const trust_domain = "home.mattmoriarity.com"
const spiffe_prefix = $"spiffe://($trust_domain)"
const svc_prefix = $"($spiffe_prefix)/svc"

def spire-register [
  entries: list = []
] {
  let data = { entries: $entries }

  # $data | to json | print
  $data | to json | spire-server entry create -socketPath /run/spire-server/api.sock -data -
}

def "selector make systemd" [name] {
  { type: "systemd", value: $"id:($name)" }
}

def "selector make tunnel" [name] {
  selector make systemd $"($name)-tunnel.service"
}

def "selector make creds" [name] {
  selector make systemd $"spiffe-creds@($name).service"
}

def "selector make certs" [name] {
  selector make systemd $"spiffe-certs@($name).service"
}

def "main register svc" [
  name: string
  --parent-service: string = ""
  --parent-node: string = ""
  --tunnel: string = ""
  --systemd-unit: string = ""
  --creds
  --certs
  --consul-dns
] {
  let spiffe_id = $"($svc_prefix)/($name)"

  let parent_id = if ($parent_service | is-not-empty) {
    $"($svc_prefix)/($parent_service)"
  } else if ($parent_node | is-not-empty) {
    $"($spiffe_prefix)/($parent_node)"
  } else {
    $spiffe_id
  }

  let selector = if ($tunnel | is-not-empty) {
    selector make tunnel $tunnel
  } else if ($systemd_unit | is-not-empty) {
    selector make systemd $systemd_unit
  } else if $creds {
    selector make creds $name
  } else if $certs {
    selector make certs $name
  } else {
    {
      type: "spiffe_id"
      value: $parent_id
    }
  }

  let dns = if $consul_dns {
    [$"($name).service.consul"]
  } else {
    []
  }

  let entries = [
    {
      spiffe_id: $spiffe_id
      parent_id: $parent_id
      selectors: [$selector]
      dns_names: $dns
    }
  ]
  spire-register $entries
}

def "main register consul" [
  name: string
] {
  main register svc consul-agent --parent-service $name --tunnel $"consul-($name)"
}

def "main register node" [
  name: string
] {
  let spiffe_id = $"($spiffe_prefix)/($name)"

  let entries = [
    {
      spiffe_id: $"($spiffe_prefix)/generic-server"
      parent_id: $spiffe_id
      selectors: [{ type: "spiffe_id", value: $spiffe_id }]
    }
    {
      spiffe_id: $"($spiffe_id)/sshd"
      parent_id: $spiffe_id
      selectors: [(selector make systemd sshd-host-cert.service)]
    }
    {
      spiffe_id: $"($svc_prefix)/consul-client"
      parent_id: $spiffe_id
      selectors: [(selector make certs consul)]
    }
  ]
  spire-register $entries
}

def main [] {}
