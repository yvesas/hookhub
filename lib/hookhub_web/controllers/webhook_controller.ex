defmodule HookhubWeb.WebhookController do
  use HookhubWeb, :controller

  alias Hookhub.Events

  plug(HookhubWeb.Plugs.ApiKeyAuth)

  @doc """
  POST /webhooks/ingest
  Receives webhook payloads from external providers.
  Requires X-API-Key header for authentication.
  """
  def ingest(conn, payload) do
    provider = conn.assigns.current_provider
    start_time = System.monotonic_time()

    # Emit telemetry start event
    :telemetry.execute(
      [:hookhub, :webhook, :ingest, :start],
      %{system_time: System.system_time()},
      %{
        provider: provider.name,
        event_type: get_event_type(payload),
        request_id: Logger.metadata()[:request_id]
      }
    )

    result = Events.ingest_webhook(payload, provider)
    duration = System.monotonic_time() - start_time

    case result do
      {:ok, :duplicate} ->
        # Emit duplicate event
        :telemetry.execute(
          [:hookhub, :webhook, :duplicate],
          %{count: 1},
          %{provider: provider.name, external_event_id: get_external_id(payload)}
        )

        # Idempotency: event already exists, return success
        conn
        |> put_status(:ok)
        |> json(%{
          status: "success",
          message: "Event already exists (idempotent)",
          duplicate: true
        })

      {:ok, event} ->
        # Emit success telemetry
        :telemetry.execute(
          [:hookhub, :webhook, :ingest, :stop],
          %{duration: duration},
          %{
            provider: provider.name,
            event_type: event.event_type,
            event_id: event.id,
            request_id: Logger.metadata()[:request_id]
          }
        )

        conn
        |> put_status(:ok)
        |> json(%{
          status: "success",
          message: "Event ingested successfully",
          event_id: event.id
        })

      {:error, :invalid_payload} ->
        conn
        |> put_status(:internal_server_error)
        |> json(%{
          status: "error",
          message: "Internal server error"
        })

      {:error, :unsupported_provider} ->
        conn
        |> put_status(:bad_request)
        |> json(%{
          status: "error",
          message: "Unsupported provider"
        })

      {:error, changeset} ->
        conn
        |> put_status(:bad_request)
        |> json(%{
          status: "error",
          message: "Validation failed",
          errors: format_changeset_errors(changeset)
        })
    end
  end

  # Helper functions for telemetry
  defp get_event_type(payload) do
    cond do
      Map.has_key?(payload, "event_type") -> payload["event_type"]
      Map.has_key?(payload, "type") -> payload["type"]
      true -> "unknown"
    end
  end

  defp get_external_id(payload) do
    cond do
      Map.has_key?(payload, "event_id") -> payload["event_id"]
      Map.has_key?(payload, "id") -> payload["id"]
      true -> "unknown"
    end
  end

  defp format_changeset_errors(changeset) do
    Ecto.Changeset.traverse_errors(changeset, fn {msg, opts} ->
      Regex.replace(~r"%{(\w+)}", msg, fn _, key ->
        opts |> Keyword.get(String.to_existing_atom(key), key) |> to_string()
      end)
    end)
  end
end
