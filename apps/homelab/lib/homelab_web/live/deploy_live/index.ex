defmodule HomelabWeb.DeployLive.Index do
  use HomelabWeb, :live_view

  alias Homelab.Deploys
  alias Homelab.Deploys.{Build, Deploy}

  def mount(_params, _session, socket) do
    :timer.send_interval(5_000, :update_now)
    :timer.send_interval(30_000, :update_data)

    {:ok, socket |> assign_now() |> assign_data()}
  end

  def handle_info(:update_now, socket) do
    {:noreply, assign_now(socket)}
  end

  def handle_info(:update_data, socket) do
    {:noreply, assign_data(socket)}
  end

  defp assign_now(socket) do
    assign(socket, :now, DateTime.utc_now())
  end

  defp assign_data(socket) do
    socket
    |> assign_async([:infra_deploys, :refreshed_at], fn ->
      {:ok,
       %{
         infra_deploys: Deploys.list_recent_infra_deployments(),
         refreshed_at: DateTime.utc_now()
       }}
    end)
    |> assign_async(:infra_build, fn ->
      {:ok, %{infra_build: Deploys.get_latest_infra_build()}}
    end)
  end

  defp icon_style(%Deploy{state: :success}), do: "bg-green-500"
  defp icon_style(%Deploy{state: :failure}), do: "bg-red-600"
  defp icon_style(%Deploy{state: state}) when state in [:inactive, :pending], do: "bg-gray-300"
  defp icon_style(%Deploy{state: :in_progress}), do: "bg-yellow-500"
  defp icon_style(_), do: nil

  def deploy_icon(%Deploy{state: :success}), do: "hero-check"
  def deploy_icon(%Deploy{state: :failure}), do: "hero-x-mark"
  def deploy_icon(%Deploy{state: :inactive}), do: "hero-chevron-right"
  def deploy_icon(%Deploy{state: state}) when state in [:in_progress, :pending], do: "hero-clock"
  def deploy_icon(_), do: "hero-question-mark-circle"

  attr(:build, :any, required: true)
  attr(:now, :any, required: true)
  attr(:running_title, :string, required: true)
  attr(:finished_title, :string, required: true)
  attr(:icon, :string, required: true)

  def build_card(assigns) do
    ~H"""
    <.async_result :let={build} assign={@build}>
      <:loading>
        <.stat_card title={@finished_title}>
          <:icon><.icon name={@icon} class="h-6 w-6 animate-pulse" /></:icon>
          Loading build info...
        </.stat_card>
      </:loading>

      <:failed>
        <.stat_card title={@finished_title}>
          <:icon><.icon name={@icon} class="h-6 w-6" /></:icon>
          Failed to load info.
        </.stat_card>
      </:failed>

      <.stat_card title={if Build.completed?(build), do: @finished_title, else: @running_title}>
        <:icon>
          <.icon
            name={@icon}
            class={["h-6 w-6", if(not Build.completed?(build), do: "animate-pulse")]}
          />
        </:icon>
        <%= cond do %>
          <% Build.completed?(build) -> %>
            <div class="inline-flex items-center space-x-1">
              <.relative_time
                time={build.finished_at || build.started_at || build.queued_at}
                now={@now}
              />
              <%= case build.state do %>
                <% :success -> %>
                  <.icon name="hero-check-circle-mini" class="h-5 w-5 text-green-500" />
                <% :failure -> %>
                  <.icon name="hero-x-circle-mini" class="h-5 w-5 text-red-600" />
                <% _ -> %>
                  <.icon name="hero-question-mark-circle-mini" class="h-5 w-5 text-gray-300" />
              <% end %>
            </div>
          <% build.percent != nil -> %>
            <%= build.percent %>% complete
          <% build.started_at != nil -> %>
            Began <.relative_time time={build.started_at} now={@now} />
          <% true -> %>
            Queued <.relative_time time={build.queued_at} now={@now} />
        <% end %>
        <:link href={build.url} target="_blank">
          View on GitLab
        </:link>
      </.stat_card>
    </.async_result>
    """
  end

  attr(:deploy, :any, required: true)

  defp job_label(assigns) do
    ~H"""
    <span class="font-semibold">
      <%= case {@deploy.repo, @deploy.job} do %>
        <% {"mjm/nix-config", "deploy nixos hosts: [x86_64]"} -> %>
          NixOS: x86_64
        <% {"mjm/nix-config", "deploy nixos hosts: [arm64]"} -> %>
          NixOS: aarch64
        <% {"mjm/nix-config", "apply terranix changes"} -> %>
          Terranix
        <% {_, job} -> %>
          <%= job %>
      <% end %>
      –
    </span>
    """
  end
end
