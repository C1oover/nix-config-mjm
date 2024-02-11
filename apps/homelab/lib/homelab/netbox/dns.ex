defmodule Homelab.NetBox.DNS do
  alias Homelab.NetBox

  @hostnames_query """
    query($domain: [String]) {
      ip_address_list(dns_name__iew: $domain) {
        address
        dns_name
        family { value }
      }
    }
  """

  def zone_file(domain, opts \\ []) do
    suffix = ".#{domain}"

    {:ok, %{"data" => %{"ip_address_list" => hosts}}} =
      NetBox.query(@hostnames_query, domain: [suffix])

    a_records =
      hosts
      |> Enum.map(&a_record(&1, suffix))
      |> Enum.join("\n")

    if Keyword.get(opts, :only_records, false) do
      "#{a_records}\n"
    else
      """
      $TTL  1m
      @   IN  SOA localhost. matt.mattmoriarity.com. (
                        1
                       1m     ; Refresh
                       1h     ; Retry
                       1w     ; Expire
                       1h )   ; Negative Cache TTL
      @   IN  NS  localhost.

      #{a_records}

      {{ with $vhosts := key "ingress/vhost_names" | parseJSON }}
      {{ range $vhosts }}
      {{ . }}  IN  CNAME ingress-http.service.consul.
      {{ end }}
      {{ end }}
      """
    end
  end

  defp a_record(%{"address" => address, "dns_name" => dns_name} = ip, suffix) do
    hostname = String.replace_suffix(dns_name, suffix, "")
    address = NetBox.strip_mask(address)
    "#{String.pad_trailing(hostname, 20)}  IN  #{record_type(ip)}  #{address}"
  end

  defp record_type(%{"family" => %{"value" => 4}}), do: "A   "
  defp record_type(%{"family" => %{"value" => 6}}), do: "AAAA"
end
