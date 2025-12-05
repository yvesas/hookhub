defmodule Hookhub.Telemetry do
  @moduledoc """
  Telemetry supervisor for metrics and monitoring.

  Collects metrics for:
  - Webhook ingestion (count, duration, errors)
  - Database queries
  - HTTP requests
  """
  use Supervisor
  import Telemetry.Metrics

  def start_link(arg) do
    Supervisor.start_link(__MODULE__, arg, name: __MODULE__)
  end

  @impl true
  def init(_arg) do
    children = [
      # Telemetry poller will execute the given period measurements
      {:telemetry_poller, measurements: periodic_measurements(), period: 10_000}
    ]

    Supervisor.init(children, strategy: :one_for_one)
  end

  def metrics do
    [
      # Phoenix Metrics
      summary("phoenix.endpoint.stop.duration",
        unit: {:native, :millisecond},
        tags: [:route],
        tag_values: &get_route_tag/1
      ),
      summary("phoenix.router.dispatch.stop.duration",
        tags: [:route],
        unit: {:native, :millisecond}
      ),

      # Database Metrics
      summary("hookhub.repo.query.total_time",
        unit: {:native, :millisecond},
        description: "Total time spent executing database queries"
      ),
      summary("hookhub.repo.query.decode_time",
        unit: {:native, :millisecond},
        description: "Time spent decoding database results"
      ),
      summary("hookhub.repo.query.query_time",
        unit: {:native, :millisecond},
        description: "Time spent executing the query"
      ),
      summary("hookhub.repo.query.queue_time",
        unit: {:native, :millisecond},
        description: "Time spent waiting for a database connection"
      ),
      summary("hookhub.repo.query.idle_time",
        unit: {:native, :millisecond},
        description: "Time the connection spent waiting before being checked out"
      ),

      # Custom Webhook Metrics
      counter("hookhub.webhook.ingest.count",
        tags: [:provider, :event_type],
        description: "Total number of webhooks ingested"
      ),
      summary("hookhub.webhook.ingest.duration",
        unit: {:native, :millisecond},
        tags: [:provider, :event_type],
        description: "Time spent processing webhooks"
      ),
      counter("hookhub.webhook.ingest.error",
        tags: [:provider, :error_type],
        description: "Number of webhook ingestion errors"
      ),
      counter("hookhub.webhook.duplicate.count",
        tags: [:provider],
        description: "Number of duplicate webhooks (idempotency)"
      ),

      # VM Metrics
      summary("vm.memory.total", unit: {:byte, :kilobyte}),
      summary("vm.total_run_queue_lengths.total"),
      summary("vm.total_run_queue_lengths.cpu"),
      summary("vm.total_run_queue_lengths.io")
    ]
  end

  defp periodic_measurements do
    [
      # A module, function and arguments to be invoked periodically.
      {__MODULE__, :dispatch_stats, []}
    ]
  end

  def dispatch_stats do
    # Dispatch custom metrics here if needed
    :ok
  end

  defp get_route_tag(metadata) do
    case metadata do
      %{conn: %{request_path: path}} -> %{route: path}
      _ -> %{route: "unknown"}
    end
  end
end
