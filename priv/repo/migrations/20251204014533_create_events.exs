defmodule Hookhub.Repo.Migrations.CreateEvents do
  use Ecto.Migration

  def change do
    create table(:events, primary_key: false) do
      add :id, :uuid, primary_key: true, default: fragment("gen_random_uuid()")
      add :provider_id, references(:providers, type: :uuid, on_delete: :restrict), null: false
      add :external_event_id, :string, size: 255, null: false
      add :event_type, :string, size: 100, null: false
      add :timestamp, :utc_datetime, null: false

      # Sender information
      add :sender_id, :string, size: 255
      add :sender_name, :string, size: 255

      # Recipient information
      add :recipient_id, :string, size: 255
      add :recipient_name, :string, size: 255

      # Message content
      add :message_type, :string, size: 50
      add :message_body, :text

      # Metadata
      add :platform, :string, size: 50
      add :raw_payload, :map, null: false

      timestamps(type: :utc_datetime, updated_at: false)
    end

    # Idempotency constraint: prevent duplicate events from same provider
    create unique_index(:events, [:provider_id, :external_event_id],
             name: :events_provider_external_id_unique
           )

    # Performance indexes
    create index(:events, [:provider_id])
    create index(:events, [:event_type])
    create index(:events, [:timestamp])
    create index(:events, [:inserted_at])
  end
end
