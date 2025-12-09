# Run with: mix run scripts/simulate_traffic.exs

defmodule TrafficSimulator do
  alias Hookhub.Repo
  alias Hookhub.Providers.Provider
  alias Hookhub.Providers.ApiKey
  import Ecto.Query

  def run do
    IO.puts("🚀 Starting Traffic Simulation (Elixir)...")

    # 1. Create Simulation Keys
    IO.puts("🔑 Creating Helper Simulation Keys...")
    providers = Repo.all(Provider)

    sim_keys =
      Enum.map(providers, fn provider ->
        raw_key = "sk_sim_#{create_random_string(8)}"
        # Hash it (assuming SHA256 as per standard)
        hash = :crypto.hash(:sha256, raw_key) |> Base.encode16(case: :lower)

        # Clean up old sim keys if any
        # Repo.delete_all(from k in ApiKey, where: k.provider_id == ^provider.id and like(k.key_hash, "sim_%")) # hard to filter by hash

        {:ok, _key} =
          Repo.insert(%ApiKey{
            provider_id: provider.id,
            key_hash: hash,
            key_prefix: "sk_sim",
            name: "Simulation Key - #{DateTime.utc_now()}",
            is_active: true
          })

        IO.puts("   👉 Created key for #{provider.name}: #{raw_key}")
        {provider.name, raw_key}
      end)
      |> Map.new()

    IO.puts("\n📡 Sending webhooks... (Press Ctrl+C to stop)\n")

    # Start loop
    try do
      loop(sim_keys)
    after
      # This might not catch Ctrl+C unless we trap exits, but it's a script.
      # We'll just rely on the user understanding it creates junk keys or run a cleanup manually.
    end
  end

  defp loop(sim_keys) do
    provider_name = Enum.random(Map.keys(sim_keys))
    api_key = Map.get(sim_keys, provider_name)

    payload = generate_payload(provider_name)
    url = "http://localhost:4000/webhooks/ingest"

    # Using :httpc for simplicity in a script to avoid dependency supervision issues if Finch isn't global
    headers = [
      {~c"content-type", ~c"application/json"},
      {~c"x-api-key", String.to_charlist(api_key)}
    ]

    body = Jason.encode!(payload)

    request =
      {String.to_charlist(url), headers, ~c"application/json", body}

    case :httpc.request(:post, request, [], []) do
      {:ok, {{_ver, status, _reason}, _headers, _body}} ->
        icon = if status in [200, 201], do: "✅", else: "❌"

        IO.puts(
          "#{icon} [#{Time.utc_now() |> Time.truncate(:second)}] #{provider_name} -> #{status}"
        )

      {:error, reason} ->
        IO.puts("❌ Request failed: #{inspect(reason)}")
    end

    Process.sleep(Enum.random(200..1500))
    loop(sim_keys)
  end

  defp generate_payload(provider_name) do
    id = System.system_time(:millisecond)

    if String.contains?(String.downcase(provider_name), "messageflow") do
      %{
        id: "evt_#{id}",
        type: "message.inbound",
        created_at: DateTime.utc_now() |> DateTime.to_iso8601(),
        data: %{
          sender: %{id: "usr_#{Enum.random(1..1000)}", name: "Simulated User"},
          recipient: %{id: "usr_support"},
          content: %{type: "text", body: "Simulation message #{id}"}
        }
      }
    else
      %{
        messageId: "msg-#{id}",
        messageType: "text",
        timestamp: System.system_time(:second),
        sender: %{id: "u_#{Enum.random(1..1000)}"},
        content: "Simulation chat #{id}"
      }
    end
  end

  defp create_random_string(length) do
    :crypto.strong_rand_bytes(length) |> Base.encode16(case: :lower)
  end
end

# Find the app name and start enough to run Repo
# Mix.run will start the app.
TrafficSimulator.run()
