defmodule GuitarVault.Vaults.Event do
  use Ecto.Schema
  import Ecto.Changeset

  alias GuitarVault.Vaults.{Image, Vaultable}

  @moduledoc """
  A dated entry in a vaultable's history, e.g. when it was built, bought,
  modified or sold.
  """

  # All allowed event kinds.
  @kinds ~w(built bought sold modification)

  # Kinds that must occur in this chronological order (by date). Each listed
  # kind's date must fall on or after every earlier-listed kind present on the
  # instrument, and on or before every later-listed kind. Kinds not in this
  # list (e.g. "modification") may be dated freely. Reorder/extend this single
  # list to change the enforced sequence.
  @ordered_kinds ~w(built bought sold)

  # Kinds that may occur at most once per instrument. Add kinds here to make
  # them unique.
  @unique_kinds ~w(built)

  schema "vaultable_events" do
    field :kind, :string
    field :date, :date
    field :description, :string

    belongs_to :vaultable, Vaultable
    has_many :images, Image

    timestamps(type: :utc_datetime)
  end

  @doc "All allowed event kinds."
  def kinds, do: @kinds

  @doc "The kinds subject to chronological ordering, in order."
  def ordered_kinds, do: @ordered_kinds

  @doc false
  def changeset(event, attrs) do
    event
    |> cast(attrs, [:kind, :date, :description])
    |> validate_required([:kind, :date])
    |> validate_inclusion(:kind, @kinds)
    |> maybe_require_description()
  end

  @doc """
  Validates that this event's date respects `ordered_kinds/0` relative to the
  instrument's other events. `siblings` is the list of the instrument's other
  events (the one being changed should not be included).
  """
  def validate_order(changeset, siblings) do
    kind = get_field(changeset, :kind)
    date = get_field(changeset, :date)

    if is_nil(date) or position(kind) == nil do
      changeset
    else
      constrained = Enum.filter(siblings, &(position(&1.kind) != nil))
      pos = position(kind)

      changeset
      |> enforce_after(date, Enum.filter(constrained, &(position(&1.kind) < pos)))
      |> enforce_before(date, Enum.filter(constrained, &(position(&1.kind) > pos)))
    end
  end

  @doc """
  Validates that a `@unique_kinds` event isn't being added when one of the same
  kind already exists. `siblings` is the instrument's other events.
  """
  def validate_uniqueness(changeset, siblings) do
    kind = get_field(changeset, :kind)

    if kind in @unique_kinds and Enum.any?(siblings, &(&1.kind == kind)) do
      add_error(changeset, :kind, "already recorded — only one #{kind} event is allowed")
    else
      changeset
    end
  end

  defp enforce_after(changeset, _date, []), do: changeset

  defp enforce_after(changeset, date, predecessors) do
    latest = Enum.max_by(predecessors, & &1.date, Date)

    if Date.compare(date, latest.date) == :lt do
      add_error(changeset, :date, "must be on or after the #{latest.kind} date (#{latest.date})")
    else
      changeset
    end
  end

  defp enforce_before(changeset, _date, []), do: changeset

  defp enforce_before(changeset, date, successors) do
    earliest = Enum.min_by(successors, & &1.date, Date)

    if Date.compare(date, earliest.date) == :gt do
      add_error(
        changeset,
        :date,
        "must be on or before the #{earliest.kind} date (#{earliest.date})"
      )
    else
      changeset
    end
  end

  defp position(kind), do: Enum.find_index(@ordered_kinds, &(&1 == kind))

  defp maybe_require_description(changeset) do
    if get_field(changeset, :kind) == "modification" do
      validate_required(changeset, [:description])
    else
      changeset
    end
  end
end
