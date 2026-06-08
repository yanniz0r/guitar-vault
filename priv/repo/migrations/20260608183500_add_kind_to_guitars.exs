defmodule GuitarVault.Repo.Migrations.AddKindToGuitars do
  use Ecto.Migration

  def change do
    alter table(:guitars) do
      add :kind, :string, null: false, default: "guitar"
    end
  end
end
