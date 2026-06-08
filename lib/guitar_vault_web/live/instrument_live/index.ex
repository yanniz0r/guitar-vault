defmodule GuitarVaultWeb.InstrumentLive.Index do
  use GuitarVaultWeb, :live_view

  alias GuitarVault.Vaults

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash} current_scope={@current_scope} max_width="max-w-6xl">
      <.header>
        Your instruments
        <:subtitle>Everything stored in your vault.</:subtitle>
      </.header>

      <div class="flex gap-6">
        <%!-- Master: overview (~1/5) --%>
        <aside class="w-1/5 min-w-44 shrink-0 space-y-3">
          <.link
            patch={~p"/instruments"}
            class={["btn btn-sm w-full", is_nil(@selected) && "btn-primary"]}
          >
            + New
          </.link>

          <nav class="flex flex-col gap-1">
            <.link
              :for={instrument <- @instruments}
              patch={~p"/instruments/#{instrument.id}"}
              class={[
                "rounded-lg px-3 py-2 hover:bg-base-200",
                @selected && @selected.id == instrument.id && "bg-base-200"
              ]}
            >
              <div class="truncate text-sm font-medium">{instrument.name}</div>
              <div class="truncate text-xs opacity-60">
                {instrument.guitar && String.capitalize(instrument.guitar.kind)}
                <span :if={instrument.guitar && instrument.guitar.brand}>
                  · {instrument.guitar.brand}
                </span>
              </div>
            </.link>
          </nav>

          <p :if={@instruments == []} class="text-sm opacity-60">No instruments yet.</p>
        </aside>

        <%!-- Detail (~4/5) --%>
        <section class="w-4/5">
          <%= if @selected do %>
            <.header>
              {@selected.name}
              <:subtitle>{@selected.guitar && String.capitalize(@selected.guitar.kind)}</:subtitle>
              <:actions>
                <.link
                  phx-click={JS.push("delete", value: %{id: @selected.id})}
                  data-confirm="Delete this instrument?"
                  class="btn btn-sm"
                >
                  Delete
                </.link>
              </:actions>
            </.header>

            <.list>
              <:item title="Name">{@selected.name}</:item>
              <:item title="Type">
                {@selected.guitar && String.capitalize(@selected.guitar.kind)}
              </:item>
              <:item title="Brand">{@selected.guitar && @selected.guitar.brand}</:item>
              <:item title="Model">{@selected.guitar && @selected.guitar.model}</:item>
              <:item title="Year">{@selected.guitar && @selected.guitar.year}</:item>
              <:item title="Color">{@selected.guitar && @selected.guitar.color}</:item>
            </.list>
          <% else %>
            <.header>
              Add an instrument
              <:subtitle>Add a guitar or bass to your vault.</:subtitle>
            </.header>

            <.form for={@form} id="instrument-form" phx-change="validate" phx-submit="save">
              <div class="grid grid-cols-1 gap-4 sm:grid-cols-2">
                <.input field={@form[:name]} label="Name" />
                <.inputs_for :let={gf} field={@form[:guitar]}>
                  <.input
                    field={gf[:kind]}
                    type="select"
                    label="Type"
                    options={[{"Guitar", "guitar"}, {"Bass", "bass"}]}
                  />
                  <.input field={gf[:brand]} label="Brand" />
                  <.input field={gf[:model]} label="Model" />
                  <.input field={gf[:year]} type="number" label="Year" />
                  <.input field={gf[:color]} label="Color" />
                </.inputs_for>
              </div>
              <.button phx-disable-with="Adding..." class="btn btn-primary mt-4">
                Add instrument
              </.button>
            </.form>
          <% end %>
        </section>
      </div>
    </Layouts.app>
    """
  end

  @impl true
  def mount(_params, _session, socket) do
    scope = socket.assigns.current_scope

    {:ok,
     socket
     |> assign(:form, to_form(Vaults.change_guitar(), as: "instrument"))
     |> assign(:instruments, Vaults.list_instruments(scope))
     |> assign(:selected, nil)}
  end

  @impl true
  def handle_params(%{"id" => id}, _uri, socket) do
    instrument = Vaults.get_instrument!(socket.assigns.current_scope, id)
    {:noreply, assign(socket, selected: instrument, page_title: instrument.name)}
  end

  def handle_params(_params, _uri, socket) do
    {:noreply, assign(socket, selected: nil, page_title: "Instruments")}
  end

  @impl true
  def handle_event("validate", %{"instrument" => params}, socket) do
    changeset =
      Vaults.change_guitar(Vaults.new_guitar(), params)
      |> Map.put(:action, :validate)

    {:noreply, assign(socket, :form, to_form(changeset, as: "instrument"))}
  end

  def handle_event("save", %{"instrument" => params}, socket) do
    scope = socket.assigns.current_scope

    case Vaults.create_guitar(scope, params) do
      {:ok, instrument} ->
        {:noreply,
         socket
         |> put_flash(:info, "Instrument added to your vault.")
         |> assign(:instruments, Vaults.list_instruments(scope))
         |> assign(:form, to_form(Vaults.change_guitar(), as: "instrument"))
         |> push_patch(to: ~p"/instruments/#{instrument.id}")}

      {:error, changeset} ->
        {:noreply, assign(socket, :form, to_form(changeset, as: "instrument"))}
    end
  end

  def handle_event("delete", %{"id" => id}, socket) do
    scope = socket.assigns.current_scope
    instrument = Vaults.get_instrument!(scope, id)
    {:ok, _} = Vaults.delete_instrument(scope, instrument)

    {:noreply,
     socket
     |> put_flash(:info, "Instrument removed from your vault.")
     |> assign(:instruments, Vaults.list_instruments(scope))
     |> push_patch(to: ~p"/instruments")}
  end
end
