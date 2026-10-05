defmodule PhoenixPaper.Checkbox do
  @moduledoc """
  An MD3 checkbox (`pp_checkbox/1`).

      <.pp_checkbox field={@form[:terms]} label="I accept the terms" />
      <.pp_checkbox name="all" label="Select all" indeterminate />

  Accepts a `Phoenix.HTML.FormField` via `field=` or plain
  `name`/`checked`. An unchecked box still submits `"false"` (a hidden
  input before the real one, like a generated `core_components.ex`).

  MD3 look: an 18dp box with 2dp corners and a 2dp `on-surface-variant`
  border, filled `primary` with an `on-primary` check when checked, inside
  a 40dp circular state layer (hover 8%, keyboard focus and press 10%) that
  reacts anywhere on the label. `error` paints it in the error role.
  `indeterminate` shows a dash and `aria-checked="mixed"` — HTML has no
  indeterminate attribute (it's a JS-only property), so this is the
  visual state only; the input still submits its checked value.

  Under `paperize={false}` it's a bare native checkbox (no hidden-input
  trick, no custom box) and `class` targets that input, so
  `class="size-5"` sizes the checkbox itself.

  `ripple` adds the centered ripple on click (off by default — the fill
  change is feedback enough on a target this small).
  """
  use Phoenix.Component

  alias PhoenixPaper.{Helpers, Ripple}

  attr(:id, :any, default: nil)
  attr(:name, :any, default: nil)
  attr(:value, :any, default: "true")
  attr(:label, :string, default: nil)
  attr(:field, Phoenix.HTML.FormField, default: nil)
  attr(:checked, :boolean, default: nil)
  attr(:indeterminate, :boolean, default: false)
  attr(:error, :boolean, default: false)
  attr(:paperize, :boolean, default: true)

  attr(:ripple, :boolean,
    default: false,
    doc: "the centered ripple on click, see PhoenixPaper.Ripple"
  )

  attr(:disabled, :boolean, default: false)
  attr(:class, :any, default: nil)
  attr(:rest, :global, include: ~w(form autofocus))

  @doc "Renders a checkbox. See the module doc."
  def pp_checkbox(%{field: %Phoenix.HTML.FormField{} = field} = assigns) do
    assigns
    |> assign(field: nil)
    |> assign(:name, assigns.name || field.name)
    |> assign(:id, assigns.id || field.id)
    |> assign(
      :checked,
      if(is_nil(assigns.checked),
        do: Phoenix.HTML.Form.normalize_value("checkbox", field.value),
        else: assigns.checked
      )
    )
    |> pp_checkbox()
  end

  def pp_checkbox(assigns) do
    assigns =
      assigns
      |> assign(:checked, assigns.checked || false)
      |> assign(:ripple?, assigns.ripple and assigns.paperize)

    ~H"""
    <label data-pp-component="checkbox" class={Helpers.toggle_label_classes(if @paperize, do: @class)}>
      <input :if={@paperize} type="hidden" name={@name} value="false" disabled={@disabled} />

      <span
        :if={@paperize}
        class="relative -m-[11px] inline-flex size-10 shrink-0 items-center justify-center rounded-full has-[:disabled]:opacity-38"
        onclick={Ripple.on_click_centered(@ripple?)}
      >
        <input
          type="checkbox"
          id={@id}
          name={@name}
          value={@value}
          checked={@checked}
          disabled={@disabled}
          aria-checked={@indeterminate && "mixed"}
          aria-invalid={@error && "true"}
          class="peer absolute inset-0 z-10 m-0 cursor-pointer opacity-0 disabled:cursor-default"
          {@rest}
        />
        <span class={["pp-state-layer-target absolute inset-0 rounded-full", layer_color(@error)]} />
        <span class={box_classes(@error, @indeterminate)}>
          <svg :if={!@indeterminate} viewBox="0 0 18 18" class="size-full" aria-hidden="true">
            <path
              d="M4.5 9.5l3 3 6-7"
              fill="none"
              stroke="currentColor"
              stroke-width="2"
              stroke-linecap="round"
              stroke-linejoin="round"
              class="[stroke-dasharray:16] [stroke-dashoffset:16] transition-[stroke-dashoffset] duration-200 ease-pp-emphasized-decelerate [:checked~span>svg>&]:[stroke-dashoffset:0]"
            />
          </svg>
          <span :if={@indeterminate} class="h-0.5 w-2.5 rounded-full bg-current" />
        </span>
      </span>

      <input
        :if={!@paperize}
        type="checkbox"
        id={@id}
        name={@name}
        value={@value}
        checked={@checked}
        disabled={@disabled}
        class={@class}
        {@rest}
      />

      <span :if={@label} class={@paperize && "pp-body-large text-pp-on-surface"}>{@label}</span>
    </label>
    """
  end

  defp layer_color(false), do: "text-pp-on-surface peer-checked:text-pp-primary"
  defp layer_color(true), do: "text-pp-error"

  # Unchecked: the outline box. Checked (peer-checked) or indeterminate:
  # filled, border dropped into the fill color.
  defp box_classes(false, false),
    do:
      "pointer-events-none relative inline-flex size-[18px] items-center justify-center rounded-[2px] border-2 border-pp-on-surface-variant text-pp-on-primary transition-colors duration-150 peer-checked:border-pp-primary peer-checked:bg-pp-primary"

  defp box_classes(false, true),
    do:
      "pointer-events-none relative inline-flex size-[18px] items-center justify-center rounded-[2px] border-2 border-pp-primary bg-pp-primary text-pp-on-primary"

  defp box_classes(true, false),
    do:
      "pointer-events-none relative inline-flex size-[18px] items-center justify-center rounded-[2px] border-2 border-pp-error text-pp-on-error transition-colors duration-150 peer-checked:bg-pp-error"

  defp box_classes(true, true),
    do:
      "pointer-events-none relative inline-flex size-[18px] items-center justify-center rounded-[2px] border-2 border-pp-error bg-pp-error text-pp-on-error"
end
