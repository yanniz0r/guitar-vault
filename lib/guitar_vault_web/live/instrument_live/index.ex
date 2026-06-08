defmodule GuitarVaultWeb.InstrumentLive.Index do
  use GuitarVaultWeb, :live_view

  alias GuitarVault.Uploads
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
            patch={~p"/instruments?#{q_params(@search, @show_sold)}"}
            class={["btn btn-sm w-full", @live_action == :index && "btn-primary"]}
          >
            + New
          </.link>

          <form phx-change="search" phx-submit="search">
            <input
              type="text"
              name="q"
              value={@search}
              placeholder="Search…"
              phx-debounce="200"
              autocomplete="off"
              class="input input-sm input-bordered w-full"
            />
          </form>

          <label class="flex cursor-pointer items-center gap-2 rounded-lg px-3 py-2 text-sm hover:bg-base-200">
            <input
              type="checkbox"
              phx-click="toggle_sold"
              checked={@show_sold}
              class="h-4 w-4 rounded border-base-content/30 accent-primary"
            />
            Show sold gear
          </label>

          <nav class="flex flex-col gap-1">
            <.link
              :for={instrument <- @instruments}
              patch={~p"/instruments/#{instrument.id}?#{q_params(@search, @show_sold)}"}
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

          <p :if={@instruments == []} class="text-sm opacity-60">
            <%= cond do %>
              <% @show_sold -> %>Sold gear shows up here.
              <% @search != "" -> %>No matches.
              <% true -> %>No instruments yet.
            <% end %>
          </p>
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
                <.link
                  patch={~p"/instruments/#{@selected.id}?#{q_params(@search, @show_sold)}"}
                  class="btn btn-ghost"
                >
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
                  <.link
                    patch={~p"/instruments/#{@selected.id}/edit?#{q_params(@search, @show_sold)}"}
                    class="btn btn-sm"
                  >
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
                  Images
                  <:subtitle>Photos of this instrument.</:subtitle>
                </.header>

                <div
                  :if={@selected.images != []}
                  class="my-4 grid grid-cols-2 gap-4 sm:grid-cols-3"
                >
                  <figure
                    :for={image <- @selected.images}
                    class="space-y-2 rounded-lg border border-base-content/10 p-2"
                  >
                    <img
                      src={Uploads.url(image.path)}
                      alt={image.description}
                      class="aspect-square w-full rounded object-cover"
                    />
                    <form phx-submit="update_image" class="flex gap-2">
                      <input type="hidden" name="image_id" value={image.id} />
                      <input
                        type="text"
                        name="description"
                        value={image.description}
                        placeholder="Add a description"
                        class="input input-sm input-bordered w-full"
                      />
                      <.button type="submit" class="btn btn-sm">Save</.button>
                    </form>
                    <.link
                      phx-click={JS.push("delete_image", value: %{id: image.id})}
                      data-confirm="Delete this image?"
                      class="text-sm opacity-60 hover:opacity-100"
                    >
                      Delete
                    </.link>
                  </figure>
                </div>

                <p :if={@selected.images == []} class="text-sm opacity-60">No images yet.</p>

                <form
                  id="upload-form"
                  phx-submit="save_images"
                  phx-change="validate_upload"
                  class="mt-4 space-y-3"
                >
                  <.live_file_input upload={@uploads.images} />

                  <div :if={@uploads.images.entries != []} class="flex flex-wrap gap-3">
                    <div :for={entry <- @uploads.images.entries} class="space-y-1">
                      <.live_img_preview entry={entry} class="size-20 rounded object-cover" />
                      <button
                        type="button"
                        phx-click="cancel_upload"
                        phx-value-ref={entry.ref}
                        class="block text-xs opacity-60 hover:opacity-100"
                      >
                        Cancel
                      </button>
                      <p
                        :for={err <- upload_errors(@uploads.images, entry)}
                        class="text-xs text-error"
                      >
                        {upload_error_to_string(err)}
                      </p>
                    </div>
                  </div>

                  <p :for={err <- upload_errors(@uploads.images)} class="text-xs text-error">
                    {upload_error_to_string(err)}
                  </p>

                  <.button type="submit" class="btn btn-primary btn-sm">Upload images</.button>
                </form>
              </div>

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
                      <p :if={event.price_cents} class="text-sm opacity-80">
                        {format_price(event.price_cents, event.currency)}
                        <span :if={event.counterparty}>· {event.counterparty}</span>
                      </p>
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

                    <.input
                      :if={money_kind?(@event_form)}
                      field={@event_form[:price]}
                      type="number"
                      step="0.01"
                      min="0"
                      label="Price"
                    />
                    <.input
                      :if={money_kind?(@event_form)}
                      field={@event_form[:currency]}
                      type="select"
                      label="Currency"
                      options={~w(EUR USD GBP)}
                    />
                    <.input
                      :if={money_kind?(@event_form)}
                      field={@event_form[:counterparty]}
                      label="Seller / buyer"
                    />
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
    {:ok,
     socket
     |> assign(:search, "")
     |> assign(:show_sold, false)
     |> assign(:current_path, ~p"/instruments")
     |> assign_instruments()
     |> assign(:selected, nil)
     |> assign(:form, new_form())
     |> assign(:event_form, new_event_form())
     |> allow_upload(:images,
       accept: ~w(.jpg .jpeg .png .webp),
       max_entries: 8,
       max_file_size: 10_000_000
     )}
  end

  @impl true
  def handle_params(params, uri, socket) do
    socket =
      socket
      |> assign(:search, params["q"] || "")
      |> assign(:show_sold, params["sold"] == "true")
      |> assign(:current_path, URI.parse(uri).path)
      |> assign_instruments()

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
         |> assign_instruments()
         |> assign(:form, new_form())
|> push_patch(to: ~p"/instruments/#{instrument.id}?#{q_params(socket.assigns.search, socket.assigns.show_sold)}")}

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
     |> assign_instruments()
     |> push_patch(to: ~p"/instruments?#{q_params(socket.assigns.search, socket.assigns.show_sold)}")}
  end

  def handle_event("search", %{"q" => q}, socket) do
    params = q_params(q, socket.assigns.show_sold)
    {:noreply, push_patch(socket, to: ~p"/instruments?#{params}", replace: true)}
  end

  def handle_event("toggle_sold", _params, socket) do
    new_show_sold = !socket.assigns.show_sold
    params = q_params(socket.assigns.search, new_show_sold)
    {:noreply, push_patch(socket, to: ~p"/instruments?#{params}", replace: true)}
  end

  def handle_event("validate_event", %{"event" => params}, socket) do
    changeset =
      %Event{}
      |> Vaults.change_event(params)
      |> Event.validate_order(socket.assigns.selected.events)
      |> Event.validate_uniqueness(socket.assigns.selected.events)
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

  def handle_event("validate_upload", _params, socket) do
    {:noreply, socket}
  end

  def handle_event("cancel_upload", %{"ref" => ref}, socket) do
    {:noreply, cancel_upload(socket, :images, ref)}
  end

  def handle_event("save_images", _params, socket) do
    scope = socket.assigns.current_scope
    instrument = socket.assigns.selected

    uploaded =
      consume_uploaded_entries(socket, :images, fn %{path: path}, entry ->
        filename = Uploads.store(path, entry.client_name)
        {:ok, %{path: filename, content_type: entry.client_type}}
      end)

    for attrs <- uploaded do
      {:ok, _image} = Vaults.add_image(scope, instrument, attrs)
    end

    socket =
      if uploaded == [] do
        socket
      else
        socket
        |> put_flash(:info, "#{length(uploaded)} image(s) uploaded.")
        |> assign(:selected, Vaults.get_instrument!(scope, instrument.id))
      end

    {:noreply, socket}
  end

  def handle_event("update_image", %{"image_id" => id, "description" => description}, socket) do
    scope = socket.assigns.current_scope
    {:ok, _image} = Vaults.update_image(scope, id, %{"description" => description})

    {:noreply,
     socket
     |> put_flash(:info, "Image updated.")
     |> assign(:selected, Vaults.get_instrument!(scope, socket.assigns.selected.id))}
  end

  def handle_event("delete_image", %{"id" => id}, socket) do
    scope = socket.assigns.current_scope
    {:ok, _} = Vaults.delete_image(scope, id)

    {:noreply,
     assign(socket, :selected, Vaults.get_instrument!(scope, socket.assigns.selected.id))}
  end

  defp form_base(%{assigns: %{live_action: :edit, selected: selected}}), do: selected
  defp form_base(_socket), do: Vaults.new_guitar()

  defp assign_instruments(socket) do
    instruments =
      Vaults.list_instruments(socket.assigns.current_scope,
        search: socket.assigns.search,
        show_sold: socket.assigns.show_sold
      )

    assign(socket, :instruments, instruments)
  end

  # Query params for verified-route links, omitting blank/false values.
  defp q_params(search, show_sold) do
    []
    |> then(fn p -> if search != "", do: [{:q, search} | p], else: p end)
    |> then(fn p -> if show_sold, do: [{:sold, "true"} | p], else: p end)
  end

  # Whether the event form's current kind carries a price.
  defp money_kind?(form), do: form[:kind].value in ~w(bought sold)

  # Format integer cents as "<CUR> <major>.<minor>" without touching floats.
  defp format_price(cents, currency) do
    minor = rem(cents, 100) |> Integer.to_string() |> String.pad_leading(2, "0")
    "#{currency} #{div(cents, 100)}.#{minor}"
  end

  defp new_form, do: to_form(Vaults.change_guitar(), as: "instrument")

  defp new_event_form, do: to_form(Vaults.change_event(), as: "event")

  defp flash_message(:edit), do: "Instrument updated."
  defp flash_message(_), do: "Instrument added to your vault."

  defp upload_error_to_string(:too_large), do: "File is too large (max 10 MB)."
  defp upload_error_to_string(:too_many_files), do: "Too many files (max 8)."
  defp upload_error_to_string(:not_accepted), do: "Unsupported file type."
  defp upload_error_to_string(_), do: "Invalid file."
end
