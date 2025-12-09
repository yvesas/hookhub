defmodule Hookhub.Providers.ApiKey do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id

  schema "api_keys" do
    field :key_hash, :string
    field :key_prefix, :string
    field :name, :string
    field :is_active, :boolean, default: true
    field :expires_at, :utc_datetime
    field :revoked_at, :utc_datetime

    # Virtual field to hold the plain key (only available on creation)
    field :key, :string, virtual: true

    belongs_to :provider, Hookhub.Providers.Provider

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(api_key, attrs) do
    api_key
    |> cast(attrs, [:provider_id, :name, :is_active, :expires_at, :revoked_at])
    |> validate_required([:provider_id])
    |> validate_length(:name, max: 100)
    |> foreign_key_constraint(:provider_id)
  end

  @doc """
  Generates a new API key and returns a changeset with the key hash and prefix.
  The plain key is stored in the virtual :key field.
  """
  def generate_key_changeset(api_key, attrs) do
    # Generate a random API key
    plain_key = generate_api_key()
    key_hash = hash_key(plain_key)
    key_prefix = String.slice(plain_key, 0, 12)

    api_key
    |> changeset(attrs)
    |> put_change(:key_hash, key_hash)
    |> put_change(:key_prefix, key_prefix)
    |> put_change(:key, plain_key)
  end

  @doc """
  Generates a random API key with format: hh_live_<random_string>
  """
  def generate_api_key do
    random_part =
      :crypto.strong_rand_bytes(32)
      |> Base.encode64(padding: false)
      |> String.replace(~r/[^a-zA-Z0-9]/, "")
      |> String.slice(0, 32)

    "hh_live_#{random_part}"
  end

  @doc """
  Hashes an API key using SHA256
  """
  def hash_key(key) do
    :crypto.hash(:sha256, key)
    |> Base.encode16(case: :lower)
  end

  @doc """
  Verifies if a plain key matches the stored hash
  """
  def verify_key(plain_key, key_hash) do
    hash_key(plain_key) == key_hash
  end
end
