defmodule GuitarVault.Vaults.Guitar do
  use Ecto.Schema
  import Ecto.Changeset

  alias GuitarVault.Vaults.Vaultable

  @moduledoc """
  A guitar in the vault. Extends `Vaultable` (which carries the shared `name`)
  with the guitar-specific `model`, `brand` and `year` fields.
  """

  schema "guitars" do
    field :model, :string
    field :brand, :string
    field :year, :integer
    field :color, :string
    field :kind, :string, default: "guitar"

    belongs_to :vaultable, Vaultable

    timestamps(type: :utc_datetime)
  end

  @kinds ~w(guitar bass)

  @doc "The available guitar kinds."
  def kinds, do: @kinds

  @doc false
  def changeset(guitar, attrs) do
    guitar
    |> cast(attrs, [:model, :brand, :year, :color, :kind])
    |> validate_required([:brand, :model, :kind])
    |> validate_inclusion(:kind, @kinds)
  end
end
