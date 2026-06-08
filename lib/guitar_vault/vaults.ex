defmodule GuitarVault.Vaults do
  @moduledoc """
  The Vaults context: a user's vault and the instruments stored in it.

  Each user owns a single vault (created on demand). Instruments are
  `Vaultable` records scoped to that vault; guitars extend them. Every public
  function takes the caller's `Scope` first and filters by `scope.user`.
  """

  import Ecto.Query, warn: false
  alias GuitarVault.Repo
  alias GuitarVault.Accounts.Scope
  alias GuitarVault.Uploads
  alias GuitarVault.Vaults.{Event, Guitar, Image, Vault, Vaultable}

  ## Vaults

  @doc "Returns the caller's vault, or nil if they don't have one yet."
  def get_vault(%Scope{user: user}) do
    Repo.get_by(Vault, user_id: user.id)
  end

  @doc "Returns the caller's vault, creating a default one if needed."
  def get_or_create_vault!(%Scope{user: user} = scope) do
    get_vault(scope) ||
      %Vault{user_id: user.id}
      |> Vault.changeset(%{name: "My Vault"})
      |> Repo.insert!()
  end

  ## Instruments

  @doc """
  Lists the instruments in the caller's vault, newest first.

  Pass `search: term` to filter by instrument name, brand or model.
  """
  def list_instruments(%Scope{} = scope, opts \\ []) do
    case get_vault(scope) do
      nil ->
        []

      vault ->
        from(v in Vaultable,
          left_join: g in assoc(v, :guitar),
          where: v.vault_id == ^vault.id,
          order_by: [desc: v.inserted_at],
          preload: [guitar: g]
        )
        |> filter_by_search(opts[:search])
        |> filter_by_sold(opts[:show_sold])
        |> Repo.all()
    end
  end

  defp filter_by_search(query, term) when is_binary(term) do
    case String.trim(term) do
      "" ->
        query

      trimmed ->
        like = "%#{trimmed}%"

        from [v, g] in query,
          where: like(v.name, ^like) or like(g.brand, ^like) or like(g.model, ^like)
    end
  end

  defp filter_by_search(query, _), do: query

  # Returns only instruments currently considered "sold":
  # they have a sold event with no subsequent bought event.
  defp filter_by_sold(query, true) do
    from v in query, where: v.id in subquery(sold_vaultable_ids())
  end

  # Default: hide sold instruments so only currently-owned gear is shown.
  defp filter_by_sold(query, _) do
    from v in query, where: v.id not in subquery(sold_vaultable_ids())
  end

  # Subquery: vaultable_ids for instruments that have a "sold" event
  # with no later "bought" event (i.e. currently sold).
  defp sold_vaultable_ids do
    from e in Event,
      as: :sold_event,
      where: e.kind == "sold",
      where:
        not exists(
          from e2 in Event,
            where:
              e2.vaultable_id == parent_as(:sold_event).vaultable_id and
                e2.kind == "bought" and
                e2.date > parent_as(:sold_event).date
        ),
      select: e.vaultable_id,
      distinct: true
  end

  @doc "Gets a single instrument from the caller's vault. Raises if not found."
  def get_instrument!(%Scope{} = scope, id) do
    vault = get_or_create_vault!(scope)

    Vaultable
    |> where([v], v.vault_id == ^vault.id and v.id == ^id)
    |> Repo.one!()
    |> Repo.preload([:guitar, :images, events: {events_query(), :images}])
  end

  defp events_query do
    from e in Event, order_by: [desc: e.date, desc: e.inserted_at]
  end

  @doc "An empty guitar instrument, for building new forms."
  def new_guitar, do: %Vaultable{guitar: %Guitar{}}

  @doc "Returns a changeset for tracking guitar-instrument form changes."
  def change_guitar(%Vaultable{} = instrument \\ %Vaultable{guitar: %Guitar{}}, attrs \\ %{}) do
    Vaultable.guitar_changeset(instrument, attrs)
  end

  @doc """
  Creates a guitar instrument in the caller's vault.

  Accepts a flat map where `name` is the instrument name and `guitar` holds the
  nested `model`, `brand` and `year` attributes.
  """
  def create_guitar(%Scope{} = scope, attrs \\ %{}) do
    vault = get_or_create_vault!(scope)

    %Vaultable{vault_id: vault.id}
    |> Vaultable.guitar_changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates a guitar instrument in the caller's vault.

  The instrument must already belong to the caller and have its `:guitar`
  preloaded (as returned by `get_instrument!/2`).
  """
  def update_instrument(%Scope{} = scope, %Vaultable{} = instrument, attrs) do
    vault = get_or_create_vault!(scope)
    true = instrument.vault_id == vault.id

    instrument
    |> Vaultable.guitar_changeset(attrs)
    |> Repo.update()
  end

  @doc "Deletes an instrument (and its guitar subtype) from the caller's vault."
  def delete_instrument(%Scope{} = scope, %Vaultable{} = instrument) do
    vault = get_or_create_vault!(scope)
    true = instrument.vault_id == vault.id
    Repo.delete(instrument)
  end

  ## History events

  @doc "Returns a changeset for tracking history-event form changes."
  def change_event(%Event{} = event \\ %Event{}, attrs \\ %{}) do
    Event.changeset(event, attrs)
  end

  @doc "Adds a history event to an instrument in the caller's vault."
  def add_event(%Scope{} = scope, %Vaultable{} = instrument, attrs) do
    vault = get_or_create_vault!(scope)
    true = instrument.vault_id == vault.id

    siblings = Repo.all(from e in Event, where: e.vaultable_id == ^instrument.id)

    %Event{vaultable_id: instrument.id}
    |> Event.changeset(attrs)
    |> Event.validate_order(siblings)
    |> Event.validate_uniqueness(siblings)
    |> Repo.insert()
  end

  @doc "Deletes a history event belonging to the caller's vault."
  def delete_event(%Scope{} = scope, id) do
    scope
    |> scoped_event!(id)
    |> Repo.delete()
  end

  ## Images

  @doc """
  Attaches an already-stored image (see `GuitarVault.Uploads.store/2`) to a
  vaultable or event in the caller's vault.

  `attrs` must include `:path` and may include `:description` and
  `:content_type`.
  """
  def add_image(%Scope{} = scope, %Vaultable{} = instrument, attrs) do
    vault = get_or_create_vault!(scope)
    true = instrument.vault_id == vault.id

    %Image{vaultable_id: instrument.id}
    |> Image.changeset(attrs)
    |> Repo.insert()
  end

  def add_image(%Scope{} = scope, %Event{} = event, attrs) do
    # Verify the event belongs to the caller's vault before attaching.
    _ = scoped_event!(scope, event.id)

    %Image{event_id: event.id}
    |> Image.changeset(attrs)
    |> Repo.insert()
  end

  @doc "Returns a changeset for editing an image's metadata (description)."
  def change_image(%Image{} = image, attrs \\ %{}) do
    Image.metadata_changeset(image, attrs)
  end

  @doc "Updates an image's metadata (e.g. its description)."
  def update_image(%Scope{} = scope, id, attrs) do
    scope
    |> get_image!(id)
    |> Image.metadata_changeset(attrs)
    |> Repo.update()
  end

  @doc "Deletes an image (row and file) belonging to the caller's vault."
  def delete_image(%Scope{} = scope, id) do
    image = get_image!(scope, id)

    with {:ok, image} <- Repo.delete(image) do
      Uploads.delete(image.path)
      {:ok, image}
    end
  end

  defp get_image!(%Scope{} = scope, id) do
    vault = get_or_create_vault!(scope)

    from(i in Image,
      left_join: v in Vaultable,
      on: v.id == i.vaultable_id,
      left_join: ev in Event,
      on: ev.id == i.event_id,
      left_join: evv in Vaultable,
      on: evv.id == ev.vaultable_id,
      where: i.id == ^id and (v.vault_id == ^vault.id or evv.vault_id == ^vault.id)
    )
    |> Repo.one!()
  end

  defp scoped_event!(%Scope{} = scope, id) do
    vault = get_or_create_vault!(scope)

    from(e in Event,
      join: v in Vaultable,
      on: v.id == e.vaultable_id,
      where: e.id == ^id and v.vault_id == ^vault.id
    )
    |> Repo.one!()
  end
end
