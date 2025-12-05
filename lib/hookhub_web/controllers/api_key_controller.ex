defmodule HookhubWeb.ApiKeyController do
  use HookhubWeb, :controller

  alias Hookhub.Providers

  @doc """
  POST /api/keys
  Creates a new API key for a provider.
  """
  def create(conn, %{"provider_id" => provider_id} = params) do
    name = Map.get(params, "name", "API Key")

    case Providers.create_api_key(%{provider_id: provider_id, name: name}) do
      {:ok, api_key} ->
        conn
        |> put_status(:created)
        |> json(%{
          status: "success",
          data: %{
            id: api_key.id,
            key: api_key.key,
            key_prefix: api_key.key_prefix,
            name: api_key.name,
            provider_id: api_key.provider_id,
            created_at: api_key.inserted_at
          },
          message: "API key created successfully. Save this key, it won't be shown again."
        })

      {:error, changeset} ->
        conn
        |> put_status(:bad_request)
        |> json(%{
          status: "error",
          message: "Failed to create API key",
          errors: format_changeset_errors(changeset)
        })
    end
  end

  @doc """
  GET /api/keys
  Lists all API keys (with masked values).
  """
  def index(conn, params) do
    provider_id = Map.get(params, "provider_id")
    opts = if provider_id, do: [provider_id: provider_id], else: []

    api_keys = Providers.list_api_keys(opts)

    json(conn, %{
      data: Enum.map(api_keys, &format_api_key/1)
    })
  end

  @doc """
  DELETE /api/keys/:id
  Revokes an API key.
  """
  def delete(conn, %{"id" => id}) do
    case Providers.get_api_key(id) do
      nil ->
        conn
        |> put_status(:not_found)
        |> json(%{error: "API key not found"})

      api_key ->
        case Providers.revoke_api_key(api_key) do
          {:ok, _} ->
            conn
            |> put_status(:ok)
            |> json(%{
              status: "success",
              message: "API key revoked successfully"
            })

          {:error, _} ->
            conn
            |> put_status(:internal_server_error)
            |> json(%{error: "Failed to revoke API key"})
        end
    end
  end

  defp format_api_key(api_key) do
    %{
      id: api_key.id,
      key_prefix: api_key.key_prefix <> "***",
      name: api_key.name,
      provider: %{
        id: api_key.provider.id,
        name: api_key.provider.name
      },
      is_active: api_key.is_active,
      created_at: api_key.inserted_at,
      revoked_at: api_key.revoked_at
    }
  end

  defp format_changeset_errors(changeset) do
    Ecto.Changeset.traverse_errors(changeset, fn {msg, opts} ->
      Regex.replace(~r"%{(\w+)}", msg, fn _, key ->
        opts |> Keyword.get(String.to_existing_atom(key), key) |> to_string()
      end)
    end)
  end
end
