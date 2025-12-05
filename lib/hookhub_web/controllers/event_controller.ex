defmodule HookhubWeb.EventController do
  use HookhubWeb, :controller

  alias Hookhub.Events

  @doc """
  GET /api/events
  Lists events with optional filters and pagination.

  Query params:
    - provider_id: UUID
    - event_type: string
    - start_date: ISO8601 datetime
    - end_date: ISO8601 datetime
    - page: integer (default: 1)
    - page_size: integer (default: 20)
  """
  def index(conn, params) do
    opts = build_query_opts(params)
    result = Events.list_events(opts)

    json(conn, %{
      data: Enum.map(result.data, &format_event/1),
      pagination: result.pagination
    })
  end

  @doc """
  GET /api/events/:id
  Gets a single event by ID.
  """
  def show(conn, %{"id" => id}) do
    case Events.get_event(id) do
      nil ->
        conn
        |> put_status(:not_found)
        |> json(%{error: "Event not found"})

      event ->
        json(conn, %{data: format_event(event)})
    end
  end

  defp build_query_opts(params) do
    []
    |> maybe_add_filter(:provider_id, params["provider_id"])
    |> maybe_add_filter(:event_type, params["event_type"])
    |> maybe_add_date_filter(:start_date, params["start_date"])
    |> maybe_add_date_filter(:end_date, params["end_date"])
    |> maybe_add_filter(:page, parse_integer(params["page"]))
    |> maybe_add_filter(:page_size, parse_integer(params["page_size"]))
  end

  defp maybe_add_filter(opts, _key, nil), do: opts
  defp maybe_add_filter(opts, _key, ""), do: opts
  defp maybe_add_filter(opts, key, value), do: Keyword.put(opts, key, value)

  defp maybe_add_date_filter(opts, _key, nil), do: opts
  defp maybe_add_date_filter(opts, _key, ""), do: opts

  defp maybe_add_date_filter(opts, key, date_string) do
    case DateTime.from_iso8601(date_string) do
      {:ok, datetime, _} -> Keyword.put(opts, key, datetime)
      _ -> opts
    end
  end

  defp parse_integer(nil), do: nil
  defp parse_integer(value) when is_integer(value), do: value

  defp parse_integer(value) when is_binary(value) do
    case Integer.parse(value) do
      {int, _} -> int
      :error -> nil
    end
  end

  defp format_event(event) do
    %{
      id: event.id,
      provider: %{
        id: event.provider.id,
        name: event.provider.name
      },
      external_event_id: event.external_event_id,
      event_type: event.event_type,
      timestamp: event.timestamp,
      sender: %{
        id: event.sender_id,
        name: event.sender_name
      },
      recipient: %{
        id: event.recipient_id,
        name: event.recipient_name
      },
      message: %{
        type: event.message_type,
        body: event.message_body
      },
      platform: event.platform,
      raw_payload: event.raw_payload,
      inserted_at: event.inserted_at
    }
  end
end
