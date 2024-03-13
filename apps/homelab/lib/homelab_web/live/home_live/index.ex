defmodule HomelabWeb.HomeLive.Index do
  use HomelabWeb, :live_view

  def mount(_params, _session, socket) do
    :timer.send_interval(15_000, :update_alerts)
    :timer.send_interval(60_000, :update_inbox_docs)

    {:ok, socket |> assign_alerts() |> assign_inbox_docs()}
  end

  defp assign_alerts(socket) do
    assign_async(socket, :alerts, fn ->
      with {:ok, alerts} <- Homelab.Prometheus.list_alerts() do
        {:ok, %{alerts: alerts}}
      end
    end)
  end

  defp assign_inbox_docs(socket) do
    assign_async(socket, :inbox_docs, fn ->
      with {:ok, docs} <- Homelab.Paperless.list_documents_by_tag("inbox") do
        {:ok, %{inbox_docs: docs}}
      end
    end)
  end

  def handle_info(:update_alerts, socket), do: {:noreply, assign_alerts(socket)}
  def handle_info(:update_inbox_docs, socket), do: {:noreply, assign_inbox_docs(socket)}

  attr(:initials, :string, required: true)
  attr(:color, :string, required: true)
  attr(:href, :string, required: true)
  slot(:title, required: true)
  slot(:subtitle, required: true)

  def app_link(assigns) do
    ~H"""
    <li class="col-span-1 flex shadow-sm sm:rounded-md">
      <div class={"flex-shrink-0 flex items-center justify-center w-16 #{@color} text-white text-sm font-medium sm:rounded-l-md"}>
        <%= @initials %>
      </div>
      <div class="flex-1 flex items-center justify-between border-t border-r border-b border-gray-200 dark:border-gray-800 bg-white dark:bg-gray-800 sm:rounded-r-md truncate">
        <div class="flex-1 px-4 py-2 text-sm truncate">
          <a
            href={@href}
            target="_blank"
            class="text-gray-900 dark:text-white font-medium hover:text-gray-600 dark:hover:text-gray-300"
          >
            <%= render_slot(@title) %>
          </a>
          <p class="text-gray-500"><%= render_slot(@subtitle) %></p>
        </div>
      </div>
    </li>
    """
  end
end
