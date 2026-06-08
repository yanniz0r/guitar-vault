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

    test "requires a description for modification events", %{scope: scope, instrument: instrument} do
      assert {:error, changeset} =
               Vaults.add_event(scope, instrument, %{
                 "kind" => "modification",
                 "date" => "2022-01-01"
               })

      assert "can't be blank" in errors_on(changeset).description

      assert {:ok, _} =
               Vaults.add_event(scope, instrument, %{
                 "kind" => "modification",
                 "date" => "2022-01-01",
                 "description" => "new pickups"
               })
    end

    test "enforces built <= bought <= sold ordering by date", %{
      scope: scope,
      instrument: instrument
    } do
      {:ok, _} =
        Vaults.add_event(scope, instrument, %{"kind" => "bought", "date" => "2020-06-15"})

      # built must be on or before the bought date
      assert {:error, changeset} =
               Vaults.add_event(scope, instrument, %{"kind" => "built", "date" => "2021-01-01"})

      assert [msg] = errors_on(changeset).date
      assert msg =~ "on or before the bought date"

      assert {:ok, _} =
               Vaults.add_event(scope, instrument, %{"kind" => "built", "date" => "2019-01-01"})

      # sold must be on or after the bought date
      assert {:error, changeset} =
               Vaults.add_event(scope, instrument, %{"kind" => "sold", "date" => "2020-01-01"})

      assert [msg] = errors_on(changeset).date
      assert msg =~ "on or after the bought date"

      assert {:ok, _} =
               Vaults.add_event(scope, instrument, %{"kind" => "sold", "date" => "2023-03-03"})
    end

    test "allows only one built event per instrument", %{scope: scope, instrument: instrument} do
      assert {:ok, _} =
               Vaults.add_event(scope, instrument, %{"kind" => "built", "date" => "2019-01-01"})

      assert {:error, changeset} =
               Vaults.add_event(scope, instrument, %{"kind" => "built", "date" => "2019-02-02"})

      assert [msg] = errors_on(changeset).kind
      assert msg =~ "only one built event is allowed"

      # other kinds remain unrestricted
      assert {:ok, _} =
               Vaults.add_event(scope, instrument, %{
                 "kind" => "modification",
                 "date" => "2021-01-01",
                 "description" => "setup"
               })
    end

    test "modification events are not constrained by the ordering", %{
      scope: scope,
      instrument: instrument
    } do
      {:ok, _} = Vaults.add_event(scope, instrument, %{"kind" => "built", "date" => "2019-01-01"})
      {:ok, _} = Vaults.add_event(scope, instrument, %{"kind" => "sold", "date" => "2020-01-01"})

      # a modification dated outside the built/sold window is still allowed
      assert {:ok, _} =
               Vaults.add_event(scope, instrument, %{
                 "kind" => "modification",
                 "date" => "2030-01-01",
                 "description" => "refret"
               })
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

  describe "images" do
    setup %{scope: scope} do
      {:ok, instrument} = Vaults.create_guitar(scope, @valid_attrs)
      %{instrument: instrument}
    end

    test "attaches images to a vaultable and to an event", %{scope: scope, instrument: instrument} do
      assert {:ok, img} =
               Vaults.add_image(scope, instrument, %{path: "a.jpg", description: "front"})

      {:ok, event} =
        Vaults.add_event(scope, instrument, %{"kind" => "built", "date" => "2019-01-01"})

      assert {:ok, _} = Vaults.add_image(scope, event, %{path: "b.jpg"})

      reloaded = Vaults.get_instrument!(scope, instrument.id)
      assert [%{path: "a.jpg", description: "front"}] = reloaded.images
      assert [%{images: [%{path: "b.jpg"}]}] = reloaded.events

      assert {:ok, updated} = Vaults.update_image(scope, img.id, %{"description" => "back"})
      assert updated.description == "back"
    end

    test "delete_image removes the row and is scoped to the vault", %{
      scope: scope,
      instrument: instrument
    } do
      {:ok, img} = Vaults.add_image(scope, instrument, %{path: "a.jpg"})

      other_scope = user_scope_fixture()
      assert_raise Ecto.NoResultsError, fn -> Vaults.delete_image(other_scope, img.id) end

      assert {:ok, _} = Vaults.delete_image(scope, img.id)
      assert Vaults.get_instrument!(scope, instrument.id).images == []
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

    test "search filters by name, brand or model", %{scope: scope} do
      {:ok, _} =
        Vaults.create_guitar(scope, %{
          "name" => "Red Tele",
          "guitar" => %{"brand" => "Fender", "model" => "Telecaster"}
        })

      {:ok, _} =
        Vaults.create_guitar(scope, %{
          "name" => "Blue One",
          "guitar" => %{"brand" => "Gibson", "model" => "Les Paul"}
        })

      assert [%{name: "Red Tele"}] = Vaults.list_instruments(scope, search: "tele")
      assert [%{name: "Blue One"}] = Vaults.list_instruments(scope, search: "gibson")
      assert [%{name: "Blue One"}] = Vaults.list_instruments(scope, search: "paul")
      assert length(Vaults.list_instruments(scope, search: "")) == 2
      assert Vaults.list_instruments(scope, search: "zzz") == []
    end
  end
end
