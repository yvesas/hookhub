defmodule HookhubWeb.Plugs.ApiKeyAuth do
  @moduledoc """
  Plug for authenticating requests using API keys.
  Validates the API key from the X-API-Key header and loads the associated provider.
  """
  import Plug.Conn
  import Phoenix.Controller

  alias Hookhub.Repo
  alias Hookhub.Providers.ApiKey

  def init(opts), do: opts

  def call(conn, _opts) do
    with {:ok, api_key} <- get_api_key(conn),
         {:ok, key_record} <- validate_api_key(api_key) do
      # Load the provider association
      key_record = Repo.preload(key_record, :provider)

      # Store provider in conn assigns for use in controllers
      assign(conn, :current_provider, key_record.provider)
    else
      {:error, :missing_key} ->
        conn
        |> put_status(:unauthorized)
        |> put_view(json: HookhubWeb.ErrorJSON)
        |> render(:"401", message: "Missing API key")
        |> halt()

      {:error, :invalid_key} ->
        conn
        |> put_status(:unauthorized)
        |> put_view(json: HookhubWeb.ErrorJSON)
        |> render(:"401", message: "Invalid API key")
        |> halt()

      {:error, :inactive_key} ->
        conn
        |> put_status(:forbidden)
        |> put_view(json: HookhubWeb.ErrorJSON)
        |> render(:"403", message: "API key is inactive or revoked")
        |> halt()

      {:error, :expired_key} ->
        conn
        |> put_status(:forbidden)
        |> put_view(json: HookhubWeb.ErrorJSON)
        |> render(:"403", message: "API key has expired")
        |> halt()
    end
  end

  defp get_api_key(conn) do
    case get_req_header(conn, "x-api-key") do
      [key | _] when is_binary(key) and byte_size(key) > 0 ->
        {:ok, key}

      _ ->
        {:error, :missing_key}
    end
  end

  defp validate_api_key(plain_key) do
    key_hash = ApiKey.hash_key(plain_key)

    case Repo.get_by(ApiKey, key_hash: key_hash) do
      nil ->
        {:error, :invalid_key}

      key_record ->
        cond do
          not key_record.is_active ->
            {:error, :inactive_key}

          key_record.revoked_at != nil ->
            {:error, :inactive_key}

          key_record.expires_at != nil and
              DateTime.compare(key_record.expires_at, DateTime.utc_now()) == :lt ->
            {:error, :expired_key}

          true ->
            {:ok, key_record}
        end
    end
  end
end
