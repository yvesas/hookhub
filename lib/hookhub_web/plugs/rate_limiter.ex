defmodule HookhubWeb.Plugs.RateLimiter do
  @moduledoc """
  Rate limiting plug using Hammer.

  Limits:
  - Webhook ingestion: 1000 requests/minute per API key
  - API queries: 100 requests/minute per IP
  - API key management: 10 requests/minute per IP
  """
  import Plug.Conn
  require Logger

  @webhook_limit 1000
  @api_limit 100
  @admin_limit 10
  # 1 minute in milliseconds
  @time_window 60_000

  def init(opts), do: opts

  def call(conn, opts) do
    limit_type = Keyword.get(opts, :type, :api)

    case check_rate_limit(conn, limit_type) do
      {:allow, count} ->
        conn
        |> put_resp_header("x-ratelimit-limit", to_string(get_limit(limit_type)))
        |> put_resp_header("x-ratelimit-remaining", to_string(get_limit(limit_type) - count))

      {:deny, retry_after} ->
        Logger.warning("Rate limit exceeded",
          ip: get_ip(conn),
          path: conn.request_path,
          limit_type: limit_type
        )

        conn
        |> put_resp_header("retry-after", to_string(retry_after))
        |> put_resp_header("x-ratelimit-limit", to_string(get_limit(limit_type)))
        |> put_resp_header("x-ratelimit-remaining", "0")
        |> send_resp(
          429,
          Jason.encode!(%{
            error: "Rate limit exceeded",
            message: "Too many requests. Please try again later.",
            retry_after: retry_after
          })
        )
        |> halt()
    end
  end

  defp check_rate_limit(conn, limit_type) do
    key = get_rate_limit_key(conn, limit_type)
    limit = get_limit(limit_type)

    case Hammer.check_rate(key, @time_window, limit) do
      {:allow, count} ->
        {:allow, count}

      {:deny, _limit} ->
        # Calculate retry_after in seconds
        retry_after = div(@time_window, 1000)
        {:deny, retry_after}
    end
  end

  defp get_rate_limit_key(conn, :webhook) do
    # Use API key for webhook rate limiting
    api_key = get_req_header(conn, "x-api-key") |> List.first()
    "webhook:#{api_key}"
  end

  defp get_rate_limit_key(conn, :api) do
    # Use IP for API rate limiting
    ip = get_ip(conn)
    "api:#{ip}"
  end

  defp get_rate_limit_key(conn, :admin) do
    # Use IP for admin operations
    ip = get_ip(conn)
    "admin:#{ip}"
  end

  defp get_limit(:webhook), do: @webhook_limit
  defp get_limit(:api), do: @api_limit
  defp get_limit(:admin), do: @admin_limit

  defp get_ip(conn) do
    case get_req_header(conn, "x-forwarded-for") do
      [ip | _] ->
        ip

      [] ->
        case conn.remote_ip do
          {a, b, c, d} -> "#{a}.#{b}.#{c}.#{d}"
          ip -> to_string(ip)
        end
    end
  end
end
