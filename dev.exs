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
# navigation, a sticky `PhoenixPaper.AppBar`, and one section per component
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

  attr(:id, :string, required: true)
  attr(:title, :string, required: true)
  attr(:description, :string, default: nil)
  attr(:props, :list, default: [], doc: "list of {name, description} tuples")
  attr(:code, :string, required: true)

  slot(:inner_block, required: true)

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

  attr(:label, :string, required: true)
  slot(:inner_block, required: true)

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
  .hero-check, .hero-star, .hero-home, .hero-cog, .hero-bell, .hero-trash,
  .hero-chevron-right, .hero-user, .hero-sun-mini, .hero-moon-mini, .hero-x-mark-mini {
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
  .hero-chevron-right {
    mask-image: url('data:image/svg+xml;utf8,<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="none" stroke="black" stroke-width="2"><path d="M9 5l7 7-7 7"/></svg>');
    -webkit-mask-image: url('data:image/svg+xml;utf8,<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="none" stroke="black" stroke-width="2"><path d="M9 5l7 7-7 7"/></svg>');
  }
  .hero-user {
    mask-image: url('data:image/svg+xml;utf8,<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="black"><circle cx="12" cy="8" r="4"/><path d="M4 21c0-4.4 3.6-7 8-7s8 2.6 8 7"/></svg>');
    -webkit-mask-image: url('data:image/svg+xml;utf8,<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="black"><circle cx="12" cy="8" r="4"/><path d="M4 21c0-4.4 3.6-7 8-7s8 2.6 8 7"/></svg>');
  }
  .hero-sun-mini {
    mask-image: url('data:image/svg+xml;utf8,<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="black" stroke="black" stroke-width="2"><circle cx="12" cy="12" r="4"/><path d="M12 2v2M12 20v2M4 12H2M22 12h-2M5.6 5.6l1.4 1.4M17 17l1.4 1.4M5.6 18.4L7 17M17 7l1.4-1.4"/></svg>');
    -webkit-mask-image: url('data:image/svg+xml;utf8,<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="black" stroke="black" stroke-width="2"><circle cx="12" cy="12" r="4"/><path d="M12 2v2M12 20v2M4 12H2M22 12h-2M5.6 5.6l1.4 1.4M17 17l1.4 1.4M5.6 18.4L7 17M17 7l1.4-1.4"/></svg>');
  }
  .hero-moon-mini {
    mask-image: url('data:image/svg+xml;utf8,<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="black"><path d="M20 14.5A8.5 8.5 0 1110.2 4.3 7 7 0 0020 14.5z"/></svg>');
    -webkit-mask-image: url('data:image/svg+xml;utf8,<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="black"><path d="M20 14.5A8.5 8.5 0 1110.2 4.3 7 7 0 0020 14.5z"/></svg>');
  }
  .hero-x-mark-mini {
    mask-image: url('data:image/svg+xml;utf8,<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="none" stroke="black" stroke-width="3"><path d="M6 6l12 12M18 6L6 18"/></svg>');
    -webkit-mask-image: url('data:image/svg+xml;utf8,<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="none" stroke="black" stroke-width="3"><path d="M6 6l12 12M18 6L6 18"/></svg>');
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
  <.pp_input variant="outlined" label="Outlined (default)" name="outlined_demo" />
  <.pp_input variant="filled" label="Filled" name="filled_demo" />
  <.pp_input variant="standard" label="Standard" name="standard_demo" />
  <.pp_input label="With an error" name="error_demo" value="not-an-email" errors={["is not a valid email"]} />
  <.pp_input color="secondary" label="Secondary" name="color_secondary_demo" />
  <.pp_input size="small" label="Small" name="size_small_demo" />

  <.pp_input label="Amount" name="amount_demo" value="42.00">
    <:start_adornment>$</:start_adornment>
    <:end_adornment>USD</:end_adornment>
  </.pp_input>

  <.pp_input multiline rows={3} label="Bio" name="bio_demo" />
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

  @theme_toggle_code ~S"""
  <.pp_theme_toggle />

  <%!-- accurate initial state, a scoped target, and persisting the choice server-side --%>
  <.pp_theme_toggle
    label="Dark mode"
    default_checked={@dark_mode?}
    target="#preview"
    on_toggle={JS.push("save_theme_preference")}
  />
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
  <.pp_slider name="volume" label="Volume" value={60} />

  <%!-- size --%>
  <.pp_slider name="volume_small" label="Small" value={60} size="small" />

  <%!-- colors --%>
  <.pp_slider :for={color <- ~w(primary secondary tertiary error)} name={"volume_#{color}"} label={color} value={60} color={color} />

  <%!-- track modes --%>
  <.pp_slider name="volume_no_track" label="track: none" value={60} track="none" />
  <.pp_slider name="volume_inverted" label="track: inverted" value={60} track="inverted" />

  <%!-- discrete marks, evenly spaced --%>
  <.pp_slider name="volume_marks" label="Discrete (marks)" value={40} step={20} marks={true} />

  <%!-- custom labeled marks --%>
  <.pp_slider
    name="temperature"
    label="Temperature"
    value={30}
    min={0}
    max={100}
    marks={[{0, "0°C"}, {30, "30°C"}, {60, "60°C"}, {100, "100°C"}]}
  />

  <%!-- range slider: a {low, high} tuple instead of a single number --%>
  <.pp_slider name="price" label="Price range" value={{20, 80}} />

  <%!-- vertical --%>
  <.pp_slider name="volume_vertical" orientation="vertical" value={60} />

  <.pp_slider name="volume_disabled" label="Disabled" value={30} disabled />
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

  @app_bar_code ~S"""
  <.pp_app_bar position="sticky">
    <:leading><.pp_drawer_toggle for="app-drawer" /></:leading>
    My App
    <:actions>
      <.pp_button variant="icon"><.pp_icon name="hero-bell" /></.pp_button>
    </:actions>
  </.pp_app_bar>

  <.pp_app_bar :for={color <- ~w(primary secondary tertiary surface transparent)} color={color} class="!static">
    {color}
    <:actions>
      <.pp_button variant="icon"><.pp_icon name="hero-bell" /></.pp_button>
    </:actions>
  </.pp_app_bar>

  <.pp_app_bar variant="dense" class="!static">
    Dense variant
  </.pp_app_bar>
  """

  @drawer_code ~S"""
  <.pp_app_bar>
    <:leading><.pp_drawer_toggle for="app-drawer" /></:leading>
    My App
  </.pp_app_bar>

  <.pp_drawer id="app-drawer" color="primary">
    <:header>My App</:header>
    <.pp_list>
      <.pp_list_item href="/" active={@current_path == "/"}>Home</.pp_list_item>
    </.pp_list>
  </.pp_drawer>
  """

  @tabs_code ~S"""
  <.pp_tabs id="demo-tabs">
    <.pp_tab id="demo-tabs" value="one" default_selected>One</.pp_tab>
    <.pp_tab id="demo-tabs" value="two">Two</.pp_tab>
    <.pp_tab id="demo-tabs" value="three" disabled>Three (disabled)</.pp_tab>
  </.pp_tabs>

  <.pp_tab_panel id="demo-tabs" value="one" default_selected>Content one.</.pp_tab_panel>
  <.pp_tab_panel id="demo-tabs" value="two">Content two.</.pp_tab_panel>
  <.pp_tab_panel id="demo-tabs" value="three">Content three.</.pp_tab_panel>

  <%!-- with icons, secondary color, vertical orientation --%>
  <.pp_tabs id="vertical-tabs" orientation="vertical">
    <.pp_tab id="vertical-tabs" value="a" orientation="vertical" color="secondary" default_selected>
      <:icon><.pp_icon name="hero-home" /></:icon>
      Home
    </.pp_tab>
    <.pp_tab id="vertical-tabs" value="b" orientation="vertical" color="secondary">
      <:icon><.pp_icon name="hero-user" /></:icon>
      Profile
    </.pp_tab>
  </.pp_tabs>
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

  @breadcrumbs_code ~S"""
  <.pp_breadcrumbs>
    <:item navigate="/">Home</:item>
    <:item navigate="/catalog">Catalog</:item>
    <:item>Current product</:item>
  </.pp_breadcrumbs>

  <%!-- custom separator slot, e.g. an icon --%>
  <.pp_breadcrumbs>
    <:separator><.pp_icon name="hero-chevron-right" class="size-4" /></:separator>
    <:item navigate="/">Home</:item>
    <:item navigate="/settings">Settings</:item>
    <:item>Profile</:item>
  </.pp_breadcrumbs>

  <%!-- beyond max_items, collapses with a clickable ellipsis (pure CSS) --%>
  <.pp_breadcrumbs max_items={3}>
    <:item navigate="/one">One</:item>
    <:item navigate="/two">Two</:item>
    <:item navigate="/three">Three</:item>
    <:item navigate="/four">Four</:item>
    <:item>Five</:item>
  </.pp_breadcrumbs>
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

  @badge_code ~S"""
  <.pp_badge content={4}>
    <.pp_icon name="hero-bell" />
  </.pp_badge>

  <.pp_badge content={150}>
    <.pp_icon name="hero-bell" />
  </.pp_badge>

  <.pp_badge variant="dot" color="success">
    <.pp_icon name="hero-user" />
  </.pp_badge>

  <%!-- overlap="circular" pulls the badge inward to sit on a circular avatar --%>
  <.pp_badge content={1} overlap="circular" color="primary">
    <span class="inline-flex size-10 items-center justify-center rounded-full bg-pp-surface-variant">
      <.pp_icon name="hero-user" />
    </span>
  </.pp_badge>
  """

  @chip_code ~S"""
  <.pp_chip>Basic</.pp_chip>
  <.pp_chip variant="outlined" color="primary">Outlined</.pp_chip>
  <.pp_chip color="success">Success</.pp_chip>
  <.pp_chip size="small">Small</.pp_chip>

  <.pp_chip>
    Tagged
    <:icon><.pp_icon name="hero-check" /></:icon>
  </.pp_chip>

  <.pp_chip
    :for={tag <- @chips}
    deletable
    on_delete={JS.push("delete_chip", value: %{chip: tag})}
  >
    {tag}
  </.pp_chip>

  <.pp_chip clickable phx-click="select_filter">Clickable</.pp_chip>
  <.pp_chip clickable disabled>Disabled</.pp_chip>
  """

  @tooltip_code ~S"""
  <.pp_tooltip title="Delete">
    <.pp_button variant="icon"><.pp_icon name="hero-trash" /></.pp_button>
  </.pp_tooltip>

  <.pp_tooltip title="Bottom" placement="bottom">
    <.pp_button variant="outlined">Bottom</.pp_button>
  </.pp_tooltip>

  <.pp_tooltip title="With an arrow" arrow>
    <.pp_button variant="outlined">Arrow</.pp_button>
  </.pp_tooltip>
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

  @accordion_code ~S"""
  <.pp_accordion id="acc1">
    <.pp_accordion_summary id="acc1">Accordion 1</.pp_accordion_summary>
    <.pp_accordion_details id="acc1">
      This is the content of the first accordion.
    </.pp_accordion_details>
    <.pp_accordion_actions id="acc1">
      <.pp_button variant="text">Cancel</.pp_button>
      <.pp_button variant="text">Save</.pp_button>
    </.pp_accordion_actions>
  </.pp_accordion>

  <.pp_accordion id="acc2" default_expanded>
    <.pp_accordion_summary id="acc2">Accordion 2 (default expanded)</.pp_accordion_summary>
    <.pp_accordion_details id="acc2">This one starts open.</.pp_accordion_details>
  </.pp_accordion>

  <.pp_accordion id="acc3" disabled>
    <.pp_accordion_summary id="acc3">Accordion 3 (disabled)</.pp_accordion_summary>
    <.pp_accordion_details id="acc3">Can't be opened.</.pp_accordion_details>
  </.pp_accordion>

  <%!-- exclusive group: same name, radios instead of checkboxes --%>
  <.pp_accordion id="faq1" name="faq">
    <.pp_accordion_summary id="faq1">FAQ 1</.pp_accordion_summary>
    <.pp_accordion_details id="faq1">Answer 1</.pp_accordion_details>
  </.pp_accordion>
  <.pp_accordion id="faq2" name="faq">
    <.pp_accordion_summary id="faq2">FAQ 2</.pp_accordion_summary>
    <.pp_accordion_details id="faq2">Answer 2</.pp_accordion_details>
  </.pp_accordion>
  """

  @alert_code ~S"""
  <.pp_alert severity="success">Changes saved.</.pp_alert>
  <.pp_alert severity="info">A new update is available.</.pp_alert>
  <.pp_alert severity="warning" variant="outlined">Check your input.</.pp_alert>
  <.pp_alert severity="error" variant="filled">
    <:title>Error</:title>
    Could not save your changes.
    <:action><.pp_button variant="text">Retry</.pp_button></:action>
  </.pp_alert>
  """

  @backdrop_code ~S"""
  <.pp_button phx-click="toggle_backdrop">Show backdrop</.pp_button>

  <.pp_backdrop open={@show_backdrop} phx-click="toggle_backdrop">
    <span class="inline-block size-10 animate-spin rounded-full border-4 border-white border-t-transparent" />
  </.pp_backdrop>
  """

  @dialog_code ~S"""
  <.pp_button phx-click={PhoenixPaper.Dialog.show("confirm-delete")}>
    Delete
  </.pp_button>

  <.pp_dialog id="confirm-delete">
    <:title>Delete this item?</:title>
    This can't be undone.
    <:actions>
      <.pp_button variant="text" phx-click={PhoenixPaper.Dialog.hide("confirm-delete")}>
        Cancel
      </.pp_button>
      <.pp_button color="error" phx-click={PhoenixPaper.Dialog.hide("confirm-delete")}>
        Delete
      </.pp_button>
    </:actions>
  </.pp_dialog>
  """

  @progress_code ~S"""
  <.pp_progress value={72} />
  <.pp_progress />
  <.pp_progress variant="circular" value={72} />
  <.pp_progress variant="circular" />
  """

  @skeleton_code ~S"""
  <.pp_skeleton variant="circular" width={40} height={40} />
  <.pp_skeleton />
  <.pp_skeleton width="60%" />
  <.pp_skeleton variant="rectangular" height={100} />
  <.pp_skeleton variant="rounded" height={100} animation="wave" />
  """

  @snackbar_code ~S"""
  <.pp_snackbar>
    Changes saved
    <:action>
      <.pp_button variant="text" class="!text-pp-surface" phx-click="dismiss">Undo</.pp_button>
    </:action>
  </.pp_snackbar>

  <.pp_snackbar anchor_origin="top-right" transition="slide">
    Copied to clipboard
  </.pp_snackbar>
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
    {:ok,
     assign(socket,
       page_title: "PhoenixPaper catalog",
       bold_pressed: false,
       show_backdrop: false,
       chips: ["React", "Elixir", "Phoenix", "LiveView"]
     )}
  end

  def handle_event("toggle_bold", _params, socket) do
    {:noreply, update(socket, :bold_pressed, &(!&1))}
  end

  def handle_event("toggle_backdrop", _params, socket) do
    {:noreply, update(socket, :show_backdrop, &(!&1))}
  end

  # Table's sortable header cells are presentation-only (see TableCell's
  # moduledoc) — this demo doesn't actually reorder the rows, just proves
  # the click reaches the LiveView instead of crashing it (a real app would
  # re-query/re-sort its data and re-render here).
  def handle_event("sort", _params, socket) do
    {:noreply, socket}
  end

  # Snackbar is presentation-only (see its moduledoc) — this demo's "Undo"
  # doesn't do anything, just proves the click reaches the LiveView instead
  # of crashing it.
  def handle_event("dismiss", _params, socket) do
    {:noreply, socket}
  end

  def handle_event("delete_chip", %{"chip" => chip}, socket) do
    {:noreply, update(socket, :chips, &List.delete(&1, chip))}
  end

  # Chip's clickable variant is presentation-only in this demo — a real app
  # would toggle its own filter state here, the same as Table's "sort".
  def handle_event("select_filter", _params, socket) do
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
        theme_toggle_code: @theme_toggle_code,
        radio_group_code: @radio_group_code,
        slider_code: @slider_code,
        rating_code: @rating_code,
        autocomplete_code: @autocomplete_code,
        transfer_list_code: @transfer_list_code,
        app_bar_code: @app_bar_code,
        drawer_code: @drawer_code,
        tabs_code: @tabs_code,
        list_code: @list_code,
        breadcrumbs_code: @breadcrumbs_code,
        box_code: @box_code,
        container_code: @container_code,
        stack_code: @stack_code,
        grid_code: @grid_code,
        divider_code: @divider_code,
        card_code: @card_code,
        badge_code: @badge_code,
        chip_code: @chip_code,
        tooltip_code: @tooltip_code,
        icon_code: @icon_code,
        image_list_code: @image_list_code,
        table_code: @table_code,
        paper_code: @paper_code,
        typography_code: @typography_code,
        accordion_code: @accordion_code,
        alert_code: @alert_code,
        backdrop_code: @backdrop_code,
        dialog_code: @dialog_code,
        progress_code: @progress_code,
        skeleton_code: @skeleton_code,
        snackbar_code: @snackbar_code,
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
            <.pp_list_item href="#theme-toggle">Theme Toggle</.pp_list_item>
            <.pp_list_item href="#radio-group">Radio Group</.pp_list_item>
            <.pp_list_item href="#slider">Slider</.pp_list_item>
            <.pp_list_item href="#rating">Rating</.pp_list_item>
            <.pp_list_item href="#autocomplete">Autocomplete</.pp_list_item>
            <.pp_list_item href="#transfer-list">Transfer List</.pp_list_item>
          </.nav_group>
          <.nav_group label="Navigation">
            <.pp_list_item href="#app-bar">App Bar</.pp_list_item>
            <.pp_list_item href="#drawer">Drawer</.pp_list_item>
            <.pp_list_item href="#tabs">Tabs</.pp_list_item>
            <.pp_list_item href="#breadcrumbs">Breadcrumbs</.pp_list_item>
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
            <.pp_list_item href="#badge">Badge</.pp_list_item>
            <.pp_list_item href="#chip">Chip</.pp_list_item>
            <.pp_list_item href="#tooltip">Tooltip</.pp_list_item>
            <.pp_list_item href="#icon">Icon</.pp_list_item>
            <.pp_list_item href="#image-list">Image List</.pp_list_item>
            <.pp_list_item href="#table">Table</.pp_list_item>
          </.nav_group>
          <.nav_group label="Surfaces">
            <.pp_list_item href="#paper">Paper</.pp_list_item>
            <.pp_list_item href="#typography">Typography</.pp_list_item>
            <.pp_list_item href="#accordion">Accordion</.pp_list_item>
          </.nav_group>
          <.nav_group label="Feedback">
            <.pp_list_item href="#alert">Alert</.pp_list_item>
            <.pp_list_item href="#backdrop">Backdrop</.pp_list_item>
            <.pp_list_item href="#dialog">Dialog</.pp_list_item>
            <.pp_list_item href="#progress">Progress</.pp_list_item>
            <.pp_list_item href="#skeleton">Skeleton</.pp_list_item>
            <.pp_list_item href="#snackbar">Snackbar</.pp_list_item>
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
        <.pp_app_bar position="sticky">
          <:leading><.pp_drawer_toggle for="app-drawer" /></:leading>
          PhoenixPaper
          <:actions>
            <.pp_button
              variant="text"
              class="text-pp-on-primary hover:bg-pp-on-primary/10 focus-visible:outline-pp-on-primary"
              phx-click={JS.remove_attribute("data-pp-theme", to: "html")}
            >
              Indigo
            </.pp_button>
            <.pp_button
              variant="text"
              class="text-pp-on-primary hover:bg-pp-on-primary/10 focus-visible:outline-pp-on-primary"
              phx-click={JS.set_attribute({"data-pp-theme", "teal"}, to: "html")}
            >
              Teal
            </.pp_button>
            <.pp_theme_toggle label={nil} />
          </:actions>
        </.pp_app_bar>

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
          description="A floating-label text field — pure CSS, no JS. outlined (bordered box), filled (filled background), or standard (underline only)."
          props={[
            {"label / value / name / id", "standard text field attrs"},
            {"type", "any input type, e.g. text | email | password (default: text)"},
            {"variant", "outlined | filled | standard (default: outlined)"},
            {"color", "primary | secondary | tertiary | error (default: primary) — focus/label accent"},
            {"size", "medium | small (default: medium)"},
            {"shape", "corner radius token (default: :sm) — ignored for variant=\"standard\""},
            {"multiline / rows", "renders a <textarea rows={@rows}> instead of <input>"},
            {"start_adornment / end_adornment", "slots for prefix/suffix content, e.g. an icon or unit"},
            {"field", "a Phoenix.HTML.FormField from to_form/2 — sets name/id/value for you"},
            {"errors", "list of error strings — switches to the error color and hides helper_text"},
            {"helper_text", "shown below the field when there are no errors"},
            {"disabled", "boolean (default: false)"},
            {"paperize", "boolean (default: true)"}
          ]}
          code={@text_field_code}
        >
          <div class="grid grid-cols-1 gap-6 sm:grid-cols-2">
            <.pp_input variant="outlined" label="Outlined (default)" name="outlined_demo" />
            <.pp_input variant="filled" label="Filled" name="filled_demo" />
            <.pp_input variant="standard" label="Standard" name="standard_demo" />
            <.pp_input label="With helper text" name="helper_demo" helper_text="We'll never share your email." />
            <.pp_input label="With an error" name="error_demo" value="not-an-email" errors={["is not a valid email"]} />
            <.pp_input label="Disabled" name="disabled_demo" value="Can't touch this" disabled />
            <.pp_input color="primary" label="Primary" name="color_primary_demo" />
            <.pp_input color="secondary" label="Secondary" name="color_secondary_demo" />
            <.pp_input color="tertiary" label="Tertiary" name="color_tertiary_demo" />
            <.pp_input size="medium" label="Medium (default)" name="size_medium_demo" />
            <.pp_input size="small" label="Small" name="size_small_demo" />
            <.pp_input label="Amount" name="amount_demo" value="42.00">
              <:start_adornment>$</:start_adornment>
              <:end_adornment>USD</:end_adornment>
            </.pp_input>
            <.pp_input multiline rows={3} label="Bio" name="bio_demo" value="A short bio, spanning a couple lines of text." class="sm:col-span-2" />
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
          description="Includes the hidden-input trick so an unchecked box still submits false."
          props={[
            {"checked", "boolean (default: nil, meaning unchecked)"},
            {"field", "a Phoenix.HTML.FormField — sets name/id/checked for you"},
            {"label", "text next to the box"},
            {"disabled", "boolean (default: false)"},
            {"ripple", "boolean — the ripple effect on click/tap (default: false)"},
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
          id="theme-toggle"
          title="Theme Toggle"
          description="A light/dark mode toggle built on Switch, wired with Phoenix.LiveView.JS.toggle_attribute/1,2 to flip a data-theme attribute on the target element — pure JS command, no server round-trip."
          props={[
            {"label", "text next to the switch (default: \"Dark mode\")"},
            {"default_checked", "boolean — initial visual state, uncontrolled (default: false)"},
            {"target", "CSS selector for the element to toggle data-theme on (default: \"html\")"},
            {"on_toggle", "extra Phoenix.LiveView.JS commands run before the built-in flip, e.g. to persist the choice server-side"},
            {"ripple / paperize", "same as Switch"}
          ]}
          code={@theme_toggle_code}
        >
          <.pp_theme_toggle />
        </.demo_section>

        <.demo_section
          id="radio-group"
          title="Radio Group"
          description="A labeled set of mutually exclusive radio buttons sharing one name."
          props={[
            {"options", "list of {label, value} tuples, or plain values"},
            {"value", "the currently selected value"},
            {"label", "the group's legend"},
            {"ripple", "boolean — the ripple effect on click/tap (default: false)"},
            {"field / disabled / paperize", "same as other form controls"}
          ]}
          code={@radio_group_code}
        >
          <.pp_radio_group label="Size" name="size_demo" value="md" options={[{"Small", "sm"}, {"Medium", "md"}, {"Large", "lg"}]} />
        </.demo_section>

        <.demo_section
          id="slider"
          title="Slider"
          description="A native range input, fully re-skinned via ::-webkit-slider-thumb/::-moz-range-progress rather than CSS accent-color alone — see AGENTS.md for why accent-color can't give the unfilled part of the track a controlled color."
          props={[
            {"min / max / step", "default 0 / 100 / 1"},
            {"value", "a number, or a {low, high} tuple for a range slider (two thumbs)"},
            {"color", "primary | secondary | tertiary | error (default: primary)"},
            {"size", "medium | small (default: medium)"},
            {"orientation", "horizontal | vertical (default: horizontal)"},
            {"track", "normal | none | inverted (default: normal) — ignored for range sliders"},
            {"marks", "true (tick every step), a list of values, or a list of {value, label} tuples"},
            {"label", "shown above the slider with the current value"},
            {"field / disabled / paperize", "same as other form controls"}
          ]}
          code={@slider_code}
        >
          <div class="grid grid-cols-1 gap-8 sm:grid-cols-2">
            <.pp_slider name="volume_demo" label="Volume" value={60} />
            <.pp_slider name="volume_small_demo" label="Small" value={60} size="small" />

            <.pp_slider
              :for={color <- ~w(primary secondary tertiary error)}
              name={"volume_#{color}_demo"}
              label={color}
              value={60}
              color={color}
            />

            <.pp_slider name="volume_no_track_demo" label="track: none" value={60} track="none" />
            <.pp_slider name="volume_inverted_demo" label="track: inverted" value={60} track="inverted" />

            <.pp_slider name="volume_marks_demo" label="Discrete (marks)" value={40} step={20} marks={true} />
            <.pp_slider
              name="temperature_demo"
              label="Custom labeled marks"
              value={30}
              min={0}
              max={100}
              marks={[{0, "0°C"}, {30, "30°C"}, {60, "60°C"}, {100, "100°C"}]}
            />

            <.pp_slider name="price_demo" label="Range slider" value={{20, 80}} />
            <.pp_slider name="volume_disabled_demo" label="Disabled" value={30} disabled />
          </div>

          <div class="mt-8 flex items-center gap-12">
            <div>
              <p class="mb-2 text-sm opacity-70">orientation="vertical"</p>
              <.pp_slider name="volume_vertical_demo" value={60} orientation="vertical" />
            </div>
            <div>
              <p class="mb-2 text-sm opacity-70">vertical + small</p>
              <.pp_slider name="volume_vertical_small_demo" value={60} orientation="vertical" size="small" color="secondary" />
            </div>
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
          id="app-bar"
          title="App Bar"
          description="A horizontal app bar with a leading slot, a title, and trailing actions. The one at the top of this page is a live sticky instance — fixed/absolute aren't demoed inline since they'd overlay the rest of this page."
          props={[
            {"color", "primary | secondary | tertiary | surface | transparent (default: primary)"},
            {"elevation", "resting elevation, 0-24 (default: 4) — ignored for color=\"transparent\""},
            {"position", "static | relative | sticky | fixed | absolute (default: static)"},
            {"variant", "regular | dense (default: regular) — dense shrinks the toolbar row"},
            {"paperize", "boolean (default: true)"}
          ]}
          code={@app_bar_code}
        >
          <div class="flex flex-col gap-3">
            <.pp_app_bar :for={color <- ~w(primary secondary tertiary surface transparent)} class="!static" color={color}>
              {color}
              <:actions>
                <.pp_button variant="icon"><span class="hero-bell" /></.pp_button>
              </:actions>
            </.pp_app_bar>
            <.pp_app_bar variant="dense" class="!static">
              dense variant
              <:actions>
                <.pp_button variant="icon"><span class="hero-bell" /></.pp_button>
              </:actions>
            </.pp_app_bar>
          </div>
        </.demo_section>

        <.demo_section
          id="drawer"
          title="Drawer"
          description="A navigation drawer, persistent on large screens and toggled by a hamburger button below that breakpoint — pure CSS via a hidden checkbox, no JS. The drawer on the left of this page is a live, primary-colored instance; try shrinking your window."
          props={[
            {"id", "required — builds the mobile toggle checkbox's id as \"\#{id}-toggle\""},
            {"color", "primary | secondary | tertiary | surface (default: surface) — also restyles nested List/ListItem for contrast"},
            {"paperize", "boolean (default: true)"},
            {"pp_drawer_toggle for=", "a hamburger <label> pointing at the given drawer's id — works from anywhere on the page, not just inside the drawer"}
          ]}
          code={@drawer_code}
        >
          <p class="text-sm opacity-70">See the left edge of this page — that's this exact component, live.</p>
        </.demo_section>

        <.demo_section
          id="tabs"
          title="Tabs"
          description="Tabs/Tab/TabPanel switch entirely client-side via Phoenix.LiveView.JS commands (add_class/remove_class/set_attribute/show/hide) fired on click — no server round-trip, no sliding indicator animation (that needs a real layout measurement, which JS commands can't do). id must match across every Tab/TabPanel in a group; value must be unique within it."
          props={[
            {"pp_tabs id", "required — shared with every Tab/TabPanel in the group"},
            {"pp_tabs orientation", "horizontal | vertical (default: horizontal)"},
            {"pp_tabs variant", "standard | scrollable | full_width (default: standard) — horizontal only"},
            {"pp_tabs centered", "boolean — horizontal + variant=\"standard\" only"},
            {"pp_tab id / value", "id matches the parent Tabs; value must be unique within the group"},
            {"pp_tab default_selected", "boolean — initial selection, uncontrolled (default: false)"},
            {"pp_tab color", "primary | secondary | tertiary | error (default: primary) — doesn't cascade from Tabs, set per Tab"},
            {"pp_tab orientation", "must match the parent Tabs' own orientation"},
            {"pp_tab :icon", "optional leading icon slot"},
            {"pp_tab disabled / ripple / paperize", "same as Button"},
            {"pp_tab_panel id / value", "must match the corresponding Tab exactly"},
            {"pp_tab_panel default_selected", "boolean — must match its Tab's own default_selected"}
          ]}
          code={@tabs_code}
        >
          <div class="flex flex-col gap-8">
            <div>
              <.pp_tabs id="demo-tabs">
                <.pp_tab id="demo-tabs" value="one" default_selected>One</.pp_tab>
                <.pp_tab id="demo-tabs" value="two">Two</.pp_tab>
                <.pp_tab id="demo-tabs" value="three" disabled>Three (disabled)</.pp_tab>
              </.pp_tabs>
              <.pp_tab_panel id="demo-tabs" value="one" default_selected>Content one.</.pp_tab_panel>
              <.pp_tab_panel id="demo-tabs" value="two">Content two.</.pp_tab_panel>
              <.pp_tab_panel id="demo-tabs" value="three">Content three.</.pp_tab_panel>
            </div>

            <div class="border-t border-pp-outline/20 pt-4">
              <p class="mb-2 text-sm opacity-70">colors:</p>
              <.pp_tabs id="color-tabs">
                <.pp_tab id="color-tabs" value="primary" default_selected color="primary">Primary</.pp_tab>
                <.pp_tab id="color-tabs" value="secondary" color="secondary">Secondary</.pp_tab>
                <.pp_tab id="color-tabs" value="tertiary" color="tertiary">Tertiary</.pp_tab>
                <.pp_tab id="color-tabs" value="error" color="error">Error</.pp_tab>
              </.pp_tabs>
              <.pp_tab_panel id="color-tabs" value="primary" default_selected>Primary content.</.pp_tab_panel>
              <.pp_tab_panel id="color-tabs" value="secondary">Secondary content.</.pp_tab_panel>
              <.pp_tab_panel id="color-tabs" value="tertiary">Tertiary content.</.pp_tab_panel>
              <.pp_tab_panel id="color-tabs" value="error">Error content.</.pp_tab_panel>
            </div>

            <div class="border-t border-pp-outline/20 pt-4">
              <p class="mb-2 text-sm opacity-70">variant="full_width":</p>
              <.pp_tabs id="full-width-tabs" variant="full_width">
                <.pp_tab id="full-width-tabs" value="one" default_selected>One</.pp_tab>
                <.pp_tab id="full-width-tabs" value="two">Two</.pp_tab>
                <.pp_tab id="full-width-tabs" value="three">Three</.pp_tab>
              </.pp_tabs>
            </div>

            <div class="border-t border-pp-outline/20 pt-4">
              <p class="mb-2 text-sm opacity-70">orientation="vertical", with icons:</p>
              <.pp_tabs id="vertical-tabs" orientation="vertical" class="max-w-xs">
                <.pp_tab id="vertical-tabs" value="a" orientation="vertical" color="secondary" default_selected>
                  <:icon><.pp_icon name="hero-home" /></:icon>
                  Home
                </.pp_tab>
                <.pp_tab id="vertical-tabs" value="b" orientation="vertical" color="secondary">
                  <:icon><.pp_icon name="hero-user" /></:icon>
                  Profile
                </.pp_tab>
              </.pp_tabs>
            </div>
          </div>
        </.demo_section>

        <.demo_section
          id="breadcrumbs"
          title="Breadcrumbs"
          description="A breadcrumb trail with a separator auto-inserted between :item slots. An item renders as a link when it has href/navigate/patch, or plain current-page text otherwise (with an aria-current attribute) — whichever item you leave without a link is the current page, same convention as ListItem."
          props={[
            {"pp_breadcrumbs :item href/navigate/patch", "makes that item a link; omit all three for the current page"},
            {"pp_breadcrumbs :separator", "a slot, not a string — can hold an icon; defaults to \"/\""},
            {"max_items", "collapse into an expandable ellipsis beyond this many items (default: 8)"},
            {"items_before_collapse / items_after_collapse", "collapsed slice sizes (default: 1 / 1)"},
            {"expand_text", "aria-label for the ellipsis expand control (default: \"Show path\")"},
            {"paperize", "boolean (default: true)"}
          ]}
          code={@breadcrumbs_code}
        >
          <div class="flex flex-col gap-4">
            <.pp_breadcrumbs>
              <:item navigate="/">Home</:item>
              <:item navigate="/catalog">Catalog</:item>
              <:item>Current product</:item>
            </.pp_breadcrumbs>

            <.pp_breadcrumbs>
              <:separator><.pp_icon name="hero-chevron-right" class="size-4" /></:separator>
              <:item navigate="/">Home</:item>
              <:item navigate="/settings">Settings</:item>
              <:item>Profile</:item>
            </.pp_breadcrumbs>

            <div>
              <p class="mb-1 text-sm opacity-70">max_items=3 — click the ellipsis to expand:</p>
              <.pp_breadcrumbs max_items={3}>
                <:item navigate="/one">One</:item>
                <:item navigate="/two">Two</:item>
                <:item navigate="/three">Three</:item>
                <:item navigate="/four">Four</:item>
                <:item>Five</:item>
              </.pp_breadcrumbs>
            </div>
          </div>
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
          id="badge"
          title="Badge"
          description="A small count/status indicator overlapping the corner of its child, in the spirit of MUI's Badge."
          props={[
            {"content", "badge content — a number or short string (default: nil)"},
            {"max", "caps a numeric content at max+, e.g. 99+ (default: 99)"},
            {"show_zero", "show the badge when content is the integer 0 (default: false)"},
            {"variant", "\"standard\" | \"dot\" (default: \"standard\")"},
            {"color", "primary | secondary | tertiary | error | success | warning | info (default: \"error\")"},
            {"overlap", "\"rectangular\" | \"circular\" — pulls the badge inward onto a circular child (default: \"rectangular\")"},
            {"anchor_origin", "which corner (default: \"top-right\")"},
            {"invisible", "force-hide the badge (default: false)"}
          ]}
          code={@badge_code}
        >
          <div class="flex items-center gap-8">
            <.pp_badge content={4}>
              <.pp_icon name="hero-bell" />
            </.pp_badge>
            <.pp_badge content={150}>
              <.pp_icon name="hero-bell" />
            </.pp_badge>
            <.pp_badge variant="dot" color="success">
              <.pp_icon name="hero-user" />
            </.pp_badge>
            <.pp_badge content={1} overlap="circular" color="primary">
              <span class="inline-flex size-10 items-center justify-center rounded-full bg-pp-surface-variant">
                <.pp_icon name="hero-user" />
              </span>
            </.pp_badge>
          </div>
        </.demo_section>

        <.demo_section
          id="chip"
          title="Chip"
          description="A compact element for input, attribute, or action, in the spirit of MUI's Chip."
          props={[
            {"variant", "\"filled\" | \"outlined\" (default: \"filled\")"},
            {"color", "default | primary | secondary | tertiary | error | success | warning | info (default: \"default\")"},
            {"size", "\"small\" | \"medium\" (default: \"medium\")"},
            {"clickable", "renders a real <button> with a ripple, for filter/action chips (default: false)"},
            {"deletable", "renders a trailing delete control wired to on_delete (default: false)"},
            {"on_delete", "JS command run when the delete control is clicked"},
            {"disabled", "dims and disables the chip and its delete control (default: false)"},
            {":icon", "a leading icon or avatar slot"}
          ]}
          code={@chip_code}
        >
          <div class="flex flex-wrap items-center gap-3">
            <.pp_chip>Basic</.pp_chip>
            <.pp_chip variant="outlined" color="primary">Outlined</.pp_chip>
            <.pp_chip color="success">Success</.pp_chip>
            <.pp_chip size="small">Small</.pp_chip>
            <.pp_chip>
              Tagged
              <:icon><.pp_icon name="hero-check" /></:icon>
            </.pp_chip>
            <.pp_chip :for={tag <- @chips} deletable on_delete={JS.push("delete_chip", value: %{chip: tag})}>
              {tag}
            </.pp_chip>
            <.pp_chip clickable phx-click="select_filter">Clickable</.pp_chip>
            <.pp_chip clickable disabled>Disabled</.pp_chip>
          </div>
        </.demo_section>

        <.demo_section
          id="tooltip"
          title="Tooltip"
          description="A short text label shown on hover/focus, in the spirit of MUI's Tooltip. Pure CSS (group-hover/group-focus-within) — no JS, no collision detection/auto-flip, see the moduledoc."
          props={[
            {"title", "the tooltip text — nil or \"\" disables the tooltip (default: nil)"},
            {"placement", "top | bottom | left | right (default: \"top\")"},
            {"arrow", "a small triangle pointing at the trigger (default: false)"}
          ]}
          code={@tooltip_code}
        >
          <div class="flex items-center gap-10 py-6">
            <.pp_tooltip title="Delete">
              <.pp_button variant="icon"><.pp_icon name="hero-trash" /></.pp_button>
            </.pp_tooltip>
            <.pp_tooltip title="Bottom" placement="bottom">
              <.pp_button variant="outlined">Bottom</.pp_button>
            </.pp_tooltip>
            <.pp_tooltip title="With an arrow" arrow>
              <.pp_button variant="outlined">Arrow</.pp_button>
            </.pp_tooltip>
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
          id="accordion"
          title="Accordion"
          description="Pure CSS, no JS/LiveView — the same hidden-checkbox-plus-peer-checked trick as Drawer/Rating. AccordionSummary/Details/Actions all need the same id as their parent Accordion, to build the matching for=/peer-checked wiring."
          props={[
            {"id", "required — shared with AccordionSummary/Details/Actions"},
            {"name", "shared across accordions for an exclusive group (radio instead of checkbox)"},
            {"default_expanded", "boolean — initial checked state, uncontrolled (default: false)"},
            {"disabled", "boolean (default: false)"},
            {"disable_gutters", "boolean — skip the extra margin an expanded accordion normally gets"},
            {"elevation / shape / paperize", "same as Card — Accordion is a Paper underneath"}
          ]}
          code={@accordion_code}
        >
          <div class="flex flex-col gap-4">
            <div>
              <.pp_accordion id="acc1_demo">
                <.pp_accordion_summary id="acc1_demo">Accordion 1</.pp_accordion_summary>
                <.pp_accordion_details id="acc1_demo">
                  This is the content of the first accordion.
                </.pp_accordion_details>
                <.pp_accordion_actions id="acc1_demo">
                  <.pp_button variant="text">Cancel</.pp_button>
                  <.pp_button variant="text">Save</.pp_button>
                </.pp_accordion_actions>
              </.pp_accordion>
              <.pp_accordion id="acc2_demo" default_expanded>
                <.pp_accordion_summary id="acc2_demo">Accordion 2 (default expanded)</.pp_accordion_summary>
                <.pp_accordion_details id="acc2_demo">This one starts open.</.pp_accordion_details>
              </.pp_accordion>
              <.pp_accordion id="acc3_demo" disabled>
                <.pp_accordion_summary id="acc3_demo">Accordion 3 (disabled)</.pp_accordion_summary>
                <.pp_accordion_details id="acc3_demo">Can't be opened.</.pp_accordion_details>
              </.pp_accordion>
            </div>
            <div class="border-t border-pp-outline/20 pt-4">
              <p class="mb-2 text-sm opacity-70">Exclusive group (radios, name="faq_demo"):</p>
              <.pp_accordion id="faq1_demo" name="faq_demo">
                <.pp_accordion_summary id="faq1_demo">FAQ 1</.pp_accordion_summary>
                <.pp_accordion_details id="faq1_demo">Answer 1</.pp_accordion_details>
              </.pp_accordion>
              <.pp_accordion id="faq2_demo" name="faq_demo">
                <.pp_accordion_summary id="faq2_demo">FAQ 2</.pp_accordion_summary>
                <.pp_accordion_details id="faq2_demo">Answer 2</.pp_accordion_details>
              </.pp_accordion>
              <.pp_accordion id="faq3_demo" name="faq_demo">
                <.pp_accordion_summary id="faq3_demo">FAQ 3</.pp_accordion_summary>
                <.pp_accordion_details id="faq3_demo">Answer 3</.pp_accordion_details>
              </.pp_accordion>
            </div>
          </div>
        </.demo_section>

        <.demo_section
          id="alert"
          title="Alert"
          description="A colored, icon-led message for status feedback. severity is a distinct color axis from every other component's color (success/info/warning/error status colors, not primary/secondary/tertiary/error brand colors) — see AGENTS.md."
          props={[
            {"severity", "success | info | warning | error (default: info) — picks the color and icon"},
            {"variant", "standard (tinted) | outlined | filled (default: standard)"},
            {":title / :action", "optional slots — a bold line above the message, a trailing action"},
            {"paperize", "boolean (default: true)"}
          ]}
          code={@alert_code}
        >
          <div class="flex flex-col gap-3">
            <.pp_alert severity="success">Changes saved.</.pp_alert>
            <.pp_alert severity="info">A new update is available.</.pp_alert>
            <.pp_alert severity="warning" variant="outlined">Check your input.</.pp_alert>
            <.pp_alert severity="error" variant="filled">
              <:title>Error</:title>
              Could not save your changes.
              <:action><.pp_button variant="text" class="!text-pp-on-error">Retry</.pp_button></:action>
            </.pp_alert>
          </div>
        </.demo_section>

        <.demo_section
          id="backdrop"
          title="Backdrop"
          description="A full-screen dimming overlay — most often behind a full-page loading spinner, or the piece Dialog composes for its own overlay. Stateless: open just toggles rendering it at all."
          props={[
            {"open", "boolean (default: true)"},
            {":inner_block", "optional content centered over the dim — e.g. a spinner"},
            {"paperize", "boolean (default: true)"}
          ]}
          code={@backdrop_code}
        >
          <.pp_button phx-click="toggle_backdrop">Show backdrop</.pp_button>
          <.pp_backdrop open={@show_backdrop} phx-click="toggle_backdrop">
            <span class="inline-block size-10 animate-spin rounded-full border-4 border-white border-t-transparent" />
          </.pp_backdrop>
        </.demo_section>

        <.demo_section
          id="dialog"
          title="Dialog"
          description="A modal — built the same way mix phx.new's generated core_components.ex builds its modal/1: always in the DOM, shown/hidden via Phoenix.LiveView.JS commands, not a server-tracked open assign. Phoenix.Dialog.show/1 and .hide/1 return JS commands to wire to whatever should open/close it."
          props={[
            {"id", "required — targeted by show/1 and hide/1"},
            {"on_cancel", "a Phoenix.LiveView.JS command run (in addition to hiding) on backdrop click/Escape"},
            {":title / :actions", "optional slots"},
            {"paperize", "boolean (default: true)"}
          ]}
          code={@dialog_code}
        >
          <.pp_button phx-click={PhoenixPaper.Dialog.show("confirm-delete-demo")}>
            Delete
          </.pp_button>
          <.pp_dialog id="confirm-delete-demo">
            <:title>Delete this item?</:title>
            This can't be undone.
            <:actions>
              <.pp_button variant="text" phx-click={PhoenixPaper.Dialog.hide("confirm-delete-demo")}>
                Cancel
              </.pp_button>
              <.pp_button color="error" phx-click={PhoenixPaper.Dialog.hide("confirm-delete-demo")}>
                Delete
              </.pp_button>
            </:actions>
          </.pp_dialog>
        </.demo_section>

        <.demo_section
          id="progress"
          title="Progress"
          description="linear or circular, combined into one component since they share the same value/color contract. value nil renders the indeterminate/animated form."
          props={[
            {"variant", "linear | circular (default: linear)"},
            {"value", "0-100, nil for indeterminate (default: nil)"},
            {"color", "primary | secondary | tertiary | error (default: primary)"},
            {"size", "circular only — diameter in pixels (default: 40)"},
            {"paperize", "boolean (default: true)"}
          ]}
          code={@progress_code}
        >
          <div class="flex flex-col gap-4">
            <div class="max-w-sm">
              <p class="mb-2 text-sm opacity-70">linear, determinate (72%):</p>
              <.pp_progress value={72} />
            </div>
            <div class="max-w-sm">
              <p class="mb-2 text-sm opacity-70">linear, indeterminate:</p>
              <.pp_progress />
            </div>
            <div class="flex items-center gap-6 border-t border-pp-outline/20 pt-4">
              <div :for={color <- ~w(primary secondary tertiary error)} class="flex flex-col items-center gap-2">
                <.pp_progress variant="circular" value={65} color={color} />
                <span class="text-xs opacity-60">{color}</span>
              </div>
              <div class="flex flex-col items-center gap-2">
                <.pp_progress variant="circular" />
                <span class="text-xs opacity-60">indeterminate</span>
              </div>
            </div>
          </div>
        </.demo_section>

        <.demo_section
          id="skeleton"
          title="Skeleton"
          description="A placeholder loading shape — text, circular, rectangular, or rounded — with a pulsing (default) or shimmering animation while real content loads."
          props={[
            {"variant", "text | circular | rectangular | rounded (default: text)"},
            {"width / height", "an integer (px) or a CSS length string, e.g. \"100%\""},
            {"animation", "pulse | wave | none (default: pulse)"},
            {"paperize", "boolean (default: true)"}
          ]}
          code={@skeleton_code}
        >
          <div class="flex max-w-sm flex-col gap-3">
            <div class="flex items-center gap-3">
              <.pp_skeleton variant="circular" width={40} height={40} />
              <div class="flex-1">
                <.pp_skeleton />
                <.pp_skeleton width="60%" />
              </div>
            </div>
            <.pp_skeleton variant="rectangular" height={80} />
            <.pp_skeleton variant="rounded" height={80} animation="wave" />
          </div>
        </.demo_section>

        <.demo_section
          id="snackbar"
          title="Snackbar"
          description="A brief toast — presentation-only. Auto-dismiss-after-a-delay isn't built in: one Process.send_after/3 clearing whatever assign controls open, the same mechanism generated flash messages already use, not a second client-side timer. No exit transition either — only entrance, see AGENTS.md."
          props={[
            {"open", "boolean (default: true)"},
            {"anchor_origin", "bottom-left (default) | bottom-center | bottom-right | top-left | top-center | top-right"},
            {"transition", "grow (default) | fade | slide | none — mount-in animation only"},
            {":action", "optional slot — e.g. an \"Undo\" button"},
            {"elevation", "resting elevation, 0-24 (default: 6)"},
            {"paperize", "boolean (default: true)"}
          ]}
          code={@snackbar_code}
        >
          <div class="relative h-32 rounded-lg border border-pp-outline/20">
            <.pp_snackbar class="!absolute !inset-x-4 !bottom-4">
              Changes saved
              <:action>
                <.pp_button variant="text" class="!text-pp-surface" phx-click="dismiss">Undo</.pp_button>
              </:action>
            </.pp_snackbar>
            <.pp_snackbar anchor_origin="top-right" transition="slide" class="!absolute !top-4 !right-4">
              Copied to clipboard
            </.pp_snackbar>
          </div>
        </.demo_section>

        <.demo_section
          id="ripple"
          title="Ripple (helper)"
          description="The Material ripple effect — a circle that expands from the click point and fades out. Vanilla inline onclick, no JS hook/bundler. Try clicking the buttons above."
          props={[
            {"ripple", "the boolean prop on Button, Fab, ToggleButton, Switch, Checkbox, RadioGroup, and a linked ListItem — default true, except Checkbox/RadioGroup (default false; their own instant fill/border change already reads as feedback on a target that small); always off when paperize is false"},
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
          description="Colors are Tailwind v4 theme tokens backed by CSS custom properties, namespaced pp- so they never collide with daisyUI. Try the Indigo/Teal buttons and the theme toggle in the app bar above — no page reload, just flipping data-theme/data-pp-theme on the root html element."
          props={[
            {"data-theme=\"dark\"", "on any ancestor — the same attribute daisyUI/Phoenix 1.8's generated app.css already use"},
            {"data-pp-theme=\"teal\"", "opts into the bundled alternate palette"},
            {"custom theme", "override the --color-pp-* variables from your own stylesheet — no build step, no JS config"}
          ]}
          code={@theming_code}
        >
          <p class="text-sm opacity-70">Use the theme buttons/toggle in the app bar — this section is just documentation.</p>
        </.demo_section>
        </.pp_container>
      </div>
    </div>
    """
  end
end

PhoenixPlayground.start(live: PhoenixPaperDemo, open_browser: false)
