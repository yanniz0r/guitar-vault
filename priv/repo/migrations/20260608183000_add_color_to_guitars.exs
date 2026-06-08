defmodule GuitarVault.Repo.Migrations.AddColorToGuitars do
  use Ecto.Migration

  def change do
    alter table(:guitars) do
      add :color, :string
    end
  end
end
