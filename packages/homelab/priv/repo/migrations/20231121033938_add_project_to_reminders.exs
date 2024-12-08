defmodule Homelab.Repo.Migrations.AddProjectToReminders do
  use Ecto.Migration

  def change do
    alter table("reminders") do
      add :project, :string
    end
  end
end
