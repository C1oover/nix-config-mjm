defmodule Homelab.Jobs.UpdateDNS do
  use Oban.Worker, unique: [period: 120, states: [:available, :scheduled, :executing]]

  alias Homelab.{GitLab, NetBox}

  @domain "home.mattmoriarity.com"

  @project "mjm/nix-config"
  @zone_file_path "hosts/common/optional/dns-server/#{@domain}.hosts.zone"

  @impl Oban.Worker
  def perform(%Oban.Job{}) do
    {:ok, current_zone_file} = GitLab.get_repository_file_raw(@project, @zone_file_path)
    new_zone_file = NetBox.DNS.zone_file(@domain, only_records: true)

    if current_zone_file != new_zone_file do
      {:ok, _} =
        GitLab.update_repository_file(@project, @zone_file_path, new_zone_file,
          branch: "main",
          commit_message: "dns-server: update host records",
          author_name: "Homelab Automation",
          author_email: "homelab@matt.mattmoriarity.com"
        )
    end

    :ok
  end
end
