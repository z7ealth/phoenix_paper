defmodule PhoenixPaper.PowerSelect do
  @moduledoc ~S'''
  A searchable select (`PhoenixPaper.PowerSelect`), in the spirit of
  [ember-power-select](https://ember-power-select.com): a Material trigger
  that opens a list you can filter by typing, navigate with the keyboard,
  group, search on the server, and (with `multiple`) pick several values
  from as chips.

      <.live_component
        module={PhoenixPaper.PowerSelect}
        id="country"
        field={@form[:country]}
        label="Country"
        options={[{"Canada", "ca"}, {"México", "mx"}, {"United States", "us"}]}
        search_enabled
        allow_clear
      />

  It needs interactive state (the search term, the current results, the
  selection, a pending server search), so like `PhoenixPaper.Autocomplete`
  it's a `Phoenix.LiveComponent`: use it with `<.live_component>`, and only
  inside a LiveView, not on a controller-rendered page.

  `PhoenixPaper.Autocomplete` is the other text-plus-list component: a free
  text field with suggestions. Reach for `PowerSelect` when the value must be
  one (or several) of a known set.

  ## Options

  `options` takes strings, `{label, value}` tuples, or maps/structs. For a
  map, `label_field` (default `:label`) and `value_field` (default `:value`)
  name the keys to read, and a `disabled: true` key disables that option:

      options={@users}
      label_field={:name}
      value_field={:id}

  **Groups**: a map with `:group_name` and `:options` is a group, and groups
  nest without limit. `disabled: true` on a group disables everything in it.
  Search and keyboard navigation go through groups, and a group with no
  matches is hidden.

      options={[
        %{group_name: "Fruit", options: ["Apple", "Banana"]},
        %{group_name: "Vegetables", options: ["Carrot", %{label: "Leek", disabled: true}]}
      ]}

  ## Search

  Off by default. `search_enabled` adds a search box at the top of the list
  (in the trigger for `multiple`). Matching ignores case and accents:
  `maria` finds `María`, `soren` finds `Søren`. It matches the label, or
  `search_field` for map options. `matcher` replaces the rule entirely, a
  function `(option, term) -> boolean` receiving the original option.

  Without search, a focused single select still jumps to an option when you
  type its first letters, the way a native `<select>` does.

  **Server search**: give `search` a function `term -> options` and every
  non-blank term runs it in a task (`start_async/3`); the list shows
  `loading_message` meanwhile. A blank term shows `options` again (an
  initial set, or `[]`, which shows `search_message`). Only the latest term's
  results are ever shown, however the tasks finish. `debounce` (ms, default
  `300`) spaces the requests out.

      search={fn term -> MyApp.Accounts.search_users(term) end}
      label_field={:name}
      value_field={:id}

  ## Multiple

  `multiple` keeps the list open while picking, shows each selection as a
  chip in the trigger (✕ removes it, so does Backspace in an empty search
  box) and clicking a picked option again unpicks it. The value is a list.

  ## Rendering options

  The `:option` slot renders each option. It receives a map with `option`
  (the original option), `label`, `search` (the current term, e.g. for
  highlighting) and `selected`:

      <:option :let={%{option: user, search: term}}>
        <.highlight text={user.name} term={term} /> <small>{user.email}</small>
      </:option>

  The `:selected_item` slot (same map) renders the selection in a single
  select's trigger; without it the trigger shows the label.

  ## Forms and change notifications

  With `field=` (or `name`) it renders hidden inputs carrying the option
  values: one for a single select, `name[]` per value for `multiple` (and a
  single empty `name` input when nothing is picked, so clearing still
  submits). After every change it fires an `input` event on them, so the
  surrounding form's `phx-change` runs exactly as it would for a native
  select. Values come back as strings, like any form param.

  Outside a form, pass `on_change`, a function called (in the LiveView's
  process) with the new value, or list of values:

      on_change={fn value -> send(self(), {:country_changed, value}) end}

  The parent's `value` is read again only when it *changes*, so a parent
  that re-renders for other reasons doesn't undo a pick the form hasn't
  round-tripped yet.

  ## Keyboard

  Arrow keys open the list and move between options, <kbd>Enter</kbd>
  picks (in the search box, it picks the first result), <kbd>Esc</kbd>
  closes, typing in the list jumps to the search box. Clicking outside
  closes it too.

  ## Look

  `variant` (`outlined`/`filled`), `shape`, `label`, `placeholder`,
  `search_placeholder`, `supporting_text`, `disabled`, and the messages
  (`no_matches_message`, `loading_message`, `search_message`), all strings
  you can translate. `paperize={false}` drops every built-in class; the
  dropdown's positioning stays, like `PhoenixPaper.Menu`'s.
  '''
  use Phoenix.LiveComponent

  alias Phoenix.LiveView.JS
  alias PhoenixPaper.{Helpers, Shape}
  import PhoenixPaper.Paper, only: [pp_paper: 1]

  @defaults [
    name: nil,
    value: nil,
    field: nil,
    options: [],
    multiple: false,
    search_enabled: false,
    search: nil,
    search_field: nil,
    label_field: :label,
    value_field: :value,
    matcher: nil,
    label: nil,
    placeholder: nil,
    search_placeholder: nil,
    allow_clear: false,
    disabled: false,
    no_matches_message: "No results found",
    loading_message: "Loading options…",
    search_message: "Type to search",
    debounce: 300,
    on_change: nil,
    variant: "outlined",
    shape: :xs,
    supporting_text: nil,
    errors: [],
    paperize: true,
    class: nil,
    option: [],
    selected_item: []
  ]

  # Keyboard handling for the whole component, delegated from the root (see
  # the moduledoc's "Keyboard"). Inline, like `PhoenixPaper.Ripple`: it only
  # moves DOM focus and clicks existing elements (options, chips, the hidden
  # close button), all of which LiveView leaves alone when it patches, so
  # nothing here can be undone by a re-render.
  @keyboard_js ~S"""
  (function(e){var root=e.currentTarget,t=e.target,k=e.key;
  var panel=root.querySelector('[data-pp-panel]');var open=!!panel&&panel.offsetParent!==null;
  var search=root.querySelector('[data-pp-search]');var trigger=root.querySelector('[data-pp-trigger]');
  var all=Array.prototype.slice.call(root.querySelectorAll('[data-pp-option]:not([disabled])'));
  var vis=all.filter(function(o){return o.offsetParent!==null;});var i=vis.indexOf(document.activeElement);
  var norm=function(s){return (s||'').normalize('NFD').replace(/[̀-ͯ]/g,'').toLowerCase();};
  if(k==='ArrowDown'||k==='ArrowUp'){e.preventDefault();
    if(!open){if(trigger)trigger.click();return;}
    if(!vis.length)return;
    if(i<0){var sel=vis.filter(function(o){return o.getAttribute('aria-selected')==='true';})[0];
      (k==='ArrowDown'?(sel||vis[0]):vis[vis.length-1]).focus();return;}
    var n=k==='ArrowDown'?Math.min(i+1,vis.length-1):i-1;
    if(n<0){(search||trigger).focus();}else{vis[n].focus();}return;}
  if(k==='Escape'&&open){e.preventDefault();var c=root.querySelector('[data-pp-close]');if(c)c.click();if(trigger)trigger.focus();return;}
  if(k==='Enter'&&search&&t===search){e.preventDefault();if(open&&vis.length)vis[0].click();return;}
  if(k==='Backspace'&&search&&t===search&&search.value===''){
    var chips=root.querySelectorAll('[data-pp-remove]');if(chips.length){e.preventDefault();chips[chips.length-1].click();}return;}
  if(k.length===1&&!e.ctrlKey&&!e.metaKey&&!e.altKey){
    if(search&&t!==search){if(open){search.focus();}else if(t===trigger){trigger.click();}return;}
    if(!search&&(t===trigger||i>=0)){
      var buf=(root.dataset.ppBuffer||'')+norm(k);root.dataset.ppBuffer=buf;
      clearTimeout(root.ppTimer);root.ppTimer=setTimeout(function(){root.dataset.ppBuffer='';},700);
      var m=all.filter(function(o){return norm(o.dataset.ppLabel).indexOf(buf)===0;})[0];
      if(m){if(open){m.focus();}else{m.click();}}}}
  })(event)
  """

  @impl true
  def mount(socket) do
    {:ok,
     assign(socket,
       search_term: "",
       results: [],
       known: %{},
       selected: [],
       loading: false,
       seeded: false,
       external_value: nil,
       change_count: 0
     )}
  end

  @impl true
  def update(assigns, socket) do
    # A LiveComponent has no `attr` defaults, so an attr the caller never
    # passed is simply absent: `assign_new/3` fills it on the first update
    # and keeps whatever a later update passes.
    socket =
      @defaults
      |> Enum.reduce(assign(socket, assigns), fn {key, default}, socket ->
        assign_new(socket, key, fn -> default end)
      end)
      |> apply_field(assigns)

    tree = normalize_options(socket.assigns.options, socket.assigns)
    known = Map.merge(socket.assigns.known, index(tree))

    socket =
      socket
      |> assign(tree: tree, known: known)
      |> seed_selection()
      |> refresh_results()

    {:ok, socket}
  end

  # An explicit `value` wins over the field's, like every other form
  # component's `field=` handling.
  defp apply_field(%{assigns: %{field: %Phoenix.HTML.FormField{} = field}} = socket, assigns) do
    errors = if Phoenix.Component.used_input?(field), do: field.errors, else: []

    assign(socket,
      name: socket.assigns.name || field.name,
      value: if(is_nil(assigns[:value]), do: field.value, else: assigns[:value]),
      errors: Enum.map(errors, &Helpers.translate_error/1)
    )
  end

  defp apply_field(socket, _assigns), do: socket

  # Re-read the parent's value only when it changed since the last update
  # (see the moduledoc): an unrelated parent re-render passes the same, possibly
  # stale, value and must not undo a pick.
  defp seed_selection(%{assigns: %{seeded: true, external_value: same, value: same}} = socket),
    do: socket

  defp seed_selection(socket) do
    %{value: value, known: known, multiple: multiple} = socket.assigns

    values =
      cond do
        value in [nil, ""] -> []
        multiple -> value |> List.wrap() |> Enum.reject(&(&1 in [nil, ""]))
        true -> [value]
      end

    selected =
      Enum.map(values, fn value ->
        Map.get(known, to_string(value)) || plain_option(value)
      end)

    assign(socket, selected: selected, external_value: value, seeded: true)
  end

  defp refresh_results(socket) do
    %{search_term: term, tree: tree, search: search, matcher: matcher} = socket.assigns

    cond do
      term == "" -> assign(socket, results: tree)
      is_function(search, 1) -> socket
      true -> assign(socket, results: filter_options(tree, term, matcher))
    end
  end

  @impl true
  def handle_event("search", %{"value" => term}, socket) do
    if term == socket.assigns.search_term do
      {:noreply, socket}
    else
      {:noreply, run_search(socket, term)}
    end
  end

  def handle_event("reset", _params, socket), do: {:noreply, run_search(socket, "")}

  def handle_event("select", %{"key" => key}, socket) do
    case Map.fetch(socket.assigns.known, key) do
      {:ok, %{disabled: false} = option} ->
        selected =
          cond do
            not socket.assigns.multiple -> [option]
            Enum.any?(socket.assigns.selected, &(&1.key == key)) -> drop_key(socket, key)
            true -> socket.assigns.selected ++ [option]
          end

        socket = if socket.assigns.multiple, do: socket, else: run_search(socket, "")
        {:noreply, changed(socket, selected)}

      _ ->
        {:noreply, socket}
    end
  end

  def handle_event("remove", %{"key" => key}, socket),
    do: {:noreply, changed(socket, drop_key(socket, key))}

  def handle_event("clear", _params, socket), do: {:noreply, changed(socket, [])}

  @impl true
  def handle_async(:search, {:ok, {term, options}}, socket) do
    if term == socket.assigns.search_term do
      results = normalize_options(options, socket.assigns)

      {:noreply,
       assign(socket,
         results: results,
         known: Map.merge(socket.assigns.known, index(results)),
         loading: false
       )}
    else
      {:noreply, socket}
    end
  end

  def handle_async(:search, {:exit, _reason}, socket),
    do: {:noreply, assign(socket, loading: false)}

  defp run_search(socket, term) do
    %{search: search, tree: tree, matcher: matcher} = socket.assigns
    socket = assign(socket, search_term: term)

    cond do
      String.trim(term) == "" ->
        socket |> cancel_async(:search) |> assign(results: tree, loading: false)

      is_function(search, 1) ->
        socket
        |> assign(loading: true)
        |> start_async(:search, fn -> {term, search.(term)} end)

      true ->
        assign(socket, results: filter_options(tree, term, matcher))
    end
  end

  defp drop_key(socket, key), do: Enum.reject(socket.assigns.selected, &(&1.key == key))

  defp changed(socket, selected) do
    socket = assign(socket, selected: selected, change_count: socket.assigns.change_count + 1)

    if on_change = socket.assigns.on_change do
      on_change.(current_value(socket.assigns))
    end

    socket
  end

  defp current_value(%{multiple: true, selected: selected}), do: Enum.map(selected, & &1.value)
  defp current_value(%{selected: [option | _]}), do: option.value
  defp current_value(_assigns), do: nil

  @impl true
  def render(assigns) do
    assigns =
      assign(assigns,
        selected_keys: MapSet.new(assigns.selected, & &1.key),
        search_box?: assigns.search_enabled or is_function(assigns.search, 1)
      )

    ~H"""
    <div
      id={@id}
      data-pp-component="power-select"
      class={Helpers.classes(@paperize, "flex flex-col gap-1", @class)}
    >
      <div
        class="relative"
        phx-click-away={hide(@id)}
        onkeydown={!@disabled && keyboard_js()}
      >
        <.hidden_inputs id={@id} name={@name} multiple={@multiple} selected={@selected} />
        <span
          :if={@change_count > 0}
          id={"#{@id}-changed-#{@change_count}"}
          hidden
          phx-mounted={JS.dispatch("input", to: "##{@id}-value")}
        />
        <button type="button" hidden data-pp-close phx-click={hide(@id)} tabindex="-1" />

        <div class={Helpers.classes(@paperize, wrapper_classes(@variant, @shape, @errors), nil)}>
          <span
            :if={@label}
            id={"#{@id}-label"}
            class={Helpers.classes(@paperize, label_classes(@errors), nil)}
          >
            {@label}
          </span>

          <button
            :if={!@multiple}
            type="button"
            id={"#{@id}-trigger"}
            data-pp-trigger
            role="combobox"
            aria-haspopup="listbox"
            aria-expanded="false"
            aria-controls={"#{@id}-listbox"}
            aria-labelledby={@label && "#{@id}-label"}
            disabled={@disabled}
            phx-click={toggle(@id, @myself)}
            class={Helpers.classes(@paperize, single_trigger_classes(@label), nil)}
          >
            <span :if={@selected == [] && @placeholder} class={@paperize && "text-pp-outline"}>
              {@placeholder}
            </span>
            <span :for={option <- @selected} class="truncate">
              {if @selected_item != [],
                do: render_slot(@selected_item, slot_arg(option, @search_term, true)),
                else: option.label}
            </span>
          </button>

          <div
            :if={@multiple}
            id={"#{@id}-trigger"}
            role="combobox"
            aria-haspopup="listbox"
            aria-expanded="false"
            aria-controls={"#{@id}-listbox"}
            aria-labelledby={@label && "#{@id}-label"}
            phx-click={!@disabled && show(@id)}
            class={Helpers.classes(@paperize, multiple_trigger_classes(@label, @disabled), nil)}
          >
            <span
              :for={option <- @selected}
              class={Helpers.classes(@paperize, "inline-flex h-7 max-w-full items-center gap-1 rounded-pp-sm border border-pp-outline-variant ps-3 pe-1 pp-label-large text-pp-on-surface-variant", nil)}
            >
              <span class="truncate">{option.label}</span>
              <span
                :if={!@disabled}
                role="button"
                tabindex="-1"
                data-pp-remove
                aria-label={"Remove #{option.label}"}
                phx-click="remove"
                phx-value-key={option.key}
                phx-target={@myself}
                class={Helpers.classes(@paperize, "relative inline-flex size-5 cursor-pointer items-center justify-center overflow-hidden rounded-pp-full pp-state-layer", nil)}
              >
                ✕
              </span>
            </span>
            <input
              :if={@search_box?}
              type="text"
              id={"#{@id}-search"}
              data-pp-search
              form={"#{@id}-detached"}
              autocomplete="off"
              value={@search_term}
              placeholder={(@selected == [] && (@search_placeholder || @placeholder)) || nil}
              disabled={@disabled}
              phx-keyup="search"
              phx-debounce={@debounce}
              phx-target={@myself}
              class={Helpers.classes(@paperize, "min-w-16 flex-1 bg-transparent py-0.5 pp-body-large text-pp-on-surface outline-none placeholder:text-pp-on-surface-variant", nil)}
            />
            <button
              :if={!@search_box?}
              type="button"
              data-pp-trigger
              disabled={@disabled}
              aria-label={@label || @placeholder || "Open"}
              phx-click={toggle(@id, @myself)}
              class={Helpers.classes(@paperize, "min-w-8 flex-1 cursor-pointer self-stretch text-start pp-body-large text-pp-on-surface-variant outline-none disabled:cursor-default", nil)}
            >
              {@selected == [] && @placeholder}
            </button>
          </div>

          <span
            :if={@allow_clear && !@multiple && @selected != [] && !@disabled}
            role="button"
            tabindex="0"
            aria-label="Clear"
            phx-click="clear"
            phx-target={@myself}
            onkeydown="if(event.key==='Enter'||event.key===' '){event.preventDefault();this.click();}"
            class={Helpers.classes(@paperize, "absolute end-9 top-1/2 inline-flex size-8 -translate-y-1/2 cursor-pointer items-center justify-center overflow-hidden rounded-pp-full text-pp-on-surface-variant pp-state-layer", nil)}
          >
            ✕
          </span>
          <span
            :if={@paperize}
            class="pointer-events-none absolute end-4 top-1/2 size-0 -translate-y-1/2 border-x-[5px] border-t-[5px] border-x-transparent border-t-pp-on-surface-variant"
          />
        </div>

        <div
          id={"#{@id}-panel"}
          data-pp-panel
          class="absolute inset-x-0 top-full z-40 mt-1 hidden"
        >
          <.pp_paper
            color="surface-container"
            elevation={2}
            shape={:xs}
            paperize={@paperize}
            component="power-select-panel"
            class={Helpers.classes(@paperize, "overflow-hidden", nil)}
          >
            <input
              :if={@search_box? && !@multiple}
              type="text"
              id={"#{@id}-search"}
              data-pp-search
              form={"#{@id}-detached"}
              autocomplete="off"
              value={@search_term}
              placeholder={@search_placeholder}
              phx-keyup="search"
              phx-debounce={@debounce}
              phx-target={@myself}
              class={Helpers.classes(@paperize, "block w-full border-b border-pp-outline-variant bg-transparent px-4 py-3 pp-body-large text-pp-on-surface outline-none placeholder:text-pp-on-surface-variant", nil)}
            />
            <ul
              id={"#{@id}-listbox"}
              role="listbox"
              aria-multiselectable={@multiple && "true"}
              class={Helpers.classes(@paperize, "max-h-72 overflow-y-auto py-1", nil)}
            >
              <li :if={@loading} class={Helpers.classes(@paperize, message_classes(), nil)}>
                {@loading_message}
              </li>
              <li
                :if={!@loading && @results == [] && @search_term == "" && is_function(@search, 1)}
                class={Helpers.classes(@paperize, message_classes(), nil)}
              >
                {@search_message}
              </li>
              <li
                :if={!@loading && @results == [] && (@search_term != "" || !is_function(@search, 1))}
                class={Helpers.classes(@paperize, message_classes(), nil)}
              >
                {@no_matches_message}
              </li>
              <.nodes
                :if={!@loading}
                nodes={@results}
                id={@id}
                myself={@myself}
                multiple={@multiple}
                search_box?={@search_box?}
                selected_keys={@selected_keys}
                search_term={@search_term}
                option_slot={@option}
                paperize={@paperize}
              />
            </ul>
          </.pp_paper>
        </div>
      </div>
      <p
        :if={@supporting_text && @errors == []}
        class={@paperize && "px-4 pp-body-small text-pp-on-surface-variant"}
      >
        {@supporting_text}
      </p>
      <p :for={msg <- @errors} class={@paperize && "px-4 pp-body-small text-pp-error"}>{msg}</p>
    </div>
    """
  end

  attr(:id, :string, required: true)
  attr(:name, :any, required: true)
  attr(:multiple, :boolean, required: true)
  attr(:selected, :list, required: true)

  defp hidden_inputs(%{name: nil} = assigns), do: ~H""

  defp hidden_inputs(%{multiple: true, selected: []} = assigns) do
    ~H"""
    <input type="hidden" id={"#{@id}-value"} name={@name} value="" />
    """
  end

  defp hidden_inputs(%{multiple: true} = assigns) do
    ~H"""
    <input
      :for={{option, index} <- Enum.with_index(@selected)}
      type="hidden"
      id={index == 0 && "#{@id}-value"}
      name={"#{@name}[]"}
      value={option.key}
    />
    """
  end

  defp hidden_inputs(assigns) do
    ~H"""
    <input
      type="hidden"
      id={"#{@id}-value"}
      name={@name}
      value={Enum.map_join(@selected, & &1.key)}
    />
    """
  end

  attr(:nodes, :list, required: true)
  attr(:id, :string, required: true)
  attr(:myself, :any, required: true)
  attr(:multiple, :boolean, required: true)
  attr(:search_box?, :boolean, required: true)
  attr(:selected_keys, :any, required: true)
  attr(:search_term, :string, required: true)
  attr(:option_slot, :list, required: true)
  attr(:paperize, :boolean, required: true)

  defp nodes(assigns) do
    ~H"""
    <li :for={node <- @nodes} role={node.kind == :group && "group"}>
      <%= if node.kind == :group do %>
        <span class={Helpers.classes(@paperize, group_classes(node.disabled), nil)}>
          {node.label}
        </span>
        <ul class={@paperize && "pl-3"}>
          <.nodes
            nodes={node.options}
            id={@id}
            myself={@myself}
            multiple={@multiple}
            search_box?={@search_box?}
            selected_keys={@selected_keys}
            search_term={@search_term}
            option_slot={@option_slot}
            paperize={@paperize}
          />
        </ul>
      <% else %>
        <button
          type="button"
          role="option"
          data-pp-option
          data-pp-label={node.label}
          aria-selected={to_string(MapSet.member?(@selected_keys, node.key))}
          disabled={node.disabled}
          phx-click={pick(@id, @myself, node.key, @multiple, @search_box?)}
          class={Helpers.classes(@paperize, option_classes(), nil)}
        >
          {if @option_slot != [],
            do:
              render_slot(
                @option_slot,
                slot_arg(node, @search_term, MapSet.member?(@selected_keys, node.key))
              ),
            else: node.label}
        </button>
      <% end %>
    </li>
    """
  end

  defp slot_arg(option, term, selected),
    do: %{option: option.raw, label: option.label, search: term, selected: selected}

  defp keyboard_js, do: @keyboard_js

  # -- JS commands ---------------------------------------------------------

  @doc false
  def show(id) do
    JS.show(to: "##{id}-panel")
    |> JS.set_attribute({"aria-expanded", "true"}, to: "##{id}-trigger")
    |> JS.focus(to: "##{id}-search")
  end

  @doc false
  def hide(js \\ %JS{}, id) do
    js
    |> JS.hide(to: "##{id}-panel")
    |> JS.set_attribute({"aria-expanded", "false"}, to: "##{id}-trigger")
  end

  @doc false
  def toggle(id, target) do
    JS.push("reset", target: target)
    |> JS.toggle(to: "##{id}-panel")
    |> JS.toggle_attribute({"aria-expanded", "true", "false"}, to: "##{id}-trigger")
    |> JS.focus(to: "##{id}-search")
  end

  # A single select closes and hands focus back to its trigger; a multiple
  # one stays open for the next pick, focus back in its search box.
  @doc false
  def pick(id, target, key, multiple, search_box?)

  def pick(id, target, key, false, _search_box?) do
    JS.push("select", value: %{key: key}, target: target)
    |> hide(id)
    |> JS.focus(to: "##{id}-trigger")
  end

  def pick(id, target, key, true, true) do
    JS.push("select", value: %{key: key}, target: target)
    |> JS.focus(to: "##{id}-search")
  end

  def pick(_id, target, key, true, false),
    do: JS.push("select", value: %{key: key}, target: target)

  # -- Options ---------------------------------------------------------------

  @doc false
  # Turns the caller's `options` into a tree of `%{kind: :option}` and
  # `%{kind: :group}` maps. `key` is the value as a string: it's what the
  # hidden inputs submit and what the option buttons send back.
  def normalize_options(options, config, group_disabled \\ false) do
    Enum.map(options, &normalize_option(&1, config, group_disabled))
  end

  defp normalize_option(%{group_name: name, options: options} = group, config, parent_disabled) do
    disabled = parent_disabled or Map.get(group, :disabled, false) == true

    %{
      kind: :group,
      label: to_string(name),
      disabled: disabled,
      options: normalize_options(options, config, disabled)
    }
  end

  defp normalize_option({label, value} = raw, _config, disabled),
    do: build_option(raw, label, value, label, disabled)

  defp normalize_option(%{} = raw, config, disabled) do
    label = Map.get(raw, config.label_field)
    value = Map.get(raw, config.value_field, label)
    search = Map.get(raw, config.search_field || config.label_field)
    build_option(raw, label, value, search, disabled or Map.get(raw, :disabled, false) == true)
  end

  defp normalize_option(raw, _config, disabled), do: build_option(raw, raw, raw, raw, disabled)

  defp build_option(raw, label, value, search, disabled) do
    %{
      kind: :option,
      key: to_string(value),
      label: to_string(label),
      value: value,
      raw: raw,
      search_text: normalize_text(to_string(search)),
      disabled: disabled
    }
  end

  defp plain_option(value), do: build_option(value, value, value, value, false)

  defp index(tree) do
    Enum.reduce(tree, %{}, fn
      %{kind: :group, options: options}, acc -> Map.merge(acc, index(options))
      %{kind: :option, key: key} = option, acc -> Map.put(acc, key, option)
    end)
  end

  @doc false
  # Keeps the options matching `term` (and the groups that still have any).
  def filter_options(tree, term, matcher) do
    needle = normalize_text(term)

    Enum.flat_map(tree, fn
      %{kind: :group} = group ->
        case filter_options(group.options, term, matcher) do
          [] -> []
          options -> [%{group | options: options}]
        end

      option ->
        if matches?(option, term, needle, matcher), do: [option], else: []
    end)
  end

  defp matches?(option, term, _needle, matcher) when is_function(matcher, 2),
    do: matcher.(option.raw, term) == true

  defp matches?(option, _term, needle, _matcher), do: String.contains?(option.search_text, needle)

  # Letters that don't decompose under NFD (`ø` isn't `o` plus a mark), so
  # stripping combining marks alone would leave them unmatched.
  @folds %{"ø" => "o", "æ" => "ae", "œ" => "oe", "ß" => "ss", "ł" => "l", "đ" => "d", "ð" => "d"}

  @doc false
  # Case- and accent-insensitive form used for matching: `"Søren"` and
  # `"MARÍA"` become `"soren"` and `"maria"`.
  def normalize_text(text) do
    text
    |> String.downcase()
    |> :unicode.characters_to_nfd_binary()
    |> String.replace(~r/\p{Mn}/u, "")
    |> String.replace(Map.keys(@folds), &Map.fetch!(@folds, &1))
  end

  # -- Classes ----------------------------------------------------------------

  defp wrapper_classes("outlined", shape, []) do
    [
      "relative flex min-h-14 border border-pp-outline bg-transparent pp-motion-effects-fast hover:border-pp-on-surface focus-within:border-2 focus-within:!border-pp-primary",
      Shape.class(shape)
    ]
  end

  defp wrapper_classes("outlined", shape, _errors),
    do: [
      "relative flex min-h-14 border border-pp-error focus-within:border-2",
      Shape.class(shape)
    ]

  defp wrapper_classes("filled", shape, []) do
    [
      "relative flex min-h-14 bg-pp-surface-container-highest shadow-[inset_0_-1px_0_0_var(--color-pp-on-surface-variant)] focus-within:shadow-[inset_0_-2px_0_0_var(--color-pp-primary)]",
      Shape.class(shape, :top)
    ]
  end

  defp wrapper_classes("filled", shape, _errors) do
    [
      "relative flex min-h-14 bg-pp-surface-container-highest shadow-[inset_0_-1px_0_0_var(--color-pp-error)] focus-within:shadow-[inset_0_-2px_0_0_var(--color-pp-error)]",
      Shape.class(shape, :top)
    ]
  end

  defp label_classes([]),
    do:
      "pointer-events-none absolute start-4 top-2 pp-body-small text-pp-on-surface-variant transition-colors [div:focus-within>&]:text-pp-primary"

  defp label_classes(_errors),
    do: "pointer-events-none absolute start-4 top-2 pp-body-small text-pp-error"

  defp single_trigger_classes(nil),
    do:
      "flex w-full min-w-0 cursor-pointer items-center py-4 ps-4 pe-14 text-start pp-body-large text-pp-on-surface outline-none disabled:cursor-default disabled:opacity-38"

  defp single_trigger_classes(_label),
    do:
      "flex w-full min-w-0 cursor-pointer items-center pt-6 pb-2 ps-4 pe-14 text-start pp-body-large text-pp-on-surface outline-none disabled:cursor-default disabled:opacity-38"

  defp multiple_trigger_classes(nil, false),
    do: "flex w-full min-w-0 cursor-text flex-wrap items-center gap-1 py-3 ps-4 pe-8"

  defp multiple_trigger_classes(_label, false),
    do: "flex w-full min-w-0 cursor-text flex-wrap items-center gap-1 pt-6 pb-2 ps-4 pe-8"

  defp multiple_trigger_classes(nil, true),
    do: "flex w-full min-w-0 flex-wrap items-center gap-1 py-3 ps-4 pe-8 opacity-38"

  defp multiple_trigger_classes(_label, true),
    do: "flex w-full min-w-0 flex-wrap items-center gap-1 pt-6 pb-2 ps-4 pe-8 opacity-38"

  # MD3 menu items: 48dp, label-large, state layer via hover/focus tints;
  # the selected option uses the Expressive selected-item color.
  defp option_classes do
    "flex min-h-12 w-full cursor-pointer items-center gap-3 px-4 py-2 text-start pp-label-large text-pp-on-surface outline-none hover:bg-pp-on-surface/8 focus:bg-pp-on-surface/10 disabled:cursor-default disabled:opacity-38 aria-selected:bg-pp-secondary-container aria-selected:text-pp-on-secondary-container"
  end

  defp group_classes(false),
    do: "block px-4 pt-3 pb-1 pp-title-small text-pp-on-surface-variant"

  defp group_classes(true),
    do: "block px-4 pt-3 pb-1 pp-title-small text-pp-on-surface-variant opacity-38"

  defp message_classes, do: "px-4 py-3 pp-body-medium text-pp-on-surface-variant"
end
