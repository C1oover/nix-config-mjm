defmodule Homelab.Tasks.Templates do
  alias Homelab.Tasks

  def add_weekly_meal_tasks() do
    # TODO import these with structured data

    with {:ok, %{uuid: prev_id}} <- Tasks.create_task("cook 1st blue apron meal project:home"),
         {:ok, %{uuid: prev_id}} <-
           Tasks.create_task("clean up kitchen project:home depends:#{prev_id}"),
         {:ok, %{uuid: prev_id}} <-
           Tasks.create_task("cook 2nd blue apron meal project:home depends:#{prev_id}"),
         {:ok, %{uuid: prev_id}} <-
           Tasks.create_task("clean up kitchen project:home depends:#{prev_id}"),
         {:ok, %{uuid: prev_id}} <-
           Tasks.create_task("cook 3rd blue apron meal project:home depends:#{prev_id}"),
         {:ok, _} <- Tasks.create_task("clean up kitchen project:home depends:#{prev_id}") do
      :ok
    end
  end

  def add_laundry_tasks() do
    # TODO import these with structured data

    with {:ok, %{uuid: wash_hot_id}} <-
           Tasks.create_task("wash hot laundry project:home.laundry +next"),
         {:ok, %{uuid: prev_id}} <-
           Tasks.create_task("dry hot clothes project:home.laundry depends:#{wash_hot_id}"),
         {:ok, _} <-
           Tasks.create_task("put away hot clothes project:home.laundry depends:#{prev_id}"),
         {:ok, %{uuid: prev_id}} <-
           Tasks.create_task("wash cold clothes project:home.laundry depends:#{wash_hot_id}"),
         {:ok, %{uuid: prev_id}} <-
           Tasks.create_task("dry cold clothes project:home.laundry depends:#{prev_id}"),
         {:ok, _} <-
           Tasks.create_task("put away cold clothes project:home.laundry depends:#{prev_id}") do
      :ok
    end
  end
end
