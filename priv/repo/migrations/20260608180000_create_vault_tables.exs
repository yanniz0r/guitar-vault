defmodule GuitarVault.Repo.Migrations.CreateVaultTables do
  use Ecto.Migration

  def change do
    create table(:vaults) do
      add :name, :string, null: false
      add :user_id, references(:users, on_delete: :delete_all), null: false

      timestamps(type: :utc_datetime)
    end

    create unique_index(:vaults, [:user_id])

    create table(:vaultables) do
      add :name, :string, null: false
      add :type, :string, null: false
      add :vault_id, references(:vaults, on_delete: :delete_all), null: false

      timestamps(type: :utc_datetime)
    end

    create index(:vaultables, [:vault_id])

    create table(:guitars) do
      add :vaultable_id, references(:vaultables, on_delete: :delete_all), null: false
      add :model, :string
      add :brand, :string
      add :year, :integer

      timestamps(type: :utc_datetime)
    end

    create unique_index(:guitars, [:vaultable_id])
  end
end
