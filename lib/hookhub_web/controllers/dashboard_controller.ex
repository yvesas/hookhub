defmodule HookhubWeb.DashboardController do
  use HookhubWeb, :controller

  alias Hookhub.{Events, Providers}

  @doc """
  GET /dashboard
  Main dashboard page showing event history.
  """
  def index(conn, params) do
    # Get filter parameters and convert empty strings to nil
    provider_id = normalize_param(Map.get(params, "provider_id"))
    event_type = normalize_param(Map.get(params, "event_type"))
    start_date = parse_date(Map.get(params, "start_date"))
    end_date = parse_date(Map.get(params, "end_date"))
    page = parse_integer(Map.get(params, "page"), 1)

    # Build query options
    opts = [
      provider_id: provider_id,
      event_type: event_type,
      start_date: start_date,
      end_date: end_date,
      page: page,
      page_size: 20
    ]

    # Get events and providers for filter dropdown
    result = Events.list_events(opts)
    providers = Providers.list_providers()

    render(conn, :index,
      events: result.data,
      pagination: result.pagination,
      providers: providers,
      filters: %{
        provider_id: provider_id,
        event_type: event_type,
        start_date: Map.get(params, "start_date"),
        end_date: Map.get(params, "end_date")
      }
    )
  end

  @doc """
  GET /dashboard/api-keys
  API keys management page.
  """
  def api_keys(conn, _params) do
    providers = Providers.list_providers()
    api_keys = Providers.list_api_keys()

    render(conn, :api_keys,
      providers: providers,
      api_keys: api_keys
    )
  end

  def analytics(conn, params) do
    days = String.to_integer(Map.get(params, "days") || "7")

    webhook_stats = Hookhub.Analytics.get_webhook_stats(days)
    provider_stats = Hookhub.Analytics.get_provider_stats()
    recent_activity = Hookhub.Analytics.get_recent_activity()
    performance_metrics = Hookhub.Analytics.get_performance_metrics()
    top_event_types = Hookhub.Analytics.get_top_event_types(10)

    render(conn, :analytics,
      webhook_stats: webhook_stats,
      provider_stats: provider_stats,
      recent_activity: recent_activity,
      performance_metrics: performance_metrics,
      top_event_types: top_event_types,
      selected_days: days
    )
  end

  defp normalize_param(nil), do: nil
  defp normalize_param(""), do: nil
  defp normalize_param(value), do: value

  defp parse_date(nil), do: nil
  defp parse_date(""), do: nil

  defp parse_date(date_string) do
    case Date.from_iso8601(date_string) do
      {:ok, date} ->
        {:ok, datetime} = DateTime.new(date, ~T[00:00:00])
        datetime

      _ ->
        nil
    end
  end

  defp parse_integer(nil, default), do: default
  defp parse_integer("", default), do: default

  defp parse_integer(value, default) when is_binary(value) do
    case Integer.parse(value) do
      {int, _} -> int
      :error -> default
    end
  end

  defp parse_integer(value, _default) when is_integer(value), do: value
end
