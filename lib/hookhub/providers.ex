defmodule Hookhub.Providers do
  @moduledoc """
  The Providers context.
  Handles provider and API key management.
  """

  import Ecto.Query, warn: false
  alias Hookhub.Repo
  alias Hookhub.Providers.{Provider, ApiKey}

  # Provider functions

  @doc """
  Lists all providers.
  """
  def list_providers do
    Repo.all(Provider)
  end

  @doc """
  Gets a single provider.
  """
  def get_provider(id), do: Repo.get(Provider, id)

  @doc """
  Gets a provider by name.
  """
  def get_provider_by_name(name) do
    Repo.get_by(Provider, name: name)
  end

  # API Key functions

  @doc """
  Lists all API keys with their associated providers.
  Optionally filter by provider_id.
  """
  def list_api_keys(opts \\ []) do
    query = from(k in ApiKey, preload: [:provider])

    query =
      case Keyword.get(opts, :provider_id) do
        nil -> query
        provider_id -> where(query, [k], k.provider_id == ^provider_id)
      end

    Repo.all(query)
  end

  @doc """
  Gets a single API key.
  """
  def get_api_key(id) do
    ApiKey
    |> preload(:provider)
    |> Repo.get(id)
  end

  @doc """
  Creates a new API key for a provider.
  Returns {:ok, api_key} with the plain key in the virtual field.
  """
  def create_api_key(attrs \\ %{}) do
    %ApiKey{}
    |> ApiKey.generate_key_changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Revokes an API key by setting revoked_at timestamp and is_active to false.
  """
  def revoke_api_key(%ApiKey{} = api_key) do
    api_key
    |> Ecto.Changeset.change(%{
      is_active: false,
      revoked_at: DateTime.utc_now()
    })
    |> Repo.update()
  end

  @doc """
  Deletes an API key.
  """
  def delete_api_key(%ApiKey{} = api_key) do
    Repo.delete(api_key)
  end
end
