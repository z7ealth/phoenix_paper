defmodule PhoenixPaper.Collapse do
  @moduledoc """
  A trigger that shows and hides a block of content (`pp_collapse/1`),
  in the spirit of MUI's `Collapse` — the lightweight option when
  `PhoenixPaper.Accordion`'s surface, summary/details split and shared
  `id` across three components are more than you need ("Show code",
  "Show more", an advanced-options block, a collapsible nav group).

      <.pp_collapse id="advanced">
        <:trigger>Advanced options</:trigger>
        <.pp_input name="timeout" label="Timeout" />
      </.pp_collapse>

  Pure CSS, the same hidden-checkbox-plus-`peer-checked:` trick as
  `Accordion`/`Drawer` (see AGENTS.md, "CSS-only interactive state"): the
  visually hidden checkbox, the trigger `<label for>` and the content are
  flat siblings. `default_open` sets the checkbox's initial state; it's
  uncontrolled after that, so a later LiveView re-render doesn't fight
  the user over it.

  The content animates its height open and closed with the
  `grid-template-rows: 0fr → 1fr` technique (no measuring, no JS), and is
  `invisible` while closed so links and inputs inside it can't be tabbed
  to. The trigger shows a chevron that flips when open; `icon={false}`
  drops it.

  The show/hide wiring (checkbox, `grid`, `invisible`, the transition) is
  unconditional — it's how the component works, not skin, so it survives
  `paperize={false}`. Only the trigger's look (padding, hover tint, focus
  ring, chevron) is paperize-gated. Style the trigger with `trigger_class`
  and the root with `class`.

  Like the other CSS-only reveals, there's no `aria-expanded` (a state a
  CSS-only component can't name); the trigger is a native `<label>` for a
  focusable checkbox, so it's still keyboard-operable (Tab to it, Space
  to toggle).
  """
  use Phoenix.Component

  alias PhoenixPaper.Helpers
  import PhoenixPaper.Icon, only: [pp_icon: 1]

  attr(:id, :string, required: true)
  attr(:default_open, :boolean, default: false)
  attr(:icon, :boolean, default: true, doc: "show the expand/collapse chevron on the trigger")
  attr(:trigger_class, :any, default: nil, doc: "extra classes for the trigger label")
  attr(:content_class, :any, default: nil, doc: "extra classes for the content wrapper")
  attr(:paperize, :boolean, default: true)
  attr(:class, :any, default: nil)
  attr(:rest, :global)

  slot(:trigger, required: true, doc: "the clickable label that toggles the content")
  slot(:inner_block, required: true, doc: "the content shown while open")

  @doc "Renders a collapsible block. See the module doc."
  def pp_collapse(assigns) do
    ~H"""
    <div data-pp-component="collapse" class={Helpers.classes(@paperize, nil, @class)} {@rest}>
      <input
        type="checkbox"
        id={toggle_id(@id)}
        checked={@default_open}
        aria-controls={content_id(@id)}
        class="peer sr-only"
      />
      <label
        for={toggle_id(@id)}
        data-pp-collapse-trigger
        class={[
          "cursor-pointer",
          Helpers.classes(@paperize, trigger_classes(), @trigger_class)
        ]}
      >
        <span class="min-w-0 flex-1">{render_slot(@trigger)}</span>
        <span
          :if={@icon && @paperize}
          data-pp-collapse-icon
          class="inline-flex shrink-0 transition-transform duration-200"
        >
          <.pp_icon name="hero-chevron-down-mini" class="!size-5" />
        </span>
      </label>
      <div
        id={content_id(@id)}
        data-pp-collapse-content
        class={content_classes()}
      >
        <div class={["min-h-0 overflow-hidden", @content_class]}>
          {render_slot(@inner_block)}
        </div>
      </div>
    </div>
    """
  end

  @doc false
  def toggle_id(id), do: "#{id}-toggle"

  @doc false
  def content_id(id), do: "#{id}-content"

  # Shared with `PhoenixPaper.List.pp_list_group/1`, which renders the same
  # checkbox/label/content structure with a list-item-shaped trigger.
  @doc false
  def content_classes do
    "invisible grid grid-rows-[0fr] transition-[grid-template-rows,visibility] duration-200 ease-out peer-checked:visible peer-checked:grid-rows-[1fr]"
  end

  # The chevron is a child of the label, not a sibling of the checkbox, so
  # it's rotated from the label with a compound selector keyed off the
  # label's own `peer-checked:` state.
  defp trigger_classes do
    "flex select-none items-center gap-2 rounded-md px-2 py-1.5 text-sm font-medium transition-colors hover:bg-pp-on-surface/5 peer-focus-visible:outline peer-focus-visible:outline-2 peer-focus-visible:outline-pp-primary peer-checked:[&>[data-pp-collapse-icon]]:rotate-180"
  end
end
