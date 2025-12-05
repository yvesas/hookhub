# Script to run this file: mix run priv/repo/seeds.exs

import Ecto.Query
alias Hookhub.Repo
alias Hookhub.Providers.{Provider, ApiKey}
alias Hookhub.Events.Event

# Clear existing data
IO.puts("🧹 Cleaning existing data...")
Repo.delete_all(Event)
Repo.delete_all(ApiKey)
Repo.delete_all(Provider)

# Create providers
IO.puts("📦 Creating providers...")

messageflow =
  Repo.insert!(%Provider{
    name: "MessageFlow",
    description: "Real-time messaging platform"
  })

chatrelay =
  Repo.insert!(%Provider{
    name: "ChatRelay",
    description: "Multi-channel chat relay service"
  })

IO.puts("✅ Created #{Repo.aggregate(Provider, :count)} providers")

# Create API keys
IO.puts("🔑 Creating API keys...")

# Generate keys
messageflow_plain_key = Hookhub.Providers.ApiKey.generate_api_key()
chatrelay_plain_key = Hookhub.Providers.ApiKey.generate_api_key()

# Create changesets and insert
messageflow_changeset =
  %ApiKey{}
  |> ApiKey.generate_key_changeset(%{
    name: "MessageFlow Production",
    provider_id: messageflow.id,
    plain_key: messageflow_plain_key
  })

chatrelay_changeset =
  %ApiKey{}
  |> ApiKey.generate_key_changeset(%{
    name: "ChatRelay Production",
    provider_id: chatrelay.id,
    plain_key: chatrelay_plain_key
  })

Repo.insert!(messageflow_changeset)
Repo.insert!(chatrelay_changeset)

IO.puts("\n" <> String.duplicate("=", 60))
IO.puts("🔐 API KEYS GENERATED - SAVE THESE!")
IO.puts(String.duplicate("=", 60))
IO.puts("MessageFlow API Key: #{messageflow_plain_key}")
IO.puts("ChatRelay API Key:   #{chatrelay_plain_key}")
IO.puts(String.duplicate("=", 60) <> "\n")

# Generate realistic events over the last 30 days
IO.puts("📊 Generating realistic event data (last 30 days)...")

event_types_messageflow = [
  "message.inbound",
  "message.outbound",
  "message.delivered",
  "message.read",
  "user.joined",
  "user.left",
  "typing.started",
  "typing.stopped"
]

event_types_chatrelay = [
  "INCOMING_MESSAGE",
  "OUTGOING_MESSAGE",
  "MESSAGE_DELIVERED",
  "MESSAGE_READ",
  "USER_ONLINE",
  "USER_OFFLINE",
  "CHANNEL_CREATED",
  "CHANNEL_DELETED"
]

platforms = ["WHATSAPP", "TELEGRAM", "SLACK", "DISCORD"]
users = ["Alice", "Bob", "Charlie", "Diana", "Eve", "Frank", "Grace", "Henry"]

# Generate events for last 30 days
now = DateTime.utc_now()
total_events = 500

IO.puts("Generating #{total_events} events...")

Enum.each(1..total_events, fn i ->
  # Random day in last 30 days
  days_ago = :rand.uniform(30)
  hours_ago = :rand.uniform(24)
  minutes_ago = :rand.uniform(60)

  timestamp =
    now
    |> DateTime.add(-days_ago * 24 * 3600, :second)
    |> DateTime.add(-hours_ago * 3600, :second)
    |> DateTime.add(-minutes_ago * 60, :second)
    |> DateTime.truncate(:second)

  # Alternate between providers with slight bias
  provider = if rem(i, 3) == 0, do: chatrelay, else: messageflow

  event_attrs =
    if provider.id == messageflow.id do
      event_type = Enum.random(event_types_messageflow)
      sender = Enum.random(users)
      recipient = Enum.random(users -- [sender])

      %{
        provider_id: provider.id,
        external_event_id: "msg_#{i}_#{:rand.uniform(999_999)}",
        event_type: event_type,
        sender_id: "usr_#{String.downcase(sender)}",
        sender_name: sender,
        recipient_id: "usr_#{String.downcase(recipient)}",
        recipient_name: recipient,
        message_type: if(String.contains?(event_type, "message"), do: "text", else: nil),
        message_body:
          if(String.contains?(event_type, "message"), do: "Sample message #{i}", else: nil),
        platform: "MessageFlow",
        timestamp: timestamp,
        raw_payload: %{
          "event_id" => "msg_#{i}",
          "event_type" => event_type,
          "timestamp" => DateTime.to_iso8601(timestamp),
          "data" => %{
            "sender" => %{"id" => "usr_#{String.downcase(sender)}", "name" => sender},
            "recipient" => %{"id" => "usr_#{String.downcase(recipient)}"},
            "content" => %{"type" => "text", "body" => "Sample message #{i}"}
          }
        },
        inserted_at: timestamp,
        updated_at: timestamp
      }
    else
      event_type = Enum.random(event_types_chatrelay)
      sender = Enum.random(users)
      recipient = Enum.random(users -- [sender])
      platform = Enum.random(platforms)

      %{
        provider_id: provider.id,
        external_event_id: "cr_#{i}_#{:rand.uniform(999_999)}",
        event_type: event_type,
        sender_id: "+5511#{:rand.uniform(900_000_000) + 100_000_000}",
        sender_name: sender,
        recipient_id: "+5511#{:rand.uniform(900_000_000) + 100_000_000}",
        recipient_name: recipient,
        message_type: if(String.contains?(event_type, "MESSAGE"), do: "TEXT", else: nil),
        message_body:
          if(String.contains?(event_type, "MESSAGE"), do: "Sample message #{i}", else: nil),
        platform: platform,
        timestamp: timestamp,
        raw_payload: %{
          "id" => "cr_#{i}",
          "type" => event_type,
          "created_at" => DateTime.to_unix(timestamp),
          "payload" => %{
            "platform" => platform,
            "from" => "+5511#{:rand.uniform(900_000_000) + 100_000_000}",
            "from_name" => sender,
            "to" => "+5511#{:rand.uniform(900_000_000) + 100_000_000}",
            "message" => %{"format" => "TEXT", "text" => "Sample message #{i}"}
          }
        },
        inserted_at: timestamp,
        updated_at: timestamp
      }
    end

  Repo.insert!(struct(Event, event_attrs))

  if rem(i, 50) == 0 do
    IO.write(".")
  end
end)

IO.puts("\n✅ Generated #{Repo.aggregate(Event, :count)} events")

# Summary
IO.puts("\n" <> String.duplicate("=", 60))
IO.puts("📊 SEED DATA SUMMARY")
IO.puts(String.duplicate("=", 60))
IO.puts("Providers: #{Repo.aggregate(Provider, :count)}")
IO.puts("API Keys:  #{Repo.aggregate(ApiKey, :count)}")
IO.puts("Events:    #{Repo.aggregate(Event, :count)}")

# Events by provider
messageflow_count =
  Repo.one(from(e in Event, where: e.provider_id == ^messageflow.id, select: count(e.id)))

chatrelay_count =
  Repo.one(from(e in Event, where: e.provider_id == ^chatrelay.id, select: count(e.id)))

IO.puts("\nEvents by Provider:")
IO.puts("  MessageFlow: #{messageflow_count}")
IO.puts("  ChatRelay:   #{chatrelay_count}")

# Events by type (top 5)
top_types =
  Repo.all(
    from(e in Event,
      group_by: e.event_type,
      select: {e.event_type, count(e.id)},
      order_by: [desc: count(e.id)],
      limit: 5
    )
  )

IO.puts("\nTop Event Types:")

Enum.each(top_types, fn {type, count} ->
  IO.puts("  #{type}: #{count}")
end)

# Date range
{min_date, max_date} =
  Repo.one(
    from(e in Event,
      select: {min(e.timestamp), max(e.timestamp)}
    )
  )

IO.puts("\nDate Range:")
IO.puts("  From: #{Calendar.strftime(min_date, "%Y-%m-%d %H:%M")}")
IO.puts("  To:   #{Calendar.strftime(max_date, "%Y-%m-%d %H:%M")}")

IO.puts(String.duplicate("=", 60))
IO.puts("\n🎉 Seeds completed successfully!")
IO.puts("\n💡 Access the dashboard:")
IO.puts("   http://localhost:4000/dashboard")
IO.puts("   http://localhost:4000/dashboard/analytics")
IO.puts("\n")
