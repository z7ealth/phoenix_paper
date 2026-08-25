#!/usr/bin/env elixir
#
# A single-file live catalog of every PhoenixPaper component. No app, no
# asset pipeline, no `mix phx.new` needed — just:
#
#   elixir dev.exs
#
# It boots a real Phoenix + LiveView server (via `phoenix_playground`) with
# `phoenix_paper` loaded straight from this checkout (`path: "."`), and
# renders a docs-site-style page: a left `PhoenixPaper.Drawer` for
# navigation, a sticky `PhoenixPaper.Navbar`, and one section per component
# with a live example, its options, and the HEEx snippet that produced it.
#
# Styling runs through the real Tailwind v4 CLI (via the `tailwind` hex
# package, the same one `mix phx.new` uses — it downloads a standalone
# binary once, then works fully offline). We compile PhoenixPaper's own
# `priv/static/phoenix_paper.css` plus this project's `lib/`/`dev.exs`
# straight to a CSS string and embed it, so the browser never has to reach
# an external CDN for the library's own styling. If you add a *new*
# Tailwind class name to a component, restart this script to pick it up —
# structural/logic edits still hot reload live via `phoenix_live_reload`.
#
# The one deliberate exception: code snippets are syntax-highlighted via
# highlight.js + its highlightjs-copy plugin, loaded from cdnjs/jsdelivr —
# real, established JS libraries rather than a hand-rolled component, so
# this page needs a network connection to render them with color/copy
# button (everything else still works offline).
#
# NOTE: every code snippet below is defined as its own module attribute
# (`@buttons_code`, `@card_code`, ...) instead of being written inline as
# `code={~S"""...""""}` inside the `~H"""..."""` template. Elixir's
# tokenizer scans for the outer heredoc's closing `"""` at the character
# level — it isn't sigil-aware — so a `~S"""..."""` nested directly inside
# an `~H"""..."""` collides with it and breaks the whole file. Pulling each
# snippet out into a top-level heredoc sidesteps the collision entirely.
Mix.install(
  [
    {:phoenix_paper, path: Path.dirname(__ENV__.file)},
    {:phoenix_playground, "~> 0.1"},
    {:tailwind, "~> 0.3"}
  ],
  config: [tailwind: [version: "4.3.0"]]
)

pp_root = Path.dirname(__ENV__.file)
theme_css = File.read!(Path.join(pp_root, "priv/static/phoenix_paper.css"))

# `@source` resolves relative to the CSS file that declares it (same as a
# real app's app.css), so the generated input file has to live inside the
# project root — an absolute filesystem path here is silently a no-op.
tailwind_input = Path.join(pp_root, ".dev_tailwind_input.css")
tailwind_output = Path.join(System.tmp_dir!(), "phoenix_paper_dev_output.css")

File.write!(
  tailwind_input,
  """
  @import "tailwindcss";
  @source "./lib";
  @source "./dev.exs";

  """ <> theme_css
)

Application.put_env(:tailwind, :default,
  args: ["--input=#{tailwind_input}", "--output=#{tailwind_output}"],
  cd: pp_root
)

Tailwind.install_and_run(:default, [])
compiled_css = File.read!(tailwind_output)

defmodule PhoenixPaperDemo.UI do
  @moduledoc """
  Small helper components used only by this catalog page — not part of
  PhoenixPaper itself.
  """
  use Phoenix.Component

  import PhoenixPaper.ListSubheader, only: [pp_list_subheader: 1]

  attr :id, :string, required: true
  attr :title, :string, required: true
  attr :description, :string, default: nil
  attr :props, :list, default: [], doc: "list of {name, description} tuples"
  attr :code, :string, required: true

  slot :inner_block, required: true

  def demo_section(assigns) do
    ~H"""
    <section id={@id} class="scroll-mt-24 border-b border-pp-outline/20 py-10 first:pt-0 last:border-b-0">
      <h2 class="text-xl font-semibold">{@title}</h2>
      <p :if={@description} class="mt-1 max-w-2xl text-sm text-pp-on-surface/70">{@description}</p>

      <div class="mt-6 rounded-lg border border-pp-outline/30 bg-pp-surface p-6">
        {render_slot(@inner_block)}
      </div>

      <div :if={@props != []} class="mt-4">
        <h3 class="text-xs font-semibold uppercase tracking-wide text-pp-on-surface/60">Options</h3>
        <dl class="mt-2 grid grid-cols-1 gap-x-4 gap-y-1.5 sm:grid-cols-[11rem_1fr]">
          <div :for={{name, desc} <- @props} class="contents">
            <dt class="font-mono text-xs text-pp-primary">{name}</dt>
            <dd class="mb-1.5 text-xs text-pp-on-surface/80 sm:mb-0">{desc}</dd>
          </div>
        </dl>
      </div>

      <div class="mt-4">
        <input type="checkbox" id={"#{@id}-code-toggle"} class="peer sr-only" />
        <label
          for={"#{@id}-code-toggle"}
          class="inline-flex cursor-pointer items-center gap-1.5 rounded-full border border-pp-outline px-3 py-1 text-xs font-medium text-pp-on-surface transition-colors hover:bg-pp-on-surface/10 peer-checked:[&>.pp-show-code]:hidden peer-checked:[&>.pp-hide-code]:inline"
        >
          <span class="pp-show-code">▸ Show code</span>
          <span class="pp-hide-code hidden">▾ Hide code</span>
        </label>

        <div class="hidden peer-checked:mt-3 peer-checked:block">
          <pre id={"#{@id}-code"} phx-update="ignore" class="overflow-x-auto rounded-lg text-sm"><code class="language-elixir">{@code}</code></pre>
        </div>
      </div>
    </section>
    """
  end

  attr :label, :string, required: true
  slot :inner_block, required: true

  def nav_group(assigns) do
    ~H"""
    <.pp_list_subheader>{@label}</.pp_list_subheader>
    {render_slot(@inner_block)}
    """
  end
end

defmodule PhoenixPaperDemo do
  use Phoenix.LiveView
  use PhoenixPaper.Components

  import Phoenix.HTML, only: [raw: 1]
  import PhoenixPaperDemo.UI
  alias Phoenix.LiveView.JS

  @pp_css compiled_css

  # Real apps get `hero-*` classes for free from `mix phx.new`'s vendored
  # heroicons + Tailwind plugin (see PhoenixPaper.Icon's moduledoc). This
  # demo has no asset pipeline, so it hand-rolls a handful of simple,
  # generic glyphs (not Heroicons' actual paths) to prove icon-accepting
  # components work the same way once those classes exist for real.
  @demo_icon_css """
  .hero-check, .hero-star, .hero-home, .hero-cog, .hero-bell, .hero-trash {
    display: inline-block; width: 1em; height: 1em; background-color: currentColor;
    mask-size: contain; -webkit-mask-size: contain;
    mask-repeat: no-repeat; -webkit-mask-repeat: no-repeat;
    mask-position: center; -webkit-mask-position: center;
  }
  .hero-check {
    mask-image: url('data:image/svg+xml;utf8,<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="none" stroke="black" stroke-width="3"><path d="M4 12l6 6L20 6"/></svg>');
    -webkit-mask-image: url('data:image/svg+xml;utf8,<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="none" stroke="black" stroke-width="3"><path d="M4 12l6 6L20 6"/></svg>');
  }
  .hero-star {
    mask-image: url('data:image/svg+xml;utf8,<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="black"><path d="M12 2l2.9 6.9L22 9.6l-5.5 4.8L18 22l-6-3.6L6 22l1.5-7.6L2 9.6l7.1-.7z"/></svg>');
    -webkit-mask-image: url('data:image/svg+xml;utf8,<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="black"><path d="M12 2l2.9 6.9L22 9.6l-5.5 4.8L18 22l-6-3.6L6 22l1.5-7.6L2 9.6l7.1-.7z"/></svg>');
  }
  .hero-home {
    mask-image: url('data:image/svg+xml;utf8,<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="black"><path d="M12 3l9 8h-3v9h-4v-6h-4v6H5v-9H2z"/></svg>');
    -webkit-mask-image: url('data:image/svg+xml;utf8,<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="black"><path d="M12 3l9 8h-3v9h-4v-6h-4v6H5v-9H2z"/></svg>');
  }
  .hero-cog {
    mask-image: url('data:image/svg+xml;utf8,<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="black" fill-rule="evenodd"><path d="M12 3a9 9 0 100 18 9 9 0 000-18zm0 5a4 4 0 100 8 4 4 0 000-8z"/></svg>');
    -webkit-mask-image: url('data:image/svg+xml;utf8,<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="black" fill-rule="evenodd"><path d="M12 3a9 9 0 100 18 9 9 0 000-18zm0 5a4 4 0 100 8 4 4 0 000-8z"/></svg>');
  }
  .hero-bell {
    mask-image: url('data:image/svg+xml;utf8,<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="black"><path d="M12 2a5 5 0 00-5 5v3.586l-1.707 1.707A1 1 0 006 14h12a1 1 0 00.707-1.707L17 10.586V7a5 5 0 00-5-5zm0 20a2.5 2.5 0 002.45-2h-4.9A2.5 2.5 0 0012 22z"/></svg>');
    -webkit-mask-image: url('data:image/svg+xml;utf8,<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="black"><path d="M12 2a5 5 0 00-5 5v3.586l-1.707 1.707A1 1 0 006 14h12a1 1 0 00.707-1.707L17 10.586V7a5 5 0 00-5-5zm0 20a2.5 2.5 0 002.45-2h-4.9A2.5 2.5 0 0012 22z"/></svg>');
  }
  .hero-trash {
    mask-image: url('data:image/svg+xml;utf8,<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="none" stroke="black" stroke-width="2"><path d="M4 7h16M9 7V4h6v3m-8 0l1 13a2 2 0 002 2h4a2 2 0 002-2l1-13"/></svg>');
    -webkit-mask-image: url('data:image/svg+xml;utf8,<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="none" stroke="black" stroke-width="2"><path d="M4 7h16M9 7V4h6v3m-8 0l1 13a2 2 0 002 2h4a2 2 0 002-2l1-13"/></svg>');
  }
  """

  # HEEx treats `<style>`/`<script>` bodies as raw text (matching how browsers
  # parse them) and does NOT interpolate `{...}` inside them — so the CSS is
  # built into one already-safe `<style>` tag *outside* the ~H sigil, and
  # dropped in with `raw/1` as a single opaque HTML fragment instead.
  @style_tag raw("<style type=\"text/css\">" <> @pp_css <> @demo_icon_css <> "</style>")

  # Code snippets are syntax-highlighted by highlight.js + its official
  # highlightjs-copy plugin (adds the copy button), loaded from cdnjs/
  # jsdelivr — see the file header for why this is the one place this page
  # reaches an external CDN.
  #
  # This tag is emitted near the *top* of the body (next to @style_tag),
  # before any `<pre><code>` markup exists in the DOM yet — a classic
  # (non-async/defer) `<script>` pauses the HTML parser and runs
  # immediately at that point in the document, so calling
  # `hljs.highlightAll()` directly here would always find zero elements
  # (it doesn't matter that the whole HTML response already arrived; the
  # parser still processes it as a left-to-right token stream and hasn't
  # built the later DOM nodes yet). Wrapping the call in a
  # `DOMContentLoaded` listener defers it until the parser has finished the
  # whole document, so it actually finds the code blocks. The `<script
  # src>` tags themselves are fine where they are — loading the libraries
  # early just means they're ready sooner.
  #
  # Language is `elixir`, not `xml`/`html`, even though these snippets are
  # HEEx templates that look tag-shaped: HEEx's function-component syntax
  # (`<.pp_button ...>`) is not valid XML — a tag name can't start with
  # `.` — and highlight.js's strict XML/HTML grammar throws on it. hljs
  # catches that per-element and silently falls back to *plain,
  # uncolored* text (marks `data-highlighted="yes"`, adds the `hljs`
  # class, but wraps nothing) — no visible error, just dead-looking output
  # for almost every snippet on this page (only the couple using bare
  # `<div>`/`<button>` escaped it). `highlight.min.js`'s bundled core only
  # ships xml/html/css/js; elixir isn't in it, so its grammar is loaded
  # separately from `/languages/elixir.min.js`. Elixir's regex-based
  # lexer doesn't choke on the leading dot (or on `<`/`>` generally — it
  # just treats them as punctuation), so every snippet highlights safely;
  # it won't color the tags themselves as HTML tags (there's no dedicated
  # HEEx grammar to reach for), but strings/atoms/keywords/numbers do.
  @hljs_assets raw("""
  <link rel="stylesheet" href="https://cdnjs.cloudflare.com/ajax/libs/highlight.js/11.10.0/styles/atom-one-dark.min.css">
  <link rel="stylesheet" href="https://cdn.jsdelivr.net/npm/highlightjs-copy@1.0.6/dist/highlightjs-copy.min.css">
  <script src="https://cdnjs.cloudflare.com/ajax/libs/highlight.js/11.10.0/highlight.min.js"></script>
  <script src="https://cdn.jsdelivr.net/npm/@highlightjs/cdn-assets@11.10.0/languages/elixir.min.js"></script>
  <script src="https://cdn.jsdelivr.net/npm/highlightjs-copy@1.0.6/dist/highlightjs-copy.min.js"></script>
  <script>
    document.addEventListener("DOMContentLoaded", function () {
      hljs.addPlugin(new CopyButtonPlugin());
      hljs.highlightAll();
    });
  </script>
  """)

  # Small placeholder "photos" for the ImageList demo — inline SVG data URIs
  # (same raw, unencoded approach as the icon masks above) so the page stays
  # fully offline, no network image fetch required.
  @photo_1 ~s(data:image/svg+xml;utf8,<svg xmlns="http://www.w3.org/2000/svg" width="200" height="200"><rect width="200" height="200" fill="#3f51b5"/></svg>)
  @photo_2 ~s(data:image/svg+xml;utf8,<svg xmlns="http://www.w3.org/2000/svg" width="200" height="200"><rect width="200" height="200" fill="#ff4081"/></svg>)
  @photo_3 ~s(data:image/svg+xml;utf8,<svg xmlns="http://www.w3.org/2000/svg" width="200" height="200"><rect width="200" height="200" fill="#009688"/></svg>)

  # --- code snippets shown under each live example (see the note at the top
  # of this file for why these live here instead of inline in the template) ---

  @buttons_code ~S"""
  <.pp_button color="primary">Save</.pp_button>
  <.pp_button variant="outlined" color="secondary">Outlined</.pp_button>
  <.pp_button variant="text">Text</.pp_button>
  <.pp_button ripple={false}>No ripple</.pp_button>
  <.pp_button paperize={false} class="border-4 border-dashed border-fuchsia-500 px-3 py-1 font-mono text-fuchsia-700">
    paperize: false
  </.pp_button>

  <.pp_button variant="outlined">
    <:start_icon><.pp_icon name="hero-trash" /></:start_icon>
    Delete
  </.pp_button>
  <.pp_button>
    Send
    <:end_icon><.pp_icon name="hero-check" /></:end_icon>
  </.pp_button>
  <.pp_button loading>
    <:start_icon><.pp_icon name="hero-trash" /></:start_icon>
    Delete
  </.pp_button>
  """

  @button_group_code ~S"""
  <.pp_button_group>
    <.pp_button variant="outlined">Day</.pp_button>
    <.pp_button variant="outlined">Week</.pp_button>
    <.pp_button variant="outlined">Month</.pp_button>
  </.pp_button_group>

  <.pp_button_group orientation="vertical">
    <.pp_button variant="outlined">Day</.pp_button>
    <.pp_button variant="outlined">Week</.pp_button>
    <.pp_button variant="outlined">Month</.pp_button>
  </.pp_button_group>

  <.pp_button_group disable_elevation>
    <.pp_button>Save</.pp_button>
    <.pp_button>Cancel</.pp_button>
  </.pp_button_group>
  """

  @fab_code ~S"""
  <.pp_fab :for={size <- ~w(sm md lg)} size={size}><.pp_icon name="hero-star" /></.pp_fab>
  <.pp_fab :for={color <- ~w(primary secondary tertiary error)} color={color}>
    <.pp_icon name="hero-star" />
  </.pp_fab>
  <.pp_fab extended color="primary">
    <.pp_icon name="hero-star" /> Create
  </.pp_fab>
  """

  @toggle_button_code ~S"""
  <.pp_toggle_button pressed={@bold_pressed} phx-click="toggle_bold">
    Bold
  </.pp_toggle_button>

  <.pp_toggle_button :for={color <- ~w(primary secondary tertiary error)} pressed color={color}>
    {color}
  </.pp_toggle_button>
  """

  @text_field_code ~S"""
  <.pp_input label="Outlined (default)" name="outlined_demo" />
  <.pp_input variant="filled" label="Filled" name="filled_demo" />
  <.pp_input label="With an error" name="error_demo" value="not-an-email" errors={["is not a valid email"]} />
  """

  @select_code ~S"""
  <.pp_select
    label="Country"
    name="country"
    prompt="Choose one"
    options={["Canada", "Mexico", "United States"]}
  />
  <.pp_select
    variant="filled"
    label="Country"
    name="country_filled"
    prompt="Choose one"
    options={["Canada", "Mexico", "United States"]}
  />
  """

  @number_field_code ~S"""
  <.pp_number_field label="Quantity" name="qty" value={2} min={0} max={10} />
  <.pp_number_field variant="filled" label="Quantity" name="qty_filled" value={2} min={0} max={10} />
  """

  @checkbox_code ~S"""
  <.pp_checkbox label="Paperized (default)" checked={true} />
  <.pp_checkbox paperize={false} label="paperize: false" />
  """

  @switch_code ~S"""
  <.pp_switch label="Notifications" checked={true} name="notifications" />
  """

  @radio_group_code ~S"""
  <.pp_radio_group
    label="Size"
    name="size"
    value="md"
    options={[{"Small", "sm"}, {"Medium", "md"}, {"Large", "lg"}]}
  />
  """

  @slider_code ~S"""
  <.pp_slider name="volume" label="Volume" value={60} color="secondary" />

  <.pp_slider :for={color <- ~w(primary secondary tertiary error)} name={"volume_#{color}"} label={color} value={60} color={color} />
  """

  @rating_code ~S"""
  <.pp_rating id="stars" name="stars" value={3} />
  <.pp_rating readonly value={4} />
  """

  @autocomplete_code ~S"""
  <.live_component
    module={PhoenixPaper.Autocomplete}
    id="country"
    name="country"
    label="Country"
    placeholder="Start typing..."
    options={["Canada", "Mexico", "United States", "United Kingdom", "Uruguay"]}
  />
  """

  @transfer_list_code ~S"""
  <.live_component
    module={PhoenixPaper.TransferList}
    id="permissions"
    items={["Read", "Write", "Admin", "Billing"]}
  />
  """

  @navbar_code ~S"""
  <.pp_navbar position="sticky">
    <:leading><.pp_drawer_toggle for="app-drawer" /></:leading>
    My App
    <:actions>
      <.pp_button variant="icon"><.pp_icon name="hero-bell" /></.pp_button>
    </:actions>
  </.pp_navbar>

  <.pp_navbar :for={color <- ~w(primary secondary tertiary surface)} color={color} class="!static">
    {color}
    <:actions>
      <.pp_button variant="icon"><.pp_icon name="hero-bell" /></.pp_button>
    </:actions>
  </.pp_navbar>
  """

  @drawer_code ~S"""
  <.pp_navbar>
    <:leading><.pp_drawer_toggle for="app-drawer" /></:leading>
    My App
  </.pp_navbar>

  <.pp_drawer id="app-drawer">
    <:header>My App</:header>
    <.pp_list>
      <.pp_list_item href="/" active={@current_path == "/"}>Home</.pp_list_item>
    </.pp_list>
  </.pp_drawer>
  """

  @list_code ~S"""
  <.pp_list>
    <.pp_list_subheader>Main</.pp_list_subheader>
    <.pp_list_item href="/" active>
      <:leading><.pp_icon name="hero-home" /></:leading>
      Home
      <:secondary>Overview</:secondary>
    </.pp_list_item>
    <.pp_divider inset />
    <.pp_list_item disabled>Locked</.pp_list_item>
  </.pp_list>
  """

  @box_code ~S"""
  <.pp_box class="rounded-lg bg-pp-surface-variant p-4">A div (default).</.pp_box>
  <.pp_box tag="span" class="rounded bg-pp-surface-variant px-2 py-1">A span.</.pp_box>
  <.pp_box tag="pre" class="rounded-lg bg-pp-surface-variant p-4">A pre, whitespace preserved.</.pp_box>
  """

  @container_code ~S"""
  <.pp_container max_width="sm">
    Narrower content.
  </.pp_container>

  <.pp_container :for={width <- ~w(sm md lg xl 2xl full)} max_width={width} class="mb-2">
    {width}
  </.pp_container>
  """

  @stack_code ~S"""
  <.pp_stack direction="row" spacing={:sm}>
    <.pp_button>Save</.pp_button>
    <.pp_button variant="outlined">Cancel</.pp_button>
  </.pp_stack>

  <.pp_stack direction="column" spacing={:sm}>
    <.pp_button>Save</.pp_button>
    <.pp_button variant="outlined">Cancel</.pp_button>
  </.pp_stack>
  """

  @grid_code ~S"""
  <.pp_grid>
    <.pp_grid_item span={12} md={4}>Sidebar</.pp_grid_item>
    <.pp_grid_item span={12} md={8}>Content</.pp_grid_item>
  </.pp_grid>
  """

  @divider_code ~S"""
  <.pp_divider />
  <.pp_divider inset />
  """

  @card_code ~S"""
  <.pp_card>
    <:title>Account</:title>
    You have no pending invoices.
    <:actions>
      <.pp_button variant="text">Dismiss</.pp_button>
    </:actions>
  </.pp_card>

  <.pp_card :for={padding <- ~w(none xs sm md lg xl 2xl)a} padding={padding}>
    padding: {padding}
  </.pp_card>
  """

  @icon_code ~S"""
  <.pp_icon name="hero-check" class="text-pp-tertiary" />
  """

  @image_list_code ~S"""
  <.pp_image_list cols={3}>
    <.pp_image_list_item src="/images/1.jpg" title="Breakfast" />
    <.pp_image_list_item src="/images/2.jpg" title="Burger" subtitle="Restaurant" />
  </.pp_image_list>
  """

  @table_code ~S"""
  <.pp_table_container>
    <.pp_table>
      <.pp_table_head>
        <.pp_table_row>
          <.pp_table_cell variant="head" sortable sort_direction="asc" phx-click="sort">Dessert</.pp_table_cell>
          <.pp_table_cell variant="head" align="right" sortable phx-click="sort">Calories</.pp_table_cell>
          <.pp_table_cell variant="head" align="right">Fat (g)</.pp_table_cell>
        </.pp_table_row>
      </.pp_table_head>
      <.pp_table_body striped>
        <.pp_table_row>
          <.pp_table_cell>Frozen yoghurt</.pp_table_cell>
          <.pp_table_cell align="right">159</.pp_table_cell>
          <.pp_table_cell align="right">6.0</.pp_table_cell>
        </.pp_table_row>
        <.pp_table_row selected>
          <.pp_table_cell>Ice cream sandwich</.pp_table_cell>
          <.pp_table_cell align="right">237</.pp_table_cell>
          <.pp_table_cell align="right">9.0</.pp_table_cell>
        </.pp_table_row>
      </.pp_table_body>
      <.pp_table_footer>
        <.pp_table_row>
          <.pp_table_cell>Total</.pp_table_cell>
          <.pp_table_cell align="right">396</.pp_table_cell>
          <.pp_table_cell align="right">15.0</.pp_table_cell>
        </.pp_table_row>
      </.pp_table_footer>
    </.pp_table>
  </.pp_table_container>

  <.pp_table_container class="max-h-40 overflow-y-auto">
    <.pp_table dense sticky_header>
      <.pp_table_head>
        <.pp_table_row>
          <.pp_table_cell variant="head">Dessert</.pp_table_cell>
          <.pp_table_cell variant="head" align="right">Calories</.pp_table_cell>
        </.pp_table_row>
      </.pp_table_head>
      <.pp_table_body>
        <.pp_table_row :for={{name, cal} <- [{"Frozen yoghurt", 159}, {"Ice cream sandwich", 237}, {"Eclair", 262}, {"Cupcake", 305}]}>
          <.pp_table_cell>{name}</.pp_table_cell>
          <.pp_table_cell align="right">{cal}</.pp_table_cell>
        </.pp_table_row>
      </.pp_table_body>
    </.pp_table>
  </.pp_table_container>
  """

  @paper_code ~S"""
  <.pp_paper elevation={4} class="p-4">A raised surface — Card is built on this.</.pp_paper>
  """

  @typography_code ~S"""
  <.pp_typography variant="h1">h1. Heading</.pp_typography>
  <.pp_typography variant="h2">h2. Heading</.pp_typography>
  <.pp_typography variant="h3">h3. Heading</.pp_typography>
  <.pp_typography variant="h4">h4. Heading</.pp_typography>
  <.pp_typography variant="h5">h5. Heading</.pp_typography>
  <.pp_typography variant="h6">h6. Heading</.pp_typography>
  <.pp_typography variant="subtitle1">subtitle1. Manage your profile, notifications, and billing.</.pp_typography>
  <.pp_typography variant="subtitle2">subtitle2. Manage your profile, notifications, and billing.</.pp_typography>
  <.pp_typography variant="body1">body1. Manage your profile, notifications, and billing.</.pp_typography>
  <.pp_typography variant="body2">body2. Manage your profile, notifications, and billing.</.pp_typography>
  <.pp_typography variant="caption">caption. Last updated 2 minutes ago</.pp_typography>
  <.pp_typography variant="overline">overline. New</.pp_typography>
  <.pp_typography variant="button">button. Save changes</.pp_typography>
  <.pp_typography variant="code">mix phx.new my_app</.pp_typography>
  """

  @ripple_code ~S"""
  <.pp_button>Ripples (default)</.pp_button>
  <.pp_button ripple={false}>No ripple</.pp_button>
  """

  @elevation_code ~S"""
  <div class={["rounded-lg bg-pp-surface p-4", PhoenixPaper.Elevation.class(8)]}>8dp</div>
  """

  @shape_code ~S"""
  <div class={["size-14 border-2 border-pp-primary", PhoenixPaper.Shape.class(:lg)]} />
  """

  @theming_code ~S"""
  <button phx-click={JS.set_attribute({"data-theme", "dark"}, to: "html")}>Dark</button>
  <button phx-click={JS.set_attribute({"data-pp-theme", "teal"}, to: "html")}>Teal</button>
  """

  def mount(_params, _session, socket) do
    {:ok, assign(socket, page_title: "PhoenixPaper catalog", bold_pressed: false)}
  end

  def handle_event("toggle_bold", _params, socket) do
    {:noreply, update(socket, :bold_pressed, &(!&1))}
  end

  # Table's sortable header cells are presentation-only (see TableCell's
  # moduledoc) — this demo doesn't actually reorder the rows, just proves
  # the click reaches the LiveView instead of crashing it (a real app would
  # re-query/re-sort its data and re-render here).
  def handle_event("sort", _params, socket) do
    {:noreply, socket}
  end

  def render(assigns) do
    assigns =
      assign(assigns,
        style_tag: @style_tag,
        hljs_assets: @hljs_assets,
        photo_1: @photo_1,
        photo_2: @photo_2,
        photo_3: @photo_3,
        buttons_code: @buttons_code,
        button_group_code: @button_group_code,
        fab_code: @fab_code,
        toggle_button_code: @toggle_button_code,
        text_field_code: @text_field_code,
        select_code: @select_code,
        number_field_code: @number_field_code,
        checkbox_code: @checkbox_code,
        switch_code: @switch_code,
        radio_group_code: @radio_group_code,
        slider_code: @slider_code,
        rating_code: @rating_code,
        autocomplete_code: @autocomplete_code,
        transfer_list_code: @transfer_list_code,
        navbar_code: @navbar_code,
        drawer_code: @drawer_code,
        list_code: @list_code,
        box_code: @box_code,
        container_code: @container_code,
        stack_code: @stack_code,
        grid_code: @grid_code,
        divider_code: @divider_code,
        card_code: @card_code,
        icon_code: @icon_code,
        image_list_code: @image_list_code,
        table_code: @table_code,
        paper_code: @paper_code,
        typography_code: @typography_code,
        ripple_code: @ripple_code,
        elevation_code: @elevation_code,
        shape_code: @shape_code,
        theming_code: @theming_code
      )

    ~H"""
    {@style_tag}
    {@hljs_assets}

    <div class="min-h-screen bg-pp-surface-variant text-pp-on-surface lg:flex">
      <.pp_drawer id="app-drawer">
        <:header>PhoenixPaper</:header>
        <.pp_list>
          <.nav_group label="Actions">
            <.pp_list_item href="#buttons">Button</.pp_list_item>
            <.pp_list_item href="#button-group">Button Group</.pp_list_item>
            <.pp_list_item href="#fab">Floating Action Button</.pp_list_item>
            <.pp_list_item href="#toggle-button">Toggle Button</.pp_list_item>
          </.nav_group>
          <.nav_group label="Forms">
            <.pp_list_item href="#text-field">Text Field</.pp_list_item>
            <.pp_list_item href="#select">Select</.pp_list_item>
            <.pp_list_item href="#number-field">Number Field</.pp_list_item>
            <.pp_list_item href="#checkbox">Checkbox</.pp_list_item>
            <.pp_list_item href="#switch">Switch</.pp_list_item>
            <.pp_list_item href="#radio-group">Radio Group</.pp_list_item>
            <.pp_list_item href="#slider">Slider</.pp_list_item>
            <.pp_list_item href="#rating">Rating</.pp_list_item>
            <.pp_list_item href="#autocomplete">Autocomplete</.pp_list_item>
            <.pp_list_item href="#transfer-list">Transfer List</.pp_list_item>
          </.nav_group>
          <.nav_group label="Navigation">
            <.pp_list_item href="#navbar">Navbar</.pp_list_item>
            <.pp_list_item href="#drawer">Drawer</.pp_list_item>
            <.pp_list_item href="#list">List</.pp_list_item>
          </.nav_group>
          <.nav_group label="Layout">
            <.pp_list_item href="#box">Box</.pp_list_item>
            <.pp_list_item href="#container">Container</.pp_list_item>
            <.pp_list_item href="#stack">Stack</.pp_list_item>
            <.pp_list_item href="#grid">Grid</.pp_list_item>
            <.pp_list_item href="#divider">Divider</.pp_list_item>
          </.nav_group>
          <.nav_group label="Data display">
            <.pp_list_item href="#card">Card</.pp_list_item>
            <.pp_list_item href="#icon">Icon</.pp_list_item>
            <.pp_list_item href="#image-list">Image List</.pp_list_item>
            <.pp_list_item href="#table">Table</.pp_list_item>
          </.nav_group>
          <.nav_group label="Surfaces">
            <.pp_list_item href="#paper">Paper</.pp_list_item>
            <.pp_list_item href="#typography">Typography</.pp_list_item>
          </.nav_group>
          <.nav_group label="Helpers">
            <.pp_list_item href="#ripple">Ripple</.pp_list_item>
            <.pp_list_item href="#elevation">Elevation</.pp_list_item>
            <.pp_list_item href="#shape">Shape</.pp_list_item>
            <.pp_list_item href="#theming">Theming</.pp_list_item>
          </.nav_group>
        </.pp_list>
      </.pp_drawer>

      <div class="min-w-0 flex-1">
        <.pp_navbar position="sticky">
          <:leading><.pp_drawer_toggle for="app-drawer" /></:leading>
          PhoenixPaper
          <:actions>
            <.pp_button variant="text" phx-click={JS.remove_attribute("data-pp-theme", to: "html")}>Indigo</.pp_button>
            <.pp_button variant="text" phx-click={JS.set_attribute({"data-pp-theme", "teal"}, to: "html")}>Teal</.pp_button>
            <.pp_button variant="outlined" phx-click={JS.remove_attribute("data-theme", to: "html")}>Light</.pp_button>
            <.pp_button variant="outlined" phx-click={JS.set_attribute({"data-theme", "dark"}, to: "html")}>Dark</.pp_button>
          </:actions>
        </.pp_navbar>

        <.pp_container max_width="lg" class="py-8">
        <.demo_section
          id="buttons"
          title="Button"
          description="The five classic Material variants. Ripples on click by default (see Helpers below)."
          props={[
            {"variant", "raised | flat | outlined | text | icon (default: raised)"},
            {"color", "primary | secondary | tertiary | error (default: primary)"},
            {"elevation", "override the resting elevation, 0-24 (default: nil — variant decides)"},
            {"shape", ":none | :xs | :sm | :md | :lg | :xl | :full (default: :full, a pill)"},
            {"ripple", "boolean — the ripple effect on click/tap (default: true)"},
            {"disabled", "boolean (default: false)"},
            {"loading", "boolean — spinner replaces start_icon, disables the button (default: false)"},
            {":start_icon / :end_icon", "slots — an icon before/after the label"},
            {"type", "button | submit | reset (default: button)"},
            {"paperize", "boolean — apply PhoenixPaper's classes at all (default: true)"},
            {"class", "merged on top via Tails"}
          ]}
          code={@buttons_code}
        >
          <div class="flex flex-col gap-4">
            <div :for={variant <- ~w(raised flat outlined text icon)} class="flex flex-wrap items-center gap-3">
              <span class="w-20 shrink-0 text-xs uppercase opacity-60">{variant}</span>
              <.pp_button :for={color <- ~w(primary secondary tertiary error)} variant={variant} color={color}>
                <span :if={variant == "icon"} class="hero-star" />
                <span :if={variant != "icon"}>{color}</span>
              </.pp_button>
            </div>
            <div class="flex items-center gap-4 border-t border-pp-outline/20 pt-4">
              <.pp_button>Styled by PhoenixPaper</.pp_button>
              <.pp_button paperize={false} class="rounded-none border-4 border-dashed border-fuchsia-500 px-3 py-1 font-mono text-fuchsia-700">
                paperize: false
              </.pp_button>
            </div>
            <div class="flex items-center gap-4 border-t border-pp-outline/20 pt-4">
              <.pp_button variant="outlined">
                <:start_icon><span class="hero-trash" /></:start_icon>
                Delete
              </.pp_button>
              <.pp_button>
                Send
                <:end_icon><span class="hero-check" /></:end_icon>
              </.pp_button>
              <.pp_button loading>
                <:start_icon><span class="hero-trash" /></:start_icon>
                Delete
              </.pp_button>
            </div>
          </div>
        </.demo_section>

        <.demo_section
          id="button-group"
          title="Button Group"
          description="Visually joins a row of buttons into one segmented control by rounding only the outer corners. No group-level variant/color/size that cascades to children like MUI's — HEEx has no context mechanism for that; set each button's own attrs."
          props={[
            {"orientation", "horizontal | vertical (default: horizontal)"},
            {"shape", "corner radius token for the group's outer corners (default: :md)"},
            {"disable_elevation", "boolean — zero out every child button's own elevation shadow (default: false)"},
            {"paperize", "boolean (default: true)"},
            {"class", "merged on top via Tails"}
          ]}
          code={@button_group_code}
        >
          <div class="flex flex-col items-start gap-6">
            <.pp_button_group>
              <.pp_button variant="outlined">Day</.pp_button>
              <.pp_button variant="outlined">Week</.pp_button>
              <.pp_button variant="outlined">Month</.pp_button>
            </.pp_button_group>
            <.pp_button_group orientation="vertical">
              <.pp_button variant="outlined">Day</.pp_button>
              <.pp_button variant="outlined">Week</.pp_button>
              <.pp_button variant="outlined">Month</.pp_button>
            </.pp_button_group>
            <.pp_button_group disable_elevation>
              <.pp_button>Save</.pp_button>
              <.pp_button>Cancel</.pp_button>
            </.pp_button_group>
          </div>
        </.demo_section>

        <.demo_section
          id="fab"
          title="Floating Action Button"
          description="A circular, elevated, icon-only button, or a labeled pill with extended."
          props={[
            {"color", "primary | secondary | tertiary | error (default: secondary)"},
            {"size", "sm | md | lg (default: md)"},
            {"extended", "boolean — labeled pill instead of a fixed circle (default: false)"},
            {"ripple", "boolean (default: true)"},
            {"disabled", "boolean (default: false)"},
            {"paperize", "boolean (default: true)"}
          ]}
          code={@fab_code}
        >
          <div class="flex flex-col gap-4">
            <div class="flex flex-wrap items-center gap-4">
              <span class="w-16 shrink-0 text-xs uppercase opacity-60">size</span>
              <.pp_fab :for={size <- ~w(sm md lg)} size={size}><span class="hero-star" /></.pp_fab>
            </div>
            <div class="flex flex-wrap items-center gap-4">
              <span class="w-16 shrink-0 text-xs uppercase opacity-60">color</span>
              <.pp_fab :for={color <- ~w(primary secondary tertiary error)} color={color}>
                <span class="hero-star" />
              </.pp_fab>
            </div>
            <div class="flex items-center gap-4 border-t border-pp-outline/20 pt-4">
              <.pp_fab extended color="primary">
                <span class="hero-star" /> Create
              </.pp_fab>
            </div>
          </div>
        </.demo_section>

        <.demo_section
          id="toggle-button"
          title="Toggle Button"
          description="A button with a boolean pressed state, filled when pressed. Combine several inside a Button Group for a segmented toggle."
          props={[
            {"pressed", "boolean (default: false)"},
            {"color", "primary | secondary | tertiary | error (default: primary)"},
            {"shape", "corner radius token (default: :md)"},
            {"ripple", "boolean (default: true)"},
            {"disabled", "boolean (default: false)"}
          ]}
          code={@toggle_button_code}
        >
          <div class="flex flex-col gap-4">
            <.pp_toggle_button pressed={@bold_pressed} phx-click="toggle_bold">
              Bold
            </.pp_toggle_button>
            <div class="flex flex-wrap items-center gap-3 border-t border-pp-outline/20 pt-4">
              <span class="w-16 shrink-0 text-xs uppercase opacity-60">pressed</span>
              <.pp_toggle_button :for={color <- ~w(primary secondary tertiary error)} pressed color={color}>
                {color}
              </.pp_toggle_button>
            </div>
          </div>
        </.demo_section>

        <.demo_section
          id="text-field"
          title="Text Field"
          description="A floating-label text field — pure CSS, no JS. outlined (bordered box) or filled (filled background)."
          props={[
            {"label / value / name / id", "standard text field attrs"},
            {"type", "any input type, e.g. text | email | password (default: text)"},
            {"variant", "outlined | filled (default: outlined)"},
            {"shape", "corner radius token (default: :sm)"},
            {"field", "a Phoenix.HTML.FormField from to_form/2 — sets name/id/value for you"},
            {"errors", "list of error strings — switches to the error color and hides helper_text"},
            {"helper_text", "shown below the field when there are no errors"},
            {"disabled", "boolean (default: false)"},
            {"paperize", "boolean (default: true)"}
          ]}
          code={@text_field_code}
        >
          <div class="grid grid-cols-1 gap-6 sm:grid-cols-2">
            <.pp_input label="Outlined (default)" name="outlined_demo" />
            <.pp_input variant="filled" label="Filled" name="filled_demo" />
            <.pp_input label="With helper text" name="helper_demo" helper_text="We'll never share your email." />
            <.pp_input label="With an error" name="error_demo" value="not-an-email" errors={["is not a valid email"]} />
            <.pp_input label="Disabled" name="disabled_demo" value="Can't touch this" disabled />
            <.pp_input paperize={false} label="paperize: false" name="bare_input_demo" class="border-b border-fuchsia-500 px-1 py-1 font-mono text-fuchsia-700" />
          </div>
        </.demo_section>

        <.demo_section
          id="select"
          title="Select"
          description="A native select element styled to match Text Field's outlined/filled variants."
          props={[
            {"options", "list of {label, value} tuples, or plain values"},
            {"prompt", "an empty/placeholder option's label"},
            {"variant", "outlined | filled (default: outlined)"},
            {"field / errors / helper_text", "same as Text Field"},
            {"disabled", "boolean (default: false)"}
          ]}
          code={@select_code}
        >
          <div class="grid grid-cols-1 gap-6 sm:grid-cols-2">
            <.pp_select label="Country" name="country_demo" prompt="Choose one" options={["Canada", "Mexico", "United States"]} />
            <.pp_select variant="filled" label="Country" name="country_filled_demo" prompt="Choose one" options={["Canada", "Mexico", "United States"]} />
          </div>
        </.demo_section>

        <.demo_section
          id="number-field"
          title="Number Field"
          description="A numeric input with increment/decrement stepper buttons — plain onclick JS calling stepUp()/stepDown(), no JS hook."
          props={[
            {"min / max / step", "passed straight to the underlying <input type=\"number\">"},
            {"variant / shape / field / errors / helper_text", "same as Text Field"},
            {"disabled", "boolean (default: false)"}
          ]}
          code={@number_field_code}
        >
          <div class="grid grid-cols-1 gap-6 sm:grid-cols-2">
            <.pp_number_field label="Quantity" name="qty_demo" value={2} min={0} max={10} />
            <.pp_number_field variant="filled" label="Quantity" name="qty_filled_demo" value={2} min={0} max={10} />
          </div>
        </.demo_section>

        <.demo_section
          id="checkbox"
          title="Checkbox"
          description="Includes the hidden-input trick so an unchecked box still submits false. Ripples on click by default — see Helpers below."
          props={[
            {"checked", "boolean (default: nil, meaning unchecked)"},
            {"field", "a Phoenix.HTML.FormField — sets name/id/checked for you"},
            {"label", "text next to the box"},
            {"disabled", "boolean (default: false)"},
            {"ripple", "boolean — the ripple effect on click/tap (default: true)"},
            {"paperize", "false renders a bare native checkbox, no hidden input"}
          ]}
          code={@checkbox_code}
        >
          <div class="flex flex-col gap-3">
            <.pp_checkbox label="Paperized (default)" checked={true} />
            <.pp_checkbox label="Unchecked" />
            <.pp_checkbox paperize={false} label="paperize: false — bare native checkbox" class="size-5" />
          </div>
        </.demo_section>

        <.demo_section
          id="switch"
          title="Switch"
          description="An on/off toggle, structured like Checkbox but rendered as a sliding track/thumb."
          props={[{"checked / field / label / disabled / ripple / paperize", "same shape as Checkbox"}]}
          code={@switch_code}
        >
          <div class="flex flex-col gap-3">
            <.pp_switch label="Paperized (default)" checked={true} name="wifi_demo" />
            <.pp_switch label="Unchecked" name="bluetooth_demo" />
            <.pp_switch paperize={false} label="paperize: false" name="bare_switch_demo" />
          </div>
        </.demo_section>

        <.demo_section
          id="radio-group"
          title="Radio Group"
          description="A labeled set of mutually exclusive radio buttons sharing one name. Ripples on click by default — see Helpers below."
          props={[
            {"options", "list of {label, value} tuples, or plain values"},
            {"value", "the currently selected value"},
            {"label", "the group's legend"},
            {"field / disabled / ripple / paperize", "same as other form controls"}
          ]}
          code={@radio_group_code}
        >
          <.pp_radio_group label="Size" name="size_demo" value="md" options={[{"Small", "sm"}, {"Medium", "md"}, {"Large", "lg"}]} />
        </.demo_section>

        <.demo_section
          id="slider"
          title="Slider"
          description="A native range input colored via CSS accent-color — no ::-webkit-slider-thumb hacks."
          props={[
            {"min / max / step", "default 0 / 100 / 1"},
            {"color", "primary | secondary | tertiary | error (default: primary)"},
            {"label", "shown above the slider with the current value"},
            {"field / disabled / paperize", "same as other form controls"}
          ]}
          code={@slider_code}
        >
          <div class="grid grid-cols-1 gap-6 sm:grid-cols-2">
            <.pp_slider
              :for={color <- ~w(primary secondary tertiary error)}
              name={"volume_#{color}_demo"}
              label={color}
              value={60}
              color={color}
            />
          </div>
        </.demo_section>

        <.demo_section
          id="rating"
          title="Rating"
          description="A row of radio inputs with a pure-CSS hover/checked fill effect — hovering star 3 highlights stars 1-3, no JS."
          props={[
            {"value", "integer, the current/selected rating (default: 0)"},
            {"max", "number of stars (default: 5)"},
            {"readonly", "boolean — renders fixed filled/unfilled spans instead of inputs (default: false)"},
            {"field / disabled / paperize", "same as other form controls"}
          ]}
          code={@rating_code}
        >
          <div class="flex flex-col gap-4">
            <div>
              <p class="mb-2 text-sm opacity-70">Interactive (click a star):</p>
              <.pp_rating id="rating_demo" name="rating_demo" value={3} />
            </div>
            <div>
              <p class="mb-2 text-sm opacity-70">Readonly:</p>
              <.pp_rating readonly value={4} />
            </div>
          </div>
        </.demo_section>

        <.demo_section
          id="autocomplete"
          title="Autocomplete"
          description="A text field with a filtered dropdown. Needs interactive state (query, open, filtered list), so it's a Phoenix.LiveComponent, not a pp_* function — works inside a LiveView only. Filtering runs server-side via phx-change."
          props={[
            {"options", "list of {label, value} tuples, or plain values"},
            {"value / name / label / placeholder", "same intent as Text Field"},
            {"shape / paperize", "same as other form controls"}
          ]}
          code={@autocomplete_code}
        >
          <.live_component
            module={PhoenixPaper.Autocomplete}
            id="country_autocomplete_demo"
            name="country_autocomplete_demo"
            label="Country"
            placeholder="Start typing..."
            options={["Canada", "Mexico", "United States", "United Kingdom", "Uruguay"]}
          />
        </.demo_section>

        <.demo_section
          id="transfer-list"
          title="Transfer List"
          description="Two list boxes with buttons to move checked items between them. Also a Phoenix.LiveComponent — it manages its own left/right split; there's no on_change callback yet."
          props={[
            {"items", "the starting list — everything begins on the left"},
            {"left_label / right_label", "column headers (default: \"Available\" / \"Selected\")"}
          ]}
          code={@transfer_list_code}
        >
          <.live_component module={PhoenixPaper.TransferList} id="permissions_demo" items={["Read", "Write", "Admin", "Billing"]} />
        </.demo_section>

        <.demo_section
          id="navbar"
          title="Navbar"
          description="A horizontal app bar with a leading slot, a title, and trailing actions. The one at the top of this page is a live sticky instance — the fixed position isn't demoed inline since it would overlay the rest of this page."
          props={[
            {"color", "primary | secondary | tertiary | surface (default: primary)"},
            {"elevation", "resting elevation, 0-24 (default: 4)"},
            {"position", "static | sticky | fixed (default: static)"},
            {"paperize", "boolean (default: true)"}
          ]}
          code={@navbar_code}
        >
          <div class="flex flex-col gap-3">
            <.pp_navbar :for={color <- ~w(primary secondary tertiary surface)} class="!static" color={color}>
              {color}
              <:actions>
                <.pp_button variant="icon"><span class="hero-bell" /></.pp_button>
              </:actions>
            </.pp_navbar>
          </div>
        </.demo_section>

        <.demo_section
          id="drawer"
          title="Drawer"
          description="A navigation drawer, persistent on large screens and toggled by a hamburger button below that breakpoint — pure CSS via a hidden checkbox, no JS. The drawer on the left of this page is a live instance; try shrinking your window."
          props={[
            {"id", "required — builds the mobile toggle checkbox's id as \"\#{id}-toggle\""},
            {"paperize", "boolean (default: true)"},
            {"pp_drawer_toggle for=", "a hamburger <label> pointing at the given drawer's id — works from anywhere on the page, not just inside the drawer"}
          ]}
          code={@drawer_code}
        >
          <p class="text-sm opacity-70">See the left edge of this page — that's this exact component, live.</p>
        </.demo_section>

        <.demo_section
          id="list"
          title="List"
          description="ListItem renders as a link (href/navigate/patch) or a plain div otherwise, so a static info row doesn't need to be clickable. Also usable standalone, e.g. inside a Card."
          props={[
            {"pp_list", "the container, role=\"list\""},
            {"pp_list_item href/navigate/patch", "makes it a link; active/disabled/ripple as usual"},
            {"pp_list_item :leading / :secondary / :trailing", "optional slots for an icon, a subtitle line, a badge"},
            {"pp_list_subheader", "a small uppercase section label"},
            {"pp_divider inset", "boolean — indent past a leading icon column instead of spanning full width"}
          ]}
          code={@list_code}
        >
          <.pp_list>
            <.pp_list_subheader>Main</.pp_list_subheader>
            <.pp_list_item href="#list" active>
              <:leading><span class="hero-home" /></:leading>
              Home
              <:secondary>Overview</:secondary>
            </.pp_list_item>
            <.pp_list_item href="#list">
              <:leading><span class="hero-cog" /></:leading>
              Settings
            </.pp_list_item>
            <.pp_divider inset />
            <.pp_list_item disabled>
              <:leading><span class="hero-bell" /></:leading>
              Locked
            </.pp_list_item>
          </.pp_list>
        </.demo_section>

        <.demo_section
          id="box"
          title="Box"
          description="A bare div/span/pre — no paperize attr at all, since there's no default visual style to strip."
          props={[{"tag", "div | span | pre (default: div)"}]}
          code={@box_code}
        >
          <div class="flex flex-col items-start gap-3">
            <.pp_box class="rounded-lg bg-pp-surface-variant p-4">A div (default).</.pp_box>
            <.pp_box tag="span" class="rounded bg-pp-surface-variant px-2 py-1">A span.</.pp_box>
            <.pp_box tag="pre" class="rounded-lg bg-pp-surface-variant p-4">A pre, whitespace preserved.</.pp_box>
          </div>
        </.demo_section>

        <.demo_section
          id="container"
          title="Container"
          description="A centered, width-constrained wrapper — uses Tailwind's own sm/md/lg/xl/2xl screen scale rather than replicating MUI's specific pixel breakpoints. This whole page's content sits inside one."
          props={[
            {"max_width", "sm | md | lg | xl | 2xl | full (default: lg)"},
            {"paperize", "boolean (default: true)"}
          ]}
          code={@container_code}
        >
          <div class="flex flex-col gap-2">
            <.pp_container
              :for={width <- ~w(sm md lg xl 2xl full)}
              max_width={width}
              class="!mx-0 rounded-lg bg-pp-surface-variant py-2 text-center text-sm"
            >
              max_width="{width}"
            </.pp_container>
          </div>
        </.demo_section>

        <.demo_section
          id="stack"
          title="Stack"
          description="A one-dimensional flex layout with consistent spacing between children. No auto-divider — add a Divider between children yourself."
          props={[
            {"direction", "row | column (default: column)"},
            {"spacing", "a Spacing token, :none | :xs | :sm | :md | :lg | :xl | :2xl (default: :md)"},
            {"wrap", "boolean (default: false)"}
          ]}
          code={@stack_code}
        >
          <div class="flex flex-col items-start gap-6">
            <div>
              <p class="mb-2 text-sm opacity-70">direction="row":</p>
              <.pp_stack direction="row" spacing={:sm}>
                <.pp_button>Save</.pp_button>
                <.pp_button variant="outlined">Cancel</.pp_button>
              </.pp_stack>
            </div>
            <div>
              <p class="mb-2 text-sm opacity-70">direction="column":</p>
              <.pp_stack direction="column" spacing={:sm}>
                <.pp_button>Save</.pp_button>
                <.pp_button variant="outlined">Cancel</.pp_button>
              </.pp_stack>
            </div>
          </div>
        </.demo_section>

        <.demo_section
          id="grid"
          title="Grid"
          description="A 12-column grid. GridItem's span sets the base column span; md optionally overrides it at the md: breakpoint and up — that's the only responsive breakpoint supported (see AGENTS.md for why)."
          props={[
            {"pp_grid spacing", "a Spacing token (default: :md)"},
            {"pp_grid_item span", "1-12 (default: 12)"},
            {"pp_grid_item md", "1-12, overrides span at md: and up (default: nil, no override)"}
          ]}
          code={@grid_code}
        >
          <.pp_grid>
            <.pp_grid_item span={12} md={4} class="rounded-lg bg-pp-surface-variant p-4 text-center text-sm">Sidebar</.pp_grid_item>
            <.pp_grid_item span={12} md={8} class="rounded-lg bg-pp-surface-variant p-4 text-center text-sm">Content</.pp_grid_item>
          </.pp_grid>
        </.demo_section>

        <.demo_section
          id="divider"
          title="Divider"
          description="A thin separator line, most often between sections of a List."
          props={[{"inset", "boolean — indent past a leading icon/avatar column instead of spanning full width (default: false)"}]}
          code={@divider_code}
        >
          <div class="flex flex-col gap-2">
            <span class="text-sm">Above</span>
            <.pp_divider />
            <span class="text-sm">Below</span>
          </div>
          <div class="mt-4 flex flex-col gap-2 border-t border-pp-outline/20 pt-4">
            <span class="pl-10 text-sm">Above (inset)</span>
            <.pp_divider inset />
            <span class="pl-10 text-sm">Below (inset)</span>
          </div>
        </.demo_section>

        <.demo_section
          id="card"
          title="Card"
          description="A surface container with optional title and actions slots."
          props={[
            {"elevation", "resting elevation, 0-24 (default: 1)"},
            {"padding", "a Spacing token (default: :md)"},
            {"shape", "corner radius token (default: :lg)"},
            {"paperize", "boolean (default: true)"}
          ]}
          code={@card_code}
        >
          <div class="flex flex-col gap-6">
            <.pp_card class="max-w-sm">
              <:title>Account</:title>
              You have no pending invoices.
              <:actions>
                <.pp_button variant="text">Dismiss</.pp_button>
              </:actions>
            </.pp_card>
            <div class="flex flex-wrap gap-4 border-t border-pp-outline/20 pt-6">
              <.pp_card :for={padding <- ~w(none xs sm md lg xl 2xl)a} padding={padding} class="w-32 text-center text-xs">
                {padding}
              </.pp_card>
            </div>
          </div>
        </.demo_section>

        <.demo_section
          id="icon"
          title="Icon"
          description="Just renders the app's existing heroicon classes — no bundled icon set, no extra dependency. This demo hand-rolls a few generic glyphs since it has no asset pipeline; a real app already has hero-* from mix phx.new."
          props={[
            {"name", "a heroicon class, e.g. \"hero-check\" (required)"},
            {"paperize", "boolean — only affects default sizing, not which icon shows (default: true)"}
          ]}
          code={@icon_code}
        >
          <div class="flex items-center gap-4">
            <.pp_icon name="hero-check" class="text-pp-tertiary" />
            <.pp_icon name="hero-star" class="text-pp-secondary" />
            <.pp_icon name="hero-home" class="text-pp-primary" />
            <.pp_icon name="hero-bell" class="text-pp-error" />
          </div>
        </.demo_section>

        <.demo_section
          id="image-list"
          title="Image List"
          description="A grid gallery of images, in the spirit of MUI's ImageList (the standard variant — masonry/quilted/woven aren't implemented). ImageListItem is an image plus an optional title/subtitle overlay bar."
          props={[
            {"pp_image_list cols", "1-6 (default: 3)"},
            {"pp_image_list_item src / alt", "the image"},
            {"pp_image_list_item title / subtitle", "an overlay bar along the bottom edge, omitted if no title"}
          ]}
          code={@image_list_code}
        >
          <.pp_image_list cols={3}>
            <.pp_image_list_item src={@photo_1} title="Breakfast" />
            <.pp_image_list_item src={@photo_2} title="Burger" subtitle="Restaurant" />
            <.pp_image_list_item src={@photo_3} />
          </.pp_image_list>
        </.demo_section>

        <.demo_section
          id="table"
          title="Table"
          description="A family of small components — Table, TableContainer, TableHead, TableBody, TableRow, TableCell, TableFooter — composed by hand like MUI's own Table parts. dense/sticky_header/striped cascade to descendant cells via CSS, not a prop threaded through every cell (see AGENTS.md)."
          props={[
            {"pp_table dense / sticky_header", "tighter cell padding / pins the header while scrolling"},
            {"pp_table_body striped", "alternating row background"},
            {"pp_table_row selected", "a stronger, persistent highlight"},
            {"pp_table_cell variant", "\"head\" (th) | \"body\" (td, default)"},
            {"pp_table_cell align", "left | center | right"},
            {"pp_table_cell sortable / sort_direction", "a clickable header arrow — wire your own phx-click, this is presentation only"}
          ]}
          code={@table_code}
        >
          <div class="flex flex-col gap-6">
            <.pp_table_container>
              <.pp_table>
                <.pp_table_head>
                  <.pp_table_row>
                    <.pp_table_cell variant="head" sortable sort_direction="asc" phx-click="sort">Dessert</.pp_table_cell>
                    <.pp_table_cell variant="head" align="right" sortable phx-click="sort">Calories</.pp_table_cell>
                    <.pp_table_cell variant="head" align="right">Fat (g)</.pp_table_cell>
                  </.pp_table_row>
                </.pp_table_head>
                <.pp_table_body striped>
                  <.pp_table_row>
                    <.pp_table_cell>Frozen yoghurt</.pp_table_cell>
                    <.pp_table_cell align="right">159</.pp_table_cell>
                    <.pp_table_cell align="right">6.0</.pp_table_cell>
                  </.pp_table_row>
                  <.pp_table_row selected>
                    <.pp_table_cell>Ice cream sandwich</.pp_table_cell>
                    <.pp_table_cell align="right">237</.pp_table_cell>
                    <.pp_table_cell align="right">9.0</.pp_table_cell>
                  </.pp_table_row>
                </.pp_table_body>
                <.pp_table_footer>
                  <.pp_table_row>
                    <.pp_table_cell>Total</.pp_table_cell>
                    <.pp_table_cell align="right">396</.pp_table_cell>
                    <.pp_table_cell align="right">15.0</.pp_table_cell>
                  </.pp_table_row>
                </.pp_table_footer>
              </.pp_table>
            </.pp_table_container>

            <div>
              <p class="mb-2 text-sm opacity-70">dense + sticky_header (scroll the box):</p>
              <.pp_table_container class="max-h-40 overflow-y-auto">
                <.pp_table dense sticky_header>
                  <.pp_table_head>
                    <.pp_table_row>
                      <.pp_table_cell variant="head">Dessert</.pp_table_cell>
                      <.pp_table_cell variant="head" align="right">Calories</.pp_table_cell>
                    </.pp_table_row>
                  </.pp_table_head>
                  <.pp_table_body>
                    <.pp_table_row :for={{name, cal} <- [{"Frozen yoghurt", 159}, {"Ice cream sandwich", 237}, {"Eclair", 262}, {"Cupcake", 305}, {"Gingerbread", 356}]}>
                      <.pp_table_cell>{name}</.pp_table_cell>
                      <.pp_table_cell align="right">{cal}</.pp_table_cell>
                    </.pp_table_row>
                  </.pp_table_body>
                </.pp_table>
              </.pp_table_container>
            </div>
          </div>
        </.demo_section>

        <.demo_section
          id="paper"
          title="Paper"
          description="The base surface — a background, an elevation shadow, and rounded corners. No padding, no slots. Card is built by composing this instead of duplicating its classes."
          props={[
            {"elevation", "resting elevation, 0-24 (default: 1)"},
            {"shape", "corner radius token (default: :lg)"},
            {"component", "overrides the data-pp-component marker — used by components like Card (default: \"paper\")"},
            {"paperize", "boolean (default: true)"}
          ]}
          code={@paper_code}
        >
          <.pp_paper elevation={4} class="p-4">A raised surface — Card is built on this.</.pp_paper>
        </.demo_section>

        <.demo_section
          id="typography"
          title="Typography"
          description="variant picks both the rendered tag and the text classes together — h1..h6, subtitle1/2, body1/2, caption, overline, button, code."
          props={[
            {"variant", "h1..h6 | subtitle1 | subtitle2 | body1 | body2 | caption | overline | button | code (default: body1)"},
            {"paperize", "boolean (default: true)"}
          ]}
          code={@typography_code}
        >
          <div class="flex flex-col gap-2">
            <.pp_typography variant="h1">h1. Heading</.pp_typography>
            <.pp_typography variant="h2">h2. Heading</.pp_typography>
            <.pp_typography variant="h3">h3. Heading</.pp_typography>
            <.pp_typography variant="h4">h4. Heading</.pp_typography>
            <.pp_typography variant="h5">h5. Heading</.pp_typography>
            <.pp_typography variant="h6">h6. Heading</.pp_typography>
            <.pp_typography variant="subtitle1">subtitle1. Manage your profile, notifications, and billing.</.pp_typography>
            <.pp_typography variant="subtitle2">subtitle2. Manage your profile, notifications, and billing.</.pp_typography>
            <.pp_typography variant="body1">body1. Manage your profile, notifications, and billing.</.pp_typography>
            <.pp_typography variant="body2">body2. Manage your profile, notifications, and billing.</.pp_typography>
            <.pp_typography variant="caption">caption. Last updated 2 minutes ago</.pp_typography>
            <.pp_typography variant="overline">overline. New</.pp_typography>
            <.pp_typography variant="button">button. Save changes</.pp_typography>
            <.pp_typography variant="code">mix phx.new my_app</.pp_typography>
          </div>
        </.demo_section>

        <.demo_section
          id="ripple"
          title="Ripple (helper)"
          description="The Material ripple effect — a circle that expands from the click point and fades out. Vanilla inline onclick, no JS hook/bundler. Try clicking the buttons above."
          props={[
            {"ripple", "the boolean prop on Button, Fab, ToggleButton, Switch, Checkbox, RadioGroup, and a linked ListItem — default true, and always off when paperize is false"},
            {"PhoenixPaper.Ripple.on_click/1", "returns the script, or nil when disabled (so the attribute is dropped entirely)"},
            {"PhoenixPaper.Ripple.container_classes/1", "the \"relative overflow-hidden\" the ripple needs to stay clipped"}
          ]}
          code={@ripple_code}
        >
          <div class="flex items-center gap-4">
            <.pp_button>Ripples (default)</.pp_button>
            <.pp_button ripple={false}>No ripple</.pp_button>
          </div>
        </.demo_section>

        <.demo_section
          id="elevation"
          title="Elevation (helper)"
          description="PhoenixPaper.Elevation.class/1 maps a Material dp level (0-24, clamped) to a pp-elevation-N class — a two-layer shadow approximating Google's official table."
          props={[{"Elevation.class(level)", "returns the literal \"pp-elevation-N\" class name"}]}
          code={@elevation_code}
        >
          <div class="flex flex-wrap gap-6">
            <div :for={level <- [0, 1, 2, 4, 8, 16, 24]} class={["flex size-16 items-center justify-center rounded-lg bg-pp-surface text-xs", PhoenixPaper.Elevation.class(level)]}>
              {level}dp
            </div>
          </div>
        </.demo_section>

        <.demo_section
          id="shape"
          title="Shape (helper)"
          description="PhoenixPaper.Shape.class/1,2 maps a token to a literal rounded-* class, optionally scoped to an edge (:top/:bottom) for shapes like the filled text field that only round two corners."
          props={[
            {"Shape.class(token)", "all four corners"},
            {"Shape.class(token, :top | :bottom)", "only those two corners"}
          ]}
          code={@shape_code}
        >
          <div class="flex flex-wrap items-end gap-6">
            <div :for={token <- ~w(none xs sm md lg xl full)a} class="flex flex-col items-center gap-2">
              <div class={["size-14 border-2 border-pp-primary bg-pp-primary/10", PhoenixPaper.Shape.class(token)]} />
              <span class="text-xs opacity-60">{token}</span>
            </div>
          </div>
        </.demo_section>

        <.demo_section
          id="theming"
          title="Theming"
          description="Colors are Tailwind v4 theme tokens backed by CSS custom properties, namespaced pp- so they never collide with daisyUI. Try the Indigo/Teal/Light/Dark buttons in the navbar above — no page reload, just flipping data-theme/data-pp-theme on the root html element."
          props={[
            {"data-theme=\"dark\"", "on any ancestor — the same attribute daisyUI/Phoenix 1.8's generated app.css already use"},
            {"data-pp-theme=\"teal\"", "opts into the bundled alternate palette"},
            {"custom theme", "override the --color-pp-* variables from your own stylesheet — no build step, no JS config"}
          ]}
          code={@theming_code}
        >
          <p class="text-sm opacity-70">Use the theme buttons in the navbar — this section is just documentation.</p>
        </.demo_section>
        </.pp_container>
      </div>
    </div>
    """
  end
end

PhoenixPlayground.start(live: PhoenixPaperDemo, open_browser: false)
