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
# an external CDN. If you add a *new* Tailwind class name to a component,
# restart this script to pick it up — structural/logic edits still hot
# reload live via `phoenix_live_reload`.
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

      <pre class="mt-4 overflow-x-auto rounded-lg bg-pp-surface-variant p-4 text-xs leading-relaxed"><code>{@code}</code></pre>
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
  .hero-check, .hero-star, .hero-home, .hero-cog, .hero-bell {
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
  """

  # HEEx treats `<style>`/`<script>` bodies as raw text (matching how browsers
  # parse them) and does NOT interpolate `{...}` inside them — so the CSS is
  # built into one already-safe `<style>` tag *outside* the ~H sigil, and
  # dropped in with `raw/1` as a single opaque HTML fragment instead.
  @style_tag raw("<style type=\"text/css\">" <> @pp_css <> @demo_icon_css <> "</style>")

  # Small placeholder "photos" for the ImageList demo — inline SVG data URIs
  # (same raw, unencoded approach as the icon masks above) so the page stays
  # fully offline, no network image fetch required. HEEx HTML-escapes this
  # string automatically when it lands in `src={...}` below, and the browser
  # un-escapes it back before treating it as a URL, so no manual encoding
  # is needed for the characters this particular SVG uses.
  @photo_1 ~s(data:image/svg+xml;utf8,<svg xmlns="http://www.w3.org/2000/svg" width="200" height="200"><rect width="200" height="200" fill="#3f51b5"/></svg>)
  @photo_2 ~s(data:image/svg+xml;utf8,<svg xmlns="http://www.w3.org/2000/svg" width="200" height="200"><rect width="200" height="200" fill="#ff4081"/></svg>)
  @photo_3 ~s(data:image/svg+xml;utf8,<svg xmlns="http://www.w3.org/2000/svg" width="200" height="200"><rect width="200" height="200" fill="#009688"/></svg>)

  def mount(_params, _session, socket) do
    {:ok, assign(socket, page_title: "PhoenixPaper catalog", bold_pressed: false)}
  end

  def handle_event("toggle_bold", _params, socket) do
    {:noreply, update(socket, :bold_pressed, &(!&1))}
  end

  def render(assigns) do
    assigns = assign(assigns, style_tag: @style_tag, photo_1: @photo_1, photo_2: @photo_2, photo_3: @photo_3)

    ~H"""
    {@style_tag}

    <div class="min-h-screen bg-pp-surface-variant text-pp-on-surface lg:pl-64">
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
          </.nav_group>
          <.nav_group label="Helpers">
            <.pp_list_item href="#ripple">Ripple</.pp_list_item>
            <.pp_list_item href="#elevation">Elevation</.pp_list_item>
            <.pp_list_item href="#shape">Shape</.pp_list_item>
            <.pp_list_item href="#theming">Theming</.pp_list_item>
          </.nav_group>
        </.pp_list>
      </.pp_drawer>

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
            {"type", "button | submit | reset (default: button)"},
            {"paperize", "boolean — apply PhoenixPaper's classes at all (default: true)"},
            {"class", "merged on top via Tails"}
          ]}
          code={~S"""
          <.pp_button color="primary">Save</.pp_button>
          <.pp_button variant="outlined" color="secondary">Outlined</.pp_button>
          <.pp_button variant="text">Text</.pp_button>
          <.pp_button ripple={false}>No ripple</.pp_button>
          <.pp_button paperize={false} class="border-4 border-dashed border-fuchsia-500 px-3 py-1 font-mono text-fuchsia-700">
            paperize: false
          </.pp_button>
          """}
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
          </div>
        </.demo_section>

        <.demo_section
          id="button-group"
          title="Button Group"
          description="Visually joins a row of buttons into one segmented control by rounding only the outer corners."
          props={[
            {"shape", "corner radius token for the group's outer corners (default: :md)"},
            {"paperize", "boolean (default: true)"},
            {"class", "merged on top via Tails"}
          ]}
          code={~S"""
          <.pp_button_group>
            <.pp_button variant="outlined">Day</.pp_button>
            <.pp_button variant="outlined">Week</.pp_button>
            <.pp_button variant="outlined">Month</.pp_button>
          </.pp_button_group>
          """}
        >
          <.pp_button_group>
            <.pp_button variant="outlined">Day</.pp_button>
            <.pp_button variant="outlined">Week</.pp_button>
            <.pp_button variant="outlined">Month</.pp_button>
          </.pp_button_group>
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
          code={~S"""
          <.pp_fab><.pp_icon name="hero-star" /></.pp_fab>
          <.pp_fab extended color="primary">
            <.pp_icon name="hero-star" /> Create
          </.pp_fab>
          """}
        >
          <div class="flex items-center gap-4">
            <.pp_fab><span class="hero-star" /></.pp_fab>
            <.pp_fab extended color="primary">
              <span class="hero-star" /> Create
            </.pp_fab>
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
          code={~S"""
          <.pp_toggle_button pressed={@bold_pressed} phx-click="toggle_bold">
            Bold
          </.pp_toggle_button>
          """}
        >
          <.pp_toggle_button pressed={@bold_pressed} phx-click="toggle_bold">
            Bold
          </.pp_toggle_button>
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
          code={~S"""
          <.pp_input label="Outlined (default)" name="outlined_demo" />
          <.pp_input variant="filled" label="Filled" name="filled_demo" />
          <.pp_input label="With an error" name="error_demo" value="not-an-email" errors={["is not a valid email"]} />
          """}
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
          description="A native <select> styled to match Text Field's outlined/filled variants."
          props={[
            {"options", "list of {label, value} tuples, or plain values"},
            {"prompt", "an empty/placeholder option's label"},
            {"variant", "outlined | filled (default: outlined)"},
            {"field / errors / helper_text", "same as Text Field"},
            {"disabled", "boolean (default: false)"}
          ]}
          code={~S"""
          <.pp_select
            label="Country"
            name="country"
            prompt="Choose one"
            options={["Canada", "Mexico", "United States"]}
          />
          """}
        >
          <.pp_select label="Country" name="country_demo" prompt="Choose one" options={["Canada", "Mexico", "United States"]} />
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
          code={~S"""
          <.pp_number_field label="Quantity" name="qty" value={2} min={0} max={10} />
          """}
        >
          <.pp_number_field label="Quantity" name="qty_demo" value={2} min={0} max={10} />
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
            {"paperize", "false renders a bare native checkbox, no hidden input"}
          ]}
          code={~S"""
          <.pp_checkbox label="Paperized (default)" checked={true} />
          <.pp_checkbox paperize={false} label="paperize: false" />
          """}
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
          props={[
            {"checked / field / label / disabled / paperize", "same shape as Checkbox"}
          ]}
          code={~S"""
          <.pp_switch label="Notifications" checked={true} name="notifications" />
          """}
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
          description="A labeled set of mutually exclusive radio buttons sharing one name."
          props={[
            {"options", "list of {label, value} tuples, or plain values"},
            {"value", "the currently selected value"},
            {"label", "the group's legend"},
            {"field / disabled / paperize", "same as other form controls"}
          ]}
          code={~S"""
          <.pp_radio_group
            label="Size"
            name="size"
            value="md"
            options={[{"Small", "sm"}, {"Medium", "md"}, {"Large", "lg"}]}
          />
          """}
        >
          <.pp_radio_group label="Size" name="size_demo" value="md" options={[{"Small", "sm"}, {"Medium", "md"}, {"Large", "lg"}]} />
        </.demo_section>

        <.demo_section
          id="slider"
          title="Slider"
          description="A native <input type=\"range\"> colored via CSS accent-color — no ::-webkit-slider-thumb hacks."
          props={[
            {"min / max / step", "default 0 / 100 / 1"},
            {"color", "primary | secondary | tertiary | error (default: primary)"},
            {"label", "shown above the slider with the current value"},
            {"field / disabled / paperize", "same as other form controls"}
          ]}
          code={~S"""
          <.pp_slider name="volume" label="Volume" value={60} color="secondary" />
          """}
        >
          <.pp_slider name="volume_demo" label="Volume" value={60} color="secondary" />
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
          code={~S"""
          <.pp_rating id="stars" name="stars" value={3} />
          <.pp_rating readonly value={4} />
          """}
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
          code={~S"""
          <.live_component
            module={PhoenixPaper.Autocomplete}
            id="country"
            name="country"
            label="Country"
            placeholder="Start typing..."
            options={["Canada", "Mexico", "United States", "United Kingdom", "Uruguay"]}
          />
          """}
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
          code={~S"""
          <.live_component
            module={PhoenixPaper.TransferList}
            id="permissions"
            items={["Read", "Write", "Admin", "Billing"]}
          />
          """}
        >
          <.live_component module={PhoenixPaper.TransferList} id="permissions_demo" items={["Read", "Write", "Admin", "Billing"]} />
        </.demo_section>

        <.demo_section
          id="navbar"
          title="Navbar"
          description="A horizontal app bar with a leading slot, a title, and trailing actions. The one at the top of this page is a live instance."
          props={[
            {"color", "primary | secondary | tertiary | surface (default: primary)"},
            {"elevation", "resting elevation, 0-24 (default: 4)"},
            {"position", "static | sticky | fixed (default: static)"},
            {"paperize", "boolean (default: true)"}
          ]}
          code={~S"""
          <.pp_navbar position="sticky">
            <:leading><.pp_drawer_toggle for="app-drawer" /></:leading>
            My App
            <:actions>
              <.pp_button variant="icon"><.pp_icon name="hero-bell" /></.pp_button>
            </:actions>
          </.pp_navbar>
          """}
        >
          <.pp_navbar class="!static" color="surface">
            My App
            <:actions>
              <.pp_button variant="icon"><span class="hero-bell" /></.pp_button>
            </:actions>
          </.pp_navbar>
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
          code={~S"""
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
          """}
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
          code={~S"""
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
          """}
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
          description="A bare div (or span via tag=\"span\") — no paperize attr at all, since there's no default visual style to strip."
          props={[
            {"tag", "div | span (default: div)"}
          ]}
          code={~S"""
          <.pp_box class="rounded-lg bg-pp-surface-variant p-4">Just a div with a class.</.pp_box>
          """}
        >
          <.pp_box class="rounded-lg bg-pp-surface-variant p-4">Just a div with a class.</.pp_box>
        </.demo_section>

        <.demo_section
          id="container"
          title="Container"
          description="A centered, width-constrained wrapper — uses Tailwind's own sm/md/lg/xl/2xl screen scale rather than replicating MUI's specific pixel breakpoints. This whole page's content sits inside one."
          props={[
            {"max_width", "sm | md | lg | xl | 2xl | full (default: lg)"},
            {"paperize", "boolean (default: true)"}
          ]}
          code={~S"""
          <.pp_container max_width="sm">
            Narrower content.
          </.pp_container>
          """}
        >
          <.pp_container max_width="sm" class="!mx-0 rounded-lg bg-pp-surface-variant">
            This box is a Container with max_width="sm".
          </.pp_container>
        </.demo_section>

        <.demo_section
          id="stack"
          title="Stack"
          description="A one-dimensional flex layout with consistent spacing between children. No auto-divider — add <.pp_divider /> between children yourself."
          props={[
            {"direction", "row | column (default: column)"},
            {"spacing", "a Spacing token, :none | :xs | :sm | :md | :lg | :xl | :2xl (default: :md)"},
            {"wrap", "boolean (default: false)"}
          ]}
          code={~S"""
          <.pp_stack direction="row" spacing={:sm}>
            <.pp_button>Save</.pp_button>
            <.pp_button variant="outlined">Cancel</.pp_button>
          </.pp_stack>
          """}
        >
          <.pp_stack direction="row" spacing={:sm}>
            <.pp_button>Save</.pp_button>
            <.pp_button variant="outlined">Cancel</.pp_button>
          </.pp_stack>
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
          code={~S"""
          <.pp_grid>
            <.pp_grid_item span={12} md={4}>Sidebar</.pp_grid_item>
            <.pp_grid_item span={12} md={8}>Content</.pp_grid_item>
          </.pp_grid>
          """}
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
          props={[
            {"inset", "boolean — indent past a leading icon/avatar column instead of spanning full width (default: false)"}
          ]}
          code={~S"""
          <.pp_divider />
          <.pp_divider inset />
          """}
        >
          <div class="flex flex-col gap-2">
            <span class="text-sm">Above</span>
            <.pp_divider />
            <span class="text-sm">Below</span>
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
          code={~S"""
          <.pp_card>
            <:title>Account</:title>
            You have no pending invoices.
            <:actions>
              <.pp_button variant="text">Dismiss</.pp_button>
            </:actions>
          </.pp_card>
          """}
        >
          <.pp_card class="max-w-sm">
            <:title>Account</:title>
            You have no pending invoices.
            <:actions>
              <.pp_button variant="text">Dismiss</.pp_button>
            </:actions>
          </.pp_card>
        </.demo_section>

        <.demo_section
          id="icon"
          title="Icon"
          description="Just renders the app's existing heroicon classes — no bundled icon set, no extra dependency. This demo hand-rolls a few generic glyphs since it has no asset pipeline; a real app already has hero-* from mix phx.new."
          props={[
            {"name", "a heroicon class, e.g. \"hero-check\" (required)"},
            {"paperize", "boolean — only affects default sizing, not which icon shows (default: true)"}
          ]}
          code={~S"""
          <.pp_icon name="hero-check" class="text-pp-tertiary" />
          """}
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
          code={~S"""
          <.pp_image_list cols={3}>
            <.pp_image_list_item src="/images/1.jpg" title="Breakfast" />
            <.pp_image_list_item src="/images/2.jpg" title="Burger" subtitle="Restaurant" />
          </.pp_image_list>
          """}
        >
          <.pp_image_list cols={3}>
            <.pp_image_list_item src={@photo_1} title="Breakfast" />
            <.pp_image_list_item src={@photo_2} title="Burger" subtitle="Restaurant" />
            <.pp_image_list_item src={@photo_3} />
          </.pp_image_list>
        </.demo_section>

        <.demo_section
          id="ripple"
          title="Ripple (helper)"
          description="The Material ripple effect — a circle that expands from the click point and fades out. Vanilla inline onclick, no JS hook/bundler. Try clicking the buttons above."
          props={[
            {"ripple", "the boolean prop on Button, Fab, ToggleButton, and a linked ListItem — default true"},
            {"PhoenixPaper.Ripple.on_click/1", "returns the script, or nil when disabled (so the attribute is dropped entirely)"},
            {"PhoenixPaper.Ripple.container_classes/1", "the \"relative overflow-hidden\" the ripple needs to stay clipped"}
          ]}
          code={~S"""
          <.pp_button>Ripples (default)</.pp_button>
          <.pp_button ripple={false}>No ripple</.pp_button>
          """}
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
          props={[
            {"Elevation.class(level)", "returns the literal \"pp-elevation-N\" class name"}
          ]}
          code={~S"""
          <div class={["rounded-lg bg-pp-surface p-4", PhoenixPaper.Elevation.class(8)]}>8dp</div>
          """}
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
          code={~S"""
          <div class={["size-14 border-2 border-pp-primary", PhoenixPaper.Shape.class(:lg)]} />
          """}
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
          description="Colors are Tailwind v4 theme tokens backed by CSS custom properties, namespaced pp- so they never collide with daisyUI. Try the Indigo/Teal/Light/Dark buttons in the navbar above — no page reload, just flipping data-theme/data-pp-theme on <html>."
          props={[
            {"data-theme=\"dark\"", "on any ancestor — the same attribute daisyUI/Phoenix 1.8's generated app.css already use"},
            {"data-pp-theme=\"teal\"", "opts into the bundled alternate palette"},
            {"custom theme", "override the --color-pp-* variables from your own stylesheet — no build step, no JS config"}
          ]}
          code={~S"""
          <button phx-click={JS.set_attribute({"data-theme", "dark"}, to: "html")}>Dark</button>
          <button phx-click={JS.set_attribute({"data-pp-theme", "teal"}, to: "html")}>Teal</button>
          """}
        >
          <p class="text-sm opacity-70">Use the theme buttons in the navbar — this section is just documentation.</p>
        </.demo_section>
      </.pp_container>
    </div>
    """
  end
end

PhoenixPlayground.start(live: PhoenixPaperDemo, open_browser: false, port: 4001)
