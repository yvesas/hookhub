defmodule Hookhub.Providers.Provider do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id

  schema "providers" do
    field :name, :string
    field :description, :string

    has_many :api_keys, Hookhub.Providers.ApiKey
    has_many :events, Hookhub.Events.Event

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(provider, attrs) do
    provider
    |> cast(attrs, [:name, :description])
    |> validate_required([:name])
    |> validate_length(:name, max: 100)
    |> unique_constraint(:name)
  end
end
