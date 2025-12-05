defmodule Hookhub.Analytics do
  @moduledoc """
  Analytics context for generating statistics and reports.
  """
  import Ecto.Query
  alias Hookhub.Repo
  alias Hookhub.Events.Event
  alias Hookhub.Providers.Provider

  @doc """
  Get webhook statistics for the last N days.
  """
  def get_webhook_stats(days \\ 7) do
    start_date = DateTime.utc_now() |> DateTime.add(-days * 24 * 3600, :second)

    # Total webhooks
    total_webhooks =
      from(e in Event, where: e.inserted_at >= ^start_date)
      |> Repo.aggregate(:count)

    # Webhooks by provider
    webhooks_by_provider =
      from(e in Event,
        join: p in Provider,
        on: e.provider_id == p.id,
        where: e.inserted_at >= ^start_date,
        group_by: p.name,
        select: {p.name, count(e.id)}
      )
      |> Repo.all()
      |> Enum.into(%{})

    # Webhooks by event type
    webhooks_by_type =
      from(e in Event,
        where: e.inserted_at >= ^start_date,
        group_by: e.event_type,
        select: {e.event_type, count(e.id)}
      )
      |> Repo.all()
      |> Enum.into(%{})

    # Daily breakdown
    daily_stats =
      from(e in Event,
        where: e.inserted_at >= ^start_date,
        group_by: fragment("DATE(?)", e.inserted_at),
        select: {fragment("DATE(?)", e.inserted_at), count(e.id)},
        order_by: [asc: fragment("DATE(?)", e.inserted_at)]
      )
      |> Repo.all()

    %{
      total_webhooks: total_webhooks,
      webhooks_by_provider: webhooks_by_provider,
      webhooks_by_type: webhooks_by_type,
      daily_stats: daily_stats,
      period_days: days
    }
  end

  @doc """
  Get provider statistics.
  """
  def get_provider_stats do
    providers =
      from(p in Provider,
        left_join: e in Event,
        on: e.provider_id == p.id,
        group_by: [p.id, p.name],
        select: %{
          name: p.name,
          total_events: count(e.id),
          last_event: max(e.inserted_at)
        }
      )
      |> Repo.all()

    providers
  end

  @doc """
  Get recent activity (last 24 hours).
  """
  def get_recent_activity do
    last_24h = DateTime.utc_now() |> DateTime.add(-24 * 3600, :second)

    hourly_stats =
      from(e in Event,
        where: e.inserted_at >= ^last_24h,
        group_by: fragment("DATE_TRUNC('hour', ?)", e.inserted_at),
        select: {fragment("DATE_TRUNC('hour', ?)", e.inserted_at), count(e.id)},
        order_by: [asc: fragment("DATE_TRUNC('hour', ?)", e.inserted_at)]
      )
      |> Repo.all()

    %{
      hourly_stats: hourly_stats,
      total_last_24h: Enum.reduce(hourly_stats, 0, fn {_, count}, acc -> acc + count end)
    }
  end

  @doc """
  Get performance metrics.
  """
  def get_performance_metrics do
    # This would ideally come from telemetry metrics
    # For now, return sample data structure
    %{
      avg_response_time_ms: 45,
      p95_response_time_ms: 120,
      p99_response_time_ms: 180,
      success_rate: 99.5,
      error_rate: 0.5
    }
  end

  @doc """
  Get top event types.
  """
  def get_top_event_types(limit \\ 10) do
    from(e in Event,
      group_by: e.event_type,
      select: {e.event_type, count(e.id)},
      order_by: [desc: count(e.id)],
      limit: ^limit
    )
    |> Repo.all()
  end
end
