defmodule Homelab.Backups do
  @moduledoc """
  The Backups context.
  """

  require OpenTelemetry.Tracer, as: Tracer

  alias Homelab.Backups.{Borg, Restic, Tarsnap}
  alias Homelab.Cache
  alias Homelab.Otel

  # def list_archives(kinds \\ [:borg, :tarsnap]) do
  #   Tracer.with_span :list_archives do
  #     {uncached_kinds, cached_results} = fetch_cached_results(kinds)

  #     uncached_kinds
  #     |> Enum.map(&async_list_archives(&1))
  #     |> Task.yield_many(20_000)
  #     |> Enum.map(fn {task, res} -> res || Task.shutdown(task, :brutal_kill) end)
  #     |> Enum.flat_map(fn
  #       {:ok, [first | _rest] = results} -> write_results_to_cache(first.kind, results)
  #       _ -> []
  #     end)
  #     |> Kernel.++(cached_results)
  #     |> Enum.sort(&(DateTime.compare(&1.time, &2.time) != :lt))
  #   end
  # end

  def list_archives() do
    Enum.sort(Restic.list_snapshots(:onsite), &(DateTime.compare(&1.time, &2.time) != :lt))
  end

  def get_archive(kind, name) do
    Tracer.with_span :get_archive, %{
      attributes: %{
        "backup.kind": kind,
        "backup.name": name
      }
    } do
      case Cache.get({:backup, kind, name}) do
        nil ->
          archive =
            case kind do
              :borg -> Borg.get_archive(name) |> IO.inspect()
            end

          :ok = Cache.put({:backup, kind, name}, archive)
          archive

        archive ->
          archive
      end
    end
  end

  defp async_list_archives(kind) do
    Otel.async_nolink(
      fn -> list_archives_by_kind(kind) end,
      shutdown: :brutal_kill
    )
  end

  def list_archives_by_kind(kind) do
    Tracer.with_span :list_archives_by_kind, %{attributes: %{"backup.kind": kind}} do
      case kind do
        :borg ->
          Borg.list_archives()

        :tarsnap ->
          Tarsnap.list_archives()
      end
    end
  end

  defp fetch_cached_results(kinds) do
    {uncached_kinds, results} =
      Enum.reduce(
        kinds,
        {[], []},
        fn kind, {uncached_kinds, acc_results} ->
          case Cache.get({:backups, kind}) do
            nil -> {[kind | uncached_kinds], acc_results}
            results -> {uncached_kinds, [results | acc_results]}
          end
        end
      )

    {uncached_kinds, List.flatten(results)}
  end

  defp write_results_to_cache(kind, results) do
    :ok = Cache.put({:backups, kind}, results, ttl: :timer.minutes(5))
    results
  end
end
