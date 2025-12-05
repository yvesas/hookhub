defmodule Hookhub.Events.Event do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id

  schema "events" do
    field :external_event_id, :string
    field :event_type, :string
    field :timestamp, :utc_datetime

    # Sender information
    field :sender_id, :string
    field :sender_name, :string

    # Recipient information
    field :recipient_id, :string
    field :recipient_name, :string

    # Message content
    field :message_type, :string
    field :message_body, :string

    # Metadata
    field :platform, :string
    field :raw_payload, :map

    belongs_to :provider, Hookhub.Providers.Provider

    timestamps(type: :utc_datetime, updated_at: false)
  end

  @doc false
  def changeset(event, attrs) do
    event
    |> cast(attrs, [
      :provider_id,
      :external_event_id,
      :event_type,
      :timestamp,
      :sender_id,
      :sender_name,
      :recipient_id,
      :recipient_name,
      :message_type,
      :message_body,
      :platform,
      :raw_payload
    ])
    |> validate_required([
      :provider_id,
      :external_event_id,
      :event_type,
      :timestamp,
      :raw_payload
    ])
    |> validate_length(:external_event_id, max: 255)
    |> validate_length(:event_type, max: 100)
    |> foreign_key_constraint(:provider_id)
    |> unique_constraint([:provider_id, :external_event_id],
      name: :events_provider_external_id_unique,
      message: "Event already exists (idempotency)"
    )
  end
end
