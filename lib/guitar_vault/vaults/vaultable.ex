defmodule GuitarVault.Vaults.Vaultable do
  use Ecto.Schema
  import Ecto.Changeset

  alias GuitarVault.Vaults.{Event, Guitar, Vault}

  @moduledoc """
  Generic instrument stored in the vault.

  Holds the fields common to every vaultable item (name, type, timestamps),
  belongs to a `Vault`, and is extended by a concrete subtype such as `Guitar`.
  """

  schema "vaultables" do
    field :name, :string
    field :type, :string

    belongs_to :vault, Vault
    has_one :guitar, Guitar, on_replace: :update
    has_many :events, Event

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(vaultable, attrs) do
    vaultable
    |> cast(attrs, [:name, :type])
    |> validate_required([:name, :type])
  end

  @doc """
  Changeset for creating/updating a guitar instrument: casts the shared `name`,
  forces the `type`, and casts the nested guitar-specific fields.
  """
  def guitar_changeset(vaultable, attrs) do
    vaultable
    |> cast(attrs, [:name])
    |> validate_required([:name])
    |> put_change(:type, "guitar")
    |> cast_assoc(:guitar, required: true, with: &Guitar.changeset/2)
  end
end
