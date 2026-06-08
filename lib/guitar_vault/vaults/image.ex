defmodule GuitarVault.Vaults.Image do
  use Ecto.Schema
  import Ecto.Changeset

  alias GuitarVault.Vaults.{Event, Vaultable}

  @moduledoc """
  An uploaded image. The binary lives on disk (see `GuitarVault.Uploads`); this
  row stores its location plus metadata. An image belongs to exactly one parent:
  a `Vaultable` or an `Event`.
  """

  schema "images" do
    field :path, :string
    field :description, :string
    field :content_type, :string

    belongs_to :vaultable, Vaultable
    belongs_to :event, Event

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(image, attrs) do
    image
    |> cast(attrs, [:path, :description, :content_type])
    |> validate_required([:path])
    |> validate_exactly_one_parent()
  end

  defp validate_exactly_one_parent(changeset) do
    parents = [get_field(changeset, :vaultable_id), get_field(changeset, :event_id)]

    if Enum.count(parents, &(&1 != nil)) == 1 do
      changeset
    else
      add_error(changeset, :vaultable_id, "image must belong to exactly one parent")
    end
  end

  @doc "Changeset for editing just the user-facing fields (description)."
  def metadata_changeset(image, attrs) do
    cast(image, attrs, [:description])
  end
end
