defmodule Hookhub.Repo.Migrations.CreateApiKeys do
  use Ecto.Migration

  def change do
    create table(:api_keys, primary_key: false) do
      add :id, :uuid, primary_key: true, default: fragment("gen_random_uuid()")
      add :provider_id, references(:providers, type: :uuid, on_delete: :delete_all), null: false
      add :key_hash, :string, size: 255, null: false
      add :key_prefix, :string, size: 20, null: false
      add :name, :string, size: 100
      add :is_active, :boolean, default: true, null: false
      add :expires_at, :utc_datetime
      add :revoked_at, :utc_datetime

      timestamps(type: :utc_datetime)
    end

    create unique_index(:api_keys, [:key_hash])
    create index(:api_keys, [:provider_id])
    create index(:api_keys, [:is_active])
  end
end
