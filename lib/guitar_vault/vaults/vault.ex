defmodule GuitarVault.Vaults.Vault do
  use Ecto.Schema
  import Ecto.Changeset

  alias GuitarVault.Accounts.User
  alias GuitarVault.Vaults.Vaultable

  @moduledoc """
  A vault belongs to a single user and holds many vaultable instruments.
  """

  schema "vaults" do
    field :name, :string

    belongs_to :user, User
    has_many :vaultables, Vaultable

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(vault, attrs) do
    vault
    |> cast(attrs, [:name])
    |> validate_required([:name])
  end
end
