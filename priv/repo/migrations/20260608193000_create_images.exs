defmodule GuitarVault.Repo.Migrations.CreateImages do
  use Ecto.Migration

  def change do
    create table(:images) do
      add :path, :string, null: false
      add :description, :string
      add :content_type, :string
      add :vaultable_id, references(:vaultables, on_delete: :delete_all)
      add :event_id, references(:vaultable_events, on_delete: :delete_all)

      timestamps(type: :utc_datetime)
    end

    create index(:images, [:vaultable_id])
    create index(:images, [:event_id])

    # SQLite can't ALTER TABLE ADD CONSTRAINT, so the "exactly one parent"
    # invariant is enforced in GuitarVault.Vaults.Image's changeset instead.
  end
end
