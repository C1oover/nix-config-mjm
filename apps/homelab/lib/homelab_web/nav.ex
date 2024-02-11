defmodule HomelabWeb.Nav do
  import Phoenix.LiveView
  import Phoenix.Component

  def on_mount(:default, _params, _session, socket) do
    {:cont,
     socket
     |> attach_hook(:active_tab, :handle_params, &set_active_tab/3)}
  end

  defp set_active_tab(_params, _url, socket) do
    active_tab =
      case {socket.view, socket.assigns.live_action} do
        {HomelabWeb.BackupLive.Index, _} ->
          :backups

        {HomelabWeb.DeployLive.Index, _} ->
          :deploys

        {HomelabWeb.TaskLive.Index, _} ->
          :tasks

        {_, _} ->
          nil
      end

    {:cont, assign(socket, active_tab: active_tab)}
  end
end
