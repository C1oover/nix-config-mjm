defmodule HomelabWeb.DeployLive.Show do
  use HomelabWeb, :live_view
  use HomelabWeb.AsyncData

  alias Homelab.Deploys
  alias Homelab.Deploys.Deploy
  alias Homelab.Deploys.Proto.ReportEvent

  fetch :deploy do
    Deploys.get_deployment(socket.assigns.deploy_id)
  end

  fetch :events do
    list_deploy_events(socket.assigns.deploy_id)
  end

  def mount(_params, _session, socket) do
    {:ok, socket}
  end

  def handle_params(%{"id" => id}, _, socket) do
    {:noreply,
     socket
     |> assign(:deploy_id, id)
     |> fetch_and_assign_all()}
  end

  defp list_deploy_events(id) do
    case Deploys.get_deployment_report(id) do
      %{events: events} -> events
      _ -> []
    end
  end

  defp seconds_since_start(
         %ReportEvent{timestamp: %{seconds: event_s}},
         %Deploy{started_at: deploy_time}
       ) do
    event_s - DateTime.to_unix(deploy_time)
  end

  defp icon_style(%ReportEvent{level: :ERROR}), do: "bg-red-600"
  defp icon_style(%ReportEvent{level: :WARNING}), do: "bg-yellow-500"
  defp icon_style(_), do: "bg-gray-400"

  attr :event, :any, required: true

  def event_icon(assigns) do
    ~H"""
    <%= case @event.level do %>
      <% :ERROR -> %>
        <.icon name="hero-x-mark" class="h-5 w-5" />
      <% :WARNING -> %>
        <.icon name="hero-exclamation-triangle" class="h-5 w-5" />
      <% _ -> %>
        <.icon name="hero-chevron-right" class="h-5 w-5 ml-px" />
    <% end %>
    """
  end

  attr :commit, :any, required: true

  def commit_message(assigns) do
    {subject, message} =
      case String.split(assigns.commit.message, "\n", parts: 2, trim: true) do
        [subject] -> {subject, nil}
        [subject, message] -> {subject, message}
      end

    assigns = assign(assigns, subject: subject, message: message)

    ~H"""
    <.link
      href={"https://github.com/mjm/pi-tools/commit/#{@commit.sha}"}
      class="font-medium text-indigo-600 hover:text-indigo-500"
      target="_blank"
    >
      <%= @subject %>
    </.link>
    <%= if @message != nil do %>
      <p class="mt-4 whitespace-pre-line"><%= @message %></p>
    <% end %>
    """
  end
end
