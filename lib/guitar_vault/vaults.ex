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
  alias GuitarVault.Vaults.{Guitar, Vault, Vaultable}

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

  @doc "Lists the instruments in the caller's vault, newest first."
  def list_instruments(%Scope{} = scope) do
    case get_vault(scope) do
      nil ->
        []

      vault ->
        Vaultable
        |> where([v], v.vault_id == ^vault.id)
        |> order_by([v], desc: v.inserted_at)
        |> Repo.all()
        |> Repo.preload(:guitar)
    end
  end

  @doc "Gets a single instrument from the caller's vault. Raises if not found."
  def get_instrument!(%Scope{} = scope, id) do
    vault = get_or_create_vault!(scope)

    Vaultable
    |> where([v], v.vault_id == ^vault.id and v.id == ^id)
    |> Repo.one!()
    |> Repo.preload(:guitar)
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
end
