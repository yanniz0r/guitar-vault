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

  describe "update_instrument/3" do
    test "updates the instrument name and nested guitar fields", %{scope: scope} do
      {:ok, instrument} = Vaults.create_guitar(scope, @valid_attrs)

      assert {:ok, updated} =
               Vaults.update_instrument(scope, instrument, %{
                 "name" => "Renamed",
                 "guitar" => %{"brand" => "Gibson", "model" => "Les Paul", "kind" => "bass"}
               })

      assert updated.name == "Renamed"
      assert updated.guitar.brand == "Gibson"
      assert updated.guitar.kind == "bass"
      # same underlying records, not duplicates
      assert updated.id == instrument.id
      assert [_] = Vaults.list_instruments(scope)
    end

    test "returns an error changeset on invalid data", %{scope: scope} do
      {:ok, instrument} = Vaults.create_guitar(scope, @valid_attrs)

      assert {:error, changeset} =
               Vaults.update_instrument(scope, instrument, %{"name" => ""})

      refute changeset.valid?
    end
  end

  describe "history events" do
    setup %{scope: scope} do
      {:ok, instrument} = Vaults.create_guitar(scope, @valid_attrs)
      %{instrument: instrument}
    end

    test "adds events and exposes them newest-first on the instrument", %{
      scope: scope,
      instrument: instrument
    } do
      assert {:ok, _} =
               Vaults.add_event(scope, instrument, %{"kind" => "built", "date" => "2018-01-01"})

      assert {:ok, _} =
               Vaults.add_event(scope, instrument, %{
                 "kind" => "bought",
                 "date" => "2020-05-02",
                 "description" => "from a friend"
               })

      reloaded = Vaults.get_instrument!(scope, instrument.id)
      assert [first, second] = reloaded.events
      assert first.kind == "bought"
      assert first.description == "from a friend"
      assert second.kind == "built"
    end

    test "rejects unknown kinds and missing dates", %{scope: scope, instrument: instrument} do
      assert {:error, changeset} =
               Vaults.add_event(scope, instrument, %{"kind" => "lost", "date" => nil})

      refute changeset.valid?
    end

    test "deletes an event scoped to the caller's vault", %{scope: scope, instrument: instrument} do
      {:ok, event} =
        Vaults.add_event(scope, instrument, %{"kind" => "sold", "date" => "2021-09-09"})

      assert {:ok, _} = Vaults.delete_event(scope, event.id)
      assert Vaults.get_instrument!(scope, instrument.id).events == []

      other_scope = user_scope_fixture()
      assert_raise Ecto.NoResultsError, fn -> Vaults.delete_event(other_scope, event.id) end
    end
  end

  describe "list_instruments/1 and delete_instrument/2" do
    test "lists only the caller's instruments and deletes them", %{scope: scope} do
      other_scope = user_scope_fixture()

      {:ok, mine} =
        Vaults.create_guitar(scope, %{
          "name" => "Mine",
          "guitar" => %{"brand" => "B", "model" => "M"}
        })

      {:ok, _theirs} =
        Vaults.create_guitar(other_scope, %{
          "name" => "Theirs",
          "guitar" => %{"brand" => "B", "model" => "M"}
        })

      assert [listed] = Vaults.list_instruments(scope)
      assert listed.id == mine.id

      assert {:ok, _} = Vaults.delete_instrument(scope, mine)
      assert [] = Vaults.list_instruments(scope)
    end
  end
end
