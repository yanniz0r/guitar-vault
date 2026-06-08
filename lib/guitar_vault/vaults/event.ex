defmodule GuitarVault.Vaults.Event do
  use Ecto.Schema
  import Ecto.Changeset

  alias GuitarVault.Vaults.Vaultable

  @moduledoc """
  A dated entry in a vaultable's history, e.g. when it was built, bought or sold.
  """

  @kinds ~w(built bought sold)

  schema "vaultable_events" do
    field :kind, :string
    field :date, :date
    field :description, :string

    belongs_to :vaultable, Vaultable

    timestamps(type: :utc_datetime)
  end

  @doc "The available event kinds."
  def kinds, do: @kinds

  @doc false
  def changeset(event, attrs) do
    event
    |> cast(attrs, [:kind, :date, :description])
    |> validate_required([:kind, :date])
    |> validate_inclusion(:kind, @kinds)
  end
end
