defmodule GuitarVaultWeb.InstrumentLive.Index do
  use GuitarVaultWeb, :live_view

  alias GuitarVault.Vaults
  alias GuitarVault.Vaults.Event

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
            class={["btn btn-sm w-full", @live_action == :index && "btn-primary"]}
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
          <%= cond do %>
            <% @live_action == :edit -> %>
              <.header>
                Edit {@selected.name}
                <:subtitle>Update the details of this instrument.</:subtitle>
              </.header>

              <.instrument_form form={@form} submit_label="Save changes">
                <.link patch={~p"/instruments/#{@selected.id}"} class="btn btn-ghost">
                  Cancel
                </.link>
              </.instrument_form>
            <% @selected -> %>
              <.header>
                {@selected.name}
                <:subtitle>
                  {@selected.guitar && String.capitalize(@selected.guitar.kind)}
                </:subtitle>
                <:actions>
                  <.link patch={~p"/instruments/#{@selected.id}/edit"} class="btn btn-sm">
                    Edit
                  </.link>
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

              <div class="mt-8">
                <.header>
                  History
                  <:subtitle>What happened to this instrument over time.</:subtitle>
                </.header>

                <ol class="my-4 space-y-2">
                  <li
                    :for={event <- @selected.events}
                    class="flex items-baseline justify-between gap-4 rounded-lg border border-base-content/10 px-3 py-2"
                  >
                    <div>
                      <span class="font-semibold">{String.capitalize(event.kind)}</span>
                      <span class="text-sm opacity-60">
                        · {Calendar.strftime(event.date, "%b %-d, %Y")}
                      </span>
                      <p :if={event.description} class="text-sm opacity-80">{event.description}</p>
                    </div>
                    <.link
                      phx-click={JS.push("delete_event", value: %{id: event.id})}
                      data-confirm="Delete this history entry?"
                      class="text-sm opacity-60 hover:opacity-100"
                    >
                      Remove
                    </.link>
                  </li>
                </ol>

                <p :if={@selected.events == []} class="text-sm opacity-60">No history yet.</p>

                <.form
                  for={@event_form}
                  id="event-form"
                  phx-change="validate_event"
                  phx-submit="save_event"
                  class="mt-4"
                >
                  <div class="grid grid-cols-1 gap-4 sm:grid-cols-3 sm:items-end">
                    <.input
                      field={@event_form[:kind]}
                      type="select"
                      label="Event"
                      options={Enum.map(Event.kinds(), &{String.capitalize(&1), &1})}
                    />
                    <.input field={@event_form[:date]} type="date" label="Date" />
                    <.input field={@event_form[:description]} label="Description" />
                  </div>
                  <.button phx-disable-with="Adding..." class="btn btn-primary btn-sm mt-4">
                    Add event
                  </.button>
                </.form>
              </div>
            <% true -> %>
              <.header>
                Add an instrument
                <:subtitle>Add a guitar or bass to your vault.</:subtitle>
              </.header>

              <.instrument_form form={@form} submit_label="Add instrument" />
          <% end %>
        </section>
      </div>
    </Layouts.app>
    """
  end

  attr :form, Phoenix.HTML.Form, required: true
  attr :submit_label, :string, required: true
  slot :inner_block, doc: "extra actions rendered next to the submit button"

  defp instrument_form(assigns) do
    ~H"""
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
      <div class="mt-4 flex gap-2">
        <.button phx-disable-with="Saving..." class="btn btn-primary">{@submit_label}</.button>
        {render_slot(@inner_block)}
      </div>
    </.form>
    """
  end

  @impl true
  def mount(_params, _session, socket) do
    scope = socket.assigns.current_scope

    {:ok,
     socket
     |> assign(:instruments, Vaults.list_instruments(scope))
     |> assign(:selected, nil)
     |> assign(:form, new_form())
     |> assign(:event_form, new_event_form())}
  end

  @impl true
  def handle_params(params, _uri, socket) do
    {:noreply, apply_action(socket, socket.assigns.live_action, params)}
  end

  defp apply_action(socket, :index, _params) do
    socket
    |> assign(:selected, nil)
    |> assign(:page_title, "Instruments")
    |> assign(:form, new_form())
  end

  defp apply_action(socket, :show, %{"id" => id}) do
    instrument = Vaults.get_instrument!(socket.assigns.current_scope, id)

    socket
    |> assign(:selected, instrument)
    |> assign(:page_title, instrument.name)
    |> assign(:event_form, new_event_form())
  end

  defp apply_action(socket, :edit, %{"id" => id}) do
    instrument = Vaults.get_instrument!(socket.assigns.current_scope, id)

    socket
    |> assign(:selected, instrument)
    |> assign(:page_title, "Edit #{instrument.name}")
    |> assign(:form, to_form(Vaults.change_guitar(instrument), as: "instrument"))
  end

  @impl true
  def handle_event("validate", %{"instrument" => params}, socket) do
    changeset =
      socket
      |> form_base()
      |> Vaults.change_guitar(params)
      |> Map.put(:action, :validate)

    {:noreply, assign(socket, :form, to_form(changeset, as: "instrument"))}
  end

  def handle_event("save", %{"instrument" => params}, socket) do
    scope = socket.assigns.current_scope

    result =
      case socket.assigns.live_action do
        :edit -> Vaults.update_instrument(scope, socket.assigns.selected, params)
        _ -> Vaults.create_guitar(scope, params)
      end

    case result do
      {:ok, instrument} ->
        {:noreply,
         socket
         |> put_flash(:info, flash_message(socket.assigns.live_action))
         |> assign(:instruments, Vaults.list_instruments(scope))
         |> assign(:form, new_form())
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

  def handle_event("validate_event", %{"event" => params}, socket) do
    changeset =
      %Event{}
      |> Vaults.change_event(params)
      |> Event.validate_order(socket.assigns.selected.events)
      |> Map.put(:action, :validate)

    {:noreply, assign(socket, :event_form, to_form(changeset, as: "event"))}
  end

  def handle_event("save_event", %{"event" => params}, socket) do
    scope = socket.assigns.current_scope

    case Vaults.add_event(scope, socket.assigns.selected, params) do
      {:ok, _event} ->
        instrument = Vaults.get_instrument!(scope, socket.assigns.selected.id)

        {:noreply,
         socket
         |> put_flash(:info, "History updated.")
         |> assign(:selected, instrument)
         |> assign(:event_form, new_event_form())}

      {:error, changeset} ->
        {:noreply, assign(socket, :event_form, to_form(changeset, as: "event"))}
    end
  end

  def handle_event("delete_event", %{"id" => id}, socket) do
    scope = socket.assigns.current_scope
    {:ok, _} = Vaults.delete_event(scope, id)
    instrument = Vaults.get_instrument!(scope, socket.assigns.selected.id)

    {:noreply, assign(socket, :selected, instrument)}
  end

  defp form_base(%{assigns: %{live_action: :edit, selected: selected}}), do: selected
  defp form_base(_socket), do: Vaults.new_guitar()

  defp new_form, do: to_form(Vaults.change_guitar(), as: "instrument")

  defp new_event_form, do: to_form(Vaults.change_event(), as: "event")

  defp flash_message(:edit), do: "Instrument updated."
  defp flash_message(_), do: "Instrument added to your vault."
end
