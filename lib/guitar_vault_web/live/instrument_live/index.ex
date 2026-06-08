defmodule GuitarVaultWeb.InstrumentLive.Index do
  use GuitarVaultWeb, :live_view

  alias GuitarVault.Vaults

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash} current_scope={@current_scope}>
      <.header>
        Your instruments
        <:subtitle>Everything stored in your vault.</:subtitle>
      </.header>

      <.form for={@form} id="instrument-form" phx-change="validate" phx-submit="save">
        <div class="grid grid-cols-1 gap-4 sm:grid-cols-2 lg:grid-cols-5 lg:items-end">
          <.input field={@form[:name]} label="Name" />
          <.inputs_for :let={gf} field={@form[:guitar]}>
            <.input field={gf[:brand]} label="Brand" />
            <.input field={gf[:model]} label="Model" />
            <.input field={gf[:year]} type="number" label="Year" />
          </.inputs_for>
          <.button phx-disable-with="Adding..." class="btn btn-primary">
            Add guitar
          </.button>
        </div>
      </.form>

      <.table id="instruments" rows={@streams.instruments}>
        <:col :let={{_id, instrument}} label="Name">{instrument.name}</:col>
        <:col :let={{_id, instrument}} label="Brand">
          {instrument.guitar && instrument.guitar.brand}
        </:col>
        <:col :let={{_id, instrument}} label="Model">
          {instrument.guitar && instrument.guitar.model}
        </:col>
        <:col :let={{_id, instrument}} label="Year">
          {instrument.guitar && instrument.guitar.year}
        </:col>
        <:action :let={{id, instrument}}>
          <.link
            phx-click={JS.push("delete", value: %{id: instrument.id}) |> hide("##{id}")}
            data-confirm="Delete this instrument?"
          >
            Delete
          </.link>
        </:action>
      </.table>
    </Layouts.app>
    """
  end

  @impl true
  def mount(_params, _session, socket) do
    {:ok,
     socket
     |> assign(:form, to_form(Vaults.change_guitar(), as: "instrument"))
     |> stream(:instruments, Vaults.list_instruments(socket.assigns.current_scope))}
  end

  @impl true
  def handle_event("validate", %{"instrument" => params}, socket) do
    changeset =
      Vaults.change_guitar(Vaults.new_guitar(), params)
      |> Map.put(:action, :validate)

    {:noreply, assign(socket, :form, to_form(changeset, as: "instrument"))}
  end

  def handle_event("save", %{"instrument" => params}, socket) do
    case Vaults.create_guitar(socket.assigns.current_scope, params) do
      {:ok, instrument} ->
        {:noreply,
         socket
         |> put_flash(:info, "Instrument added to your vault.")
         |> stream_insert(:instruments, instrument, at: 0)
         |> assign(:form, to_form(Vaults.change_guitar(), as: "instrument"))}

      {:error, changeset} ->
        {:noreply, assign(socket, :form, to_form(changeset, as: "instrument"))}
    end
  end

  def handle_event("delete", %{"id" => id}, socket) do
    scope = socket.assigns.current_scope
    instrument = Vaults.get_instrument!(scope, id)
    {:ok, _} = Vaults.delete_instrument(scope, instrument)

    {:noreply, stream_delete(socket, :instruments, instrument)}
  end
end
