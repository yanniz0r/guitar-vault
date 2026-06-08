defmodule GuitarVault.Repo.Migrations.CreateVaultableEvents do
  use Ecto.Migration

  def change do
    create table(:vaultable_events) do
      add :kind, :string, null: false
      add :date, :date, null: false
      add :description, :text
      add :vaultable_id, references(:vaultables, on_delete: :delete_all), null: false

      timestamps(type: :utc_datetime)
    end

    create index(:vaultable_events, [:vaultable_id])
  end
end
