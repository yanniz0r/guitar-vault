defmodule GuitarVaultWeb.InstrumentLive.Index do
  use GuitarVaultWeb, :live_view

  alias GuitarVault.Uploads
  alias GuitarVault.Vaults
  alias GuitarVault.Vaults.Event

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash} current_scope={@current_scope} max_width="max-w-7xl">
      <%!-- Masthead --%>
      <div class="mb-10 border-b-2 border-base-content/15 pb-6">
        <p class="text-[10px] font-black uppercase tracking-[0.4em] text-primary">
          Your Collection
        </p>
        <h1 class="mt-1 text-5xl font-black leading-none tracking-tight">The Vault</h1>
      </div>

      <div class="flex gap-10">
        <%!-- ═══ Sidebar ═══ --%>
        <aside class="w-72 shrink-0 space-y-5">
          <.link
            patch={~p"/instruments?#{q_params(@search, @show_sold)}"}
            class={[
              "block w-full border-2 border-primary py-3 text-center text-xs font-black uppercase tracking-[0.25em] transition-colors hover:bg-primary hover:text-primary-content",
              @live_action == :index && "bg-primary text-primary-content"
            ]}
          >
            ＋ New Instrument
          </.link>

          <form phx-change="search" phx-submit="search">
            <div class="relative">
              <.icon
                name="hero-magnifying-glass"
                class="absolute left-0 top-1/2 h-4 w-4 -translate-y-1/2 opacity-40"
              />
              <input
                type="text"
                name="q"
                value={@search}
                placeholder="Search…"
                phx-debounce="200"
                autocomplete="off"
                class="w-full border-0 border-b-2 border-base-content/20 bg-transparent pb-2 pl-6 text-sm placeholder:opacity-40 focus:border-primary focus:outline-none"
              />
            </div>
          </form>

          <label class="flex cursor-pointer items-center gap-2 text-sm opacity-50 transition-opacity hover:opacity-100">
            <input
              type="checkbox"
              phx-click="toggle_sold"
              checked={@show_sold}
              class="h-4 w-4 accent-primary"
            />
            Show sold gear
          </label>

          <nav class="border-t-2 border-base-content/15">
            <.link
              :for={instrument <- @instruments}
              patch={~p"/instruments/#{instrument.id}?#{q_params(@search, @show_sold)}"}
              class={[
                "block border-b border-base-content/10 py-4 pl-0 pr-2 transition-all duration-150 hover:pl-3",
                @selected && @selected.id == instrument.id &&
                  "border-l-4 border-l-primary bg-primary/5 pl-3"
              ]}
            >
              <div class="truncate font-bold leading-snug">{instrument.name}</div>
              <div class="mt-0.5 truncate text-xs opacity-40">
                {instrument.guitar && String.capitalize(instrument.guitar.kind)}
                <span :if={instrument.guitar && instrument.guitar.brand}>
                  · {instrument.guitar.brand}
                </span>
              </div>
            </.link>
          </nav>

          <p :if={@instruments == []} class="pt-2 text-sm italic opacity-40">
            <%= cond do %>
              <% @show_sold -> %>No sold gear recorded.
              <% @search != "" -> %>Nothing matches.
              <% true -> %>Your vault is empty.
            <% end %>
          </p>
        </aside>

        <%!-- ═══ Detail panel ═══ --%>
        <section class="min-w-0 flex-1">
          <%= cond do %>
            <%!-- ── Edit form ── --%>
            <% @live_action == :edit -> %>
              <div class="mb-6 border-b-2 border-base-content/15 pb-4">
                <p class="text-[10px] font-black uppercase tracking-[0.4em] text-primary opacity-70">
                  Editing
                </p>
                <h2 class="mt-1 text-3xl font-black tracking-tight">{@selected.name}</h2>
              </div>

              <.instrument_form form={@form} submit_label="Save changes">
                <.link
                  patch={~p"/instruments/#{@selected.id}?#{q_params(@search, @show_sold)}"}
                  class="btn btn-ghost rounded-none font-bold uppercase tracking-wider"
                >
                  Cancel
                </.link>
              </.instrument_form>

            <%!-- ── Instrument detail ── --%>
            <% @selected -> %>
              <%!-- Hero header --%>
              <div class="mb-8 border-b-2 border-base-content/15 pb-6">
                <div class="flex items-start justify-between gap-6">
                  <div class="min-w-0">
                    <p class="text-[10px] font-black uppercase tracking-[0.4em] text-primary opacity-70">
                      {@selected.guitar && String.capitalize(@selected.guitar.kind)}
                    </p>
                    <h2 class="mt-1 text-5xl font-black leading-tight tracking-tight">
                      {@selected.name}
                    </h2>
                    <p class="mt-2 text-lg font-semibold opacity-50">
                      <span :if={@selected.guitar && @selected.guitar.brand}>
                        {@selected.guitar.brand}
                      </span>
                      <span :if={@selected.guitar && @selected.guitar.model}>
                        · {@selected.guitar.model}
                      </span>
                    </p>
                  </div>
                  <div class="flex shrink-0 gap-2 pt-1">
                    <.link
                      patch={~p"/instruments/#{@selected.id}/edit?#{q_params(@search, @show_sold)}"}
                      class="btn btn-sm rounded-none border-2 font-bold uppercase tracking-wider"
                    >
                      Edit
                    </.link>
                    <.link
                      phx-click={JS.push("delete", value: %{id: @selected.id})}
                      data-confirm="Delete this instrument?"
                      class="btn btn-sm btn-error rounded-none font-bold uppercase tracking-wider"
                    >
                      Delete
                    </.link>
                  </div>
                </div>
              </div>

              <%!-- Specs strip --%>
              <div class="mb-10 grid grid-cols-2 gap-px border border-base-content/15 bg-base-content/10 sm:grid-cols-4">
                <div class="bg-base-100 px-4 py-4">
                  <p class="text-[10px] font-black uppercase tracking-[0.3em] opacity-40">Year</p>
                  <p class="mt-1 text-2xl font-black">
                    {if @selected.guitar && @selected.guitar.year,
                      do: @selected.guitar.year,
                      else: "—"}
                  </p>
                </div>
                <div class="bg-base-100 px-4 py-4">
                  <p class="text-[10px] font-black uppercase tracking-[0.3em] opacity-40">Brand</p>
                  <p class="mt-1 text-xl font-bold leading-snug">
                    {if @selected.guitar && @selected.guitar.brand,
                      do: @selected.guitar.brand,
                      else: "—"}
                  </p>
                </div>
                <div class="bg-base-100 px-4 py-4">
                  <p class="text-[10px] font-black uppercase tracking-[0.3em] opacity-40">Model</p>
                  <p class="mt-1 text-xl font-bold leading-snug">
                    {if @selected.guitar && @selected.guitar.model,
                      do: @selected.guitar.model,
                      else: "—"}
                  </p>
                </div>
                <div class="bg-base-100 px-4 py-4">
                  <p class="text-[10px] font-black uppercase tracking-[0.3em] opacity-40">Color</p>
                  <p class="mt-1 text-xl font-bold leading-snug">
                    {if @selected.guitar && @selected.guitar.color,
                      do: @selected.guitar.color,
                      else: "—"}
                  </p>
                </div>
              </div>

              <%!-- ─── Photos ─── --%>
              <div class="mb-12">
                <h3 class="mb-5 text-[10px] font-black uppercase tracking-[0.4em] opacity-40">
                  Photos
                </h3>

                <div
                  :if={@selected.images != []}
                  class="mb-4 grid grid-cols-2 gap-4 sm:grid-cols-3"
                >
                  <figure :for={image <- @selected.images} class="space-y-2">
                    <img
                      src={Uploads.url(image.path)}
                      alt={image.description}
                      class="aspect-square w-full object-cover"
                    />
                    <form phx-submit="update_image" class="flex gap-2">
                      <input type="hidden" name="image_id" value={image.id} />
                      <input
                        type="text"
                        name="description"
                        value={image.description}
                        placeholder="Add a caption"
                        class="input input-sm input-bordered w-full rounded-none"
                      />
                      <.button type="submit" class="btn btn-sm rounded-none font-bold uppercase tracking-wider">
                        Save
                      </.button>
                    </form>
                    <.link
                      phx-click={JS.push("delete_image", value: %{id: image.id})}
                      data-confirm="Delete this photo?"
                      class="text-xs opacity-40 transition-opacity hover:text-error hover:opacity-100"
                    >
                      Delete photo
                    </.link>
                  </figure>
                </div>

                <p :if={@selected.images == []} class="mb-4 text-sm italic opacity-40">
                  No photos yet.
                </p>

                <form
                  id="upload-form"
                  phx-submit="save_images"
                  phx-change="validate_upload"
                  class="space-y-3"
                >
                  <.live_file_input upload={@uploads.images} />

                  <div :if={@uploads.images.entries != []} class="flex flex-wrap gap-3">
                    <div :for={entry <- @uploads.images.entries} class="space-y-1">
                      <.live_img_preview entry={entry} class="size-24 object-cover" />
                      <button
                        type="button"
                        phx-click="cancel_upload"
                        phx-value-ref={entry.ref}
                        class="block text-xs opacity-40 hover:opacity-100"
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

                  <.button type="submit" class="btn btn-sm btn-primary rounded-none font-bold uppercase tracking-wider">
                    Upload photos
                  </.button>
                </form>
              </div>

              <%!-- ─── History ─── --%>
              <div>
                <h3 class="mb-5 text-[10px] font-black uppercase tracking-[0.4em] opacity-40">
                  History
                </h3>

                <ol class="relative ml-3 space-y-4 border-l-2 border-base-content/15">
                  <li :for={event <- @selected.events} class="relative ml-6">
                    <%!-- Timeline dot --%>
                    <span class="absolute -left-[33px] top-3 flex h-5 w-5 items-center justify-center rounded-full border-2 border-primary bg-base-100 ring-4 ring-base-100">
                      <span class="h-2 w-2 rounded-full bg-primary"></span>
                    </span>

                    <div class="border border-base-content/10 bg-base-200/40 px-4 py-3">
                      <div class="flex items-start justify-between gap-4">
                        <div>
                          <span class="text-[10px] font-black uppercase tracking-[0.3em] text-primary">
                            {String.capitalize(event.kind)}
                          </span>
                          <span class="ml-2 text-sm opacity-50">
                            {Calendar.strftime(event.date, "%b %-d, %Y")}
                          </span>
                          <p :if={event.description} class="mt-1 text-sm opacity-80">
                            {event.description}
                          </p>
                          <p :if={event.price_cents} class="mt-1 text-sm font-bold">
                            {format_price(event.price_cents, event.currency)}
                            <span :if={event.counterparty} class="font-normal opacity-60">
                              · {event.counterparty}
                            </span>
                          </p>
                        </div>
                        <div class="flex shrink-0 items-center gap-4">
                          <button
                            type="button"
                            phx-click="set_uploading_event"
                            phx-value-id={event.id}
                            class="text-xs opacity-40 transition-opacity hover:text-primary hover:opacity-100"
                          >
                            {if @uploading_event_id == event.id, do: "Cancel", else: "+ Photos"}
                          </button>
                          <.link
                            phx-click={JS.push("delete_event", value: %{id: event.id})}
                            data-confirm="Delete this history entry?"
                            class="text-xs opacity-40 transition-opacity hover:text-error hover:opacity-100"
                          >
                            Remove
                          </.link>
                        </div>
                      </div>

                      <%!-- Event images --%>
                      <div :if={event.images != []} class="mt-3 flex flex-wrap gap-2">
                        <figure :for={image <- event.images} class="space-y-1">
                          <img
                            src={Uploads.url(image.path)}
                            alt={image.description}
                            class="size-24 object-cover"
                          />
                          <form phx-submit="update_image" class="flex gap-1">
                            <input type="hidden" name="image_id" value={image.id} />
                            <input
                              type="text"
                              name="description"
                              value={image.description}
                              placeholder="Caption"
                              class="input input-xs input-bordered w-24 rounded-none"
                            />
                            <.button type="submit" class="btn btn-xs rounded-none">OK</.button>
                          </form>
                          <.link
                            phx-click={JS.push("delete_image", value: %{id: image.id})}
                            data-confirm="Delete this photo?"
                            class="block text-xs opacity-40 hover:text-error hover:opacity-100"
                          >
                            Delete
                          </.link>
                        </figure>
                      </div>

                      <%!-- Event upload form --%>
                      <div
                        :if={@uploading_event_id == event.id}
                        class="mt-3 border-t border-base-content/10 pt-3"
                      >
                        <form
                          id={"event-upload-form-#{event.id}"}
                          phx-submit="save_event_images"
                          phx-change="validate_event_upload"
                          class="space-y-2"
                        >
                          <.live_file_input upload={@uploads.event_images} />

                          <div
                            :if={@uploads.event_images.entries != []}
                            class="flex flex-wrap gap-2"
                          >
                            <div
                              :for={entry <- @uploads.event_images.entries}
                              class="space-y-1"
                            >
                              <.live_img_preview entry={entry} class="size-16 object-cover" />
                              <button
                                type="button"
                                phx-click="cancel_event_upload"
                                phx-value-ref={entry.ref}
                                class="block text-xs opacity-40 hover:opacity-100"
                              >
                                Cancel
                              </button>
                              <p
                                :for={err <- upload_errors(@uploads.event_images, entry)}
                                class="text-xs text-error"
                              >
                                {upload_error_to_string(err)}
                              </p>
                            </div>
                          </div>

                          <p
                            :for={err <- upload_errors(@uploads.event_images)}
                            class="text-xs text-error"
                          >
                            {upload_error_to_string(err)}
                          </p>

                          <.button
                            type="submit"
                            phx-disable-with="Uploading..."
                            class="btn btn-xs btn-primary rounded-none font-bold uppercase tracking-wider"
                          >
                            Upload photos
                          </.button>
                        </form>
                      </div>
                    </div>
                  </li>
                </ol>

                <p :if={@selected.events == []} class="mb-4 text-sm italic opacity-40">
                  No history recorded yet.
                </p>

                <%!-- Add event form --%>
                <div class="mt-8 border-t-2 border-base-content/10 pt-6">
                  <p class="mb-4 text-[10px] font-black uppercase tracking-[0.4em] opacity-40">
                    Add to history
                  </p>
                  <.form
                    for={@event_form}
                    id="event-form"
                    phx-change="validate_event"
                    phx-submit="save_event"
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
                    <.button
                      phx-disable-with="Adding..."
                      class="btn btn-primary mt-4 rounded-none font-bold uppercase tracking-wider"
                    >
                      Add event
                    </.button>
                  </.form>
                </div>
              </div>

            <%!-- ── Add new instrument ── --%>
            <% true -> %>
              <div class="flex h-full items-start pt-4">
                <div class="max-w-md">
                  <p class="text-[10px] font-black uppercase tracking-[0.4em] text-primary opacity-70">
                    Add to the vault
                  </p>
                  <h2 class="mt-2 text-4xl font-black tracking-tight">New Instrument</h2>
                  <p class="mb-8 mt-2 text-base opacity-50">
                    Add a guitar or bass to start building your collection.
                  </p>
                  <.instrument_form form={@form} submit_label="Add to vault" />
                </div>
              </div>
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
        <.button phx-disable-with="Saving..." class="btn btn-primary rounded-none font-bold uppercase tracking-wider">
          {@submit_label}
        </.button>
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
     |> assign(:uploading_event_id, nil)
     |> assign(:form, new_form())
     |> assign(:event_form, new_event_form())
     |> allow_upload(:images,
       accept: ~w(.jpg .jpeg .png .webp),
       max_entries: 8,
       max_file_size: 10_000_000
     )
     |> allow_upload(:event_images,
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

  def handle_event("set_uploading_event", %{"id" => id}, socket) do
    parsed = String.to_integer(id)
    new_id = if socket.assigns.uploading_event_id == parsed, do: nil, else: parsed
    {:noreply, assign(socket, :uploading_event_id, new_id)}
  end

  def handle_event("validate_event_upload", _params, socket) do
    {:noreply, socket}
  end

  def handle_event("cancel_event_upload", %{"ref" => ref}, socket) do
    {:noreply, cancel_upload(socket, :event_images, ref)}
  end

  def handle_event("save_event_images", _params, socket) do
    scope = socket.assigns.current_scope
    event_id = socket.assigns.uploading_event_id
    event = Enum.find(socket.assigns.selected.events, &(&1.id == event_id))

    uploaded =
      consume_uploaded_entries(socket, :event_images, fn %{path: path}, entry ->
        filename = Uploads.store(path, entry.client_name)
        {:ok, %{path: filename, content_type: entry.client_type}}
      end)

    for attrs <- uploaded do
      {:ok, _image} = Vaults.add_image(scope, event, attrs)
    end

    socket =
      if uploaded == [] do
        socket
      else
        socket
        |> put_flash(:info, "#{length(uploaded)} photo(s) added.")
        |> assign(:selected, Vaults.get_instrument!(scope, socket.assigns.selected.id))
        |> assign(:uploading_event_id, nil)
      end

    {:noreply, socket}
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
