defmodule Hookhub.Events do
  @moduledoc """
  The Events context.
  Handles webhook event ingestion and querying.
  """

  import Ecto.Query, warn: false
  alias Hookhub.Repo
  alias Hookhub.Events.{Event, Normalizer}
  alias Hookhub.Providers.Provider

  @doc """
  Ingests a webhook event from a provider.
  Normalizes the payload and creates an event record.
  Returns {:ok, event} or {:error, reason}.
  Handles idempotency - duplicate events return {:ok, :duplicate}.
  """
  def ingest_webhook(payload, %Provider{} = provider) do
    with {:ok, normalized} <- Normalizer.normalize(payload, provider),
         attrs <- Map.put(normalized, :provider_id, provider.id),
         changeset <- Event.changeset(%Event{}, attrs),
         {:ok, event} <- Repo.insert(changeset) do
      {:ok, event}
    else
      {:error, %Ecto.Changeset{errors: errors} = changeset} ->
        # Check if it's an idempotency error
        case Keyword.get(errors, :external_event_id) do
          {"Event already exists (idempotency)", _} ->
            {:ok, :duplicate}

          _ ->
            {:error, changeset}
        end

      {:error, reason} ->
        {:error, reason}
    end
  end

  @doc """
  Lists events with optional filters.

  ## Options
    * `:provider_id` - Filter by provider UUID
    * `:event_type` - Filter by event type
    * `:start_date` - Filter events after this datetime
    * `:end_date` - Filter events before this datetime
    * `:page` - Page number (default: 1)
    * `:page_size` - Number of items per page (default: 20)
  """
  def list_events(opts \\ []) do
    page = Keyword.get(opts, :page, 1)
    page_size = Keyword.get(opts, :page_size, 20)
    offset = (page - 1) * page_size

    query =
      Event
      |> apply_filters(opts)
      |> order_by([e], desc: e.timestamp)
      |> limit(^page_size)
      |> offset(^offset)
      |> preload(:provider)

    events = Repo.all(query)
    total = count_events(opts)

    %{
      data: events,
      pagination: %{
        page: page,
        page_size: page_size,
        total: total,
        total_pages: ceil(total / page_size)
      }
    }
  end

  @doc """
  Gets a single event by ID.
  """
  def get_event(id) do
    Event
    |> preload(:provider)
    |> Repo.get(id)
  end

  # Private functions

  defp apply_filters(query, opts) do
    Enum.reduce(opts, query, fn
      {:provider_id, provider_id}, query when not is_nil(provider_id) ->
        where(query, [e], e.provider_id == ^provider_id)

      {:event_type, event_type}, query when not is_nil(event_type) ->
        where(query, [e], e.event_type == ^event_type)

      {:start_date, start_date}, query when not is_nil(start_date) ->
        where(query, [e], e.timestamp >= ^start_date)

      {:end_date, end_date}, query when not is_nil(end_date) ->
        where(query, [e], e.timestamp <= ^end_date)

      _, query ->
        query
    end)
  end

  defp count_events(opts) do
    Event
    |> apply_filters(opts)
    |> Repo.aggregate(:count)
  end
end
