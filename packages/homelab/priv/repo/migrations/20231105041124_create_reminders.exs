defmodule Homelab.Repo.Migrations.CreateReminders do
  use Ecto.Migration

  def change do
    create table("reminders") do
      add :description, :string, null: false
      add :started_at, :utc_datetime
      add :notify_at, :utc_datetime, null: false
      add :snooze_minutes, :integer
      add :recurrence, :map

      timestamps()
    end
  end
end
