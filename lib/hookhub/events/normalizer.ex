defmodule Hookhub.Events.Normalizer do
  @moduledoc """
  Normalizes webhook payloads from different providers into a unified schema.
  """

  alias Hookhub.Providers.Provider

  @doc """
  Normalizes a webhook payload based on the provider.
  Returns a map with normalized fields ready for Event changeset.
  """
  def normalize(payload, %Provider{name: "MessageFlow"}) do
    normalize_messageflow(payload)
  end

  def normalize(payload, %Provider{name: "ChatRelay"}) do
    normalize_chatrelay(payload)
  end

  def normalize(_payload, _provider) do
    {:error, :unsupported_provider}
  end

  # MessageFlow normalization
  defp normalize_messageflow(payload) do
    {:ok, timestamp, _} = DateTime.from_iso8601(payload["timestamp"])

    {:ok,
     %{
       external_event_id: payload["event_id"],
       event_type: payload["event_type"],
       timestamp: timestamp,
       sender_id: get_in(payload, ["data", "sender", "id"]),
       sender_name: get_in(payload, ["data", "sender", "name"]),
       recipient_id: get_in(payload, ["data", "recipient", "id"]),
       recipient_name: nil,
       message_type: get_in(payload, ["data", "content", "type"]),
       message_body: get_in(payload, ["data", "content", "body"]),
       platform: "MessageFlow",
       raw_payload: payload
     }}
  rescue
    _ -> {:error, :invalid_payload}
  end

  # ChatRelay normalization
  defp normalize_chatrelay(payload) do
    # Convert Unix timestamp to DateTime
    timestamp = DateTime.from_unix!(payload["created_at"])

    # Normalize event type (INCOMING_MESSAGE -> incoming.message)
    event_type =
      payload["type"]
      |> String.downcase()
      |> String.replace("_", ".")

    {:ok,
     %{
       external_event_id: payload["id"],
       event_type: event_type,
       timestamp: timestamp,
       sender_id: get_in(payload, ["payload", "from"]),
       sender_name: get_in(payload, ["payload", "from_name"]),
       recipient_id: get_in(payload, ["payload", "to"]),
       recipient_name: nil,
       message_type: get_in(payload, ["payload", "message", "format"]) |> normalize_message_type(),
       message_body: get_in(payload, ["payload", "message", "text"]),
       platform: get_in(payload, ["payload", "platform"]),
       raw_payload: payload
     }}
  rescue
    _ -> {:error, :invalid_payload}
  end

  defp normalize_message_type(nil), do: nil
  defp normalize_message_type(type), do: String.downcase(type)
end
