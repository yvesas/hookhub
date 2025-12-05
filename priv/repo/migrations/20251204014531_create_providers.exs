defmodule Hookhub.Repo.Migrations.CreateProviders do
  use Ecto.Migration

  def change do
    create table(:providers, primary_key: false) do
      add :id, :uuid, primary_key: true, default: fragment("gen_random_uuid()")
      add :name, :string, size: 100, null: false
      add :description, :text

      timestamps(type: :utc_datetime)
    end

    create unique_index(:providers, [:name])
  end
end
