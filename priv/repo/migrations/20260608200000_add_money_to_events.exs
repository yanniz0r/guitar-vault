defmodule GuitarVault.Repo.Migrations.AddMoneyToEvents do
  use Ecto.Migration

  def change do
    alter table(:vaultable_events) do
      add :price_cents, :integer
      add :currency, :string
      add :counterparty, :string
    end
  end
end
