defmodule GuitarVault.VaultsTest do
  use GuitarVault.DataCase, async: true

  import GuitarVault.AccountsFixtures

  alias GuitarVault.Vaults
  alias GuitarVault.Vaults.Vaultable

  setup do
    %{scope: user_scope_fixture()}
  end

  describe "create_guitar/2" do
    @valid_attrs %{
      "name" => "Fender Telecaster",
      "guitar" => %{"brand" => "Fender", "model" => "Telecaster", "year" => "2020"}
    }

    test "creates an instrument with its guitar in the caller's vault", %{scope: scope} do
      assert {:ok, %Vaultable{} = instrument} = Vaults.create_guitar(scope, @valid_attrs)

      assert instrument.name == "Fender Telecaster"
      assert instrument.type == "guitar"
      assert instrument.guitar.brand == "Fender"
      assert instrument.guitar.model == "Telecaster"
      assert instrument.guitar.year == 2020

      vault = Vaults.get_vault(scope)
      assert instrument.vault_id == vault.id
    end

    test "auto-creates a single vault and reuses it", %{scope: scope} do
      assert {:ok, _} = Vaults.create_guitar(scope, @valid_attrs)
      assert {:ok, _} = Vaults.create_guitar(scope, @valid_attrs)

      assert [_, _] = Vaults.list_instruments(scope)
    end

    test "returns an error changeset when required fields are missing", %{scope: scope} do
      assert {:error, changeset} = Vaults.create_guitar(scope, %{"name" => "", "guitar" => %{}})
      refute changeset.valid?
    end
  end

  describe "list_instruments/1 and delete_instrument/2" do
    test "lists only the caller's instruments and deletes them", %{scope: scope} do
      other_scope = user_scope_fixture()
      {:ok, mine} = Vaults.create_guitar(scope, %{"name" => "Mine", "guitar" => %{"brand" => "B", "model" => "M"}})
      {:ok, _theirs} = Vaults.create_guitar(other_scope, %{"name" => "Theirs", "guitar" => %{"brand" => "B", "model" => "M"}})

      assert [listed] = Vaults.list_instruments(scope)
      assert listed.id == mine.id

      assert {:ok, _} = Vaults.delete_instrument(scope, mine)
      assert [] = Vaults.list_instruments(scope)
    end
  end
end
