defmodule PhoenixPaper.NumberField do
  @moduledoc """
  An MD3-styled number field (`pp_number_field/1`) — a numeric input
  between decrement/increment icon buttons, in an outlined or filled MD3
  field box (56dp, `body-large`, the same states as
  `PhoenixPaper.TextField`). The label sits above the box.

  The steppers use two lines of vanilla inline JS (`stepUp()`/`stepDown()`
  plus dispatching a real `input` event so `phx-change`/`phx-debounce` on
  the field still fire) — no JS hook, no bundler, no extra dependency.

  Migrating from 0.3: `helper_text` → `supporting_text`; `shape` is gone.
  """
  use Phoenix.Component

  alias PhoenixPaper.Helpers

  attr(:id, :any, default: nil)
  attr(:name, :any, default: nil)
  attr(:label, :string, default: nil)
  attr(:value, :any, default: nil)
  attr(:min, :any, default: nil)
  attr(:max, :any, default: nil)
  attr(:step, :any, default: 1)
  attr(:variant, :string, default: "outlined", values: ~w(outlined filled))

  attr(:field, Phoenix.HTML.FormField, default: nil)
  attr(:errors, :list, default: [])
  attr(:supporting_text, :string, default: nil)
  attr(:disabled, :boolean, default: false)
  attr(:paperize, :boolean, default: true)
  attr(:class, :any, default: nil)
  attr(:rest, :global, include: ~w(autocomplete autofocus form readonly required))

  def pp_number_field(%{field: %Phoenix.HTML.FormField{} = field} = assigns) do
    errors = if Phoenix.Component.used_input?(field), do: field.errors, else: []

    assigns
    |> assign(field: nil)
    |> assign(:name, assigns.name || field.name)
    |> assign(:id, assigns.id || field.id)
    |> assign(:value, assigns.value || field.value)
    |> assign(:errors, Enum.map(errors, &Helpers.translate_error/1))
    |> pp_number_field()
  end

  def pp_number_field(assigns) do
    assigns = assign(assigns, :input_id, assigns.id || assigns.name)

    ~H"""
    <div data-pp-component="number-field" class={Helpers.classes(@paperize, "flex flex-col gap-1", @class)}>
      <label
        :if={@label}
        for={@input_id}
        class={Helpers.classes(@paperize, "px-4 pp-body-small text-pp-on-surface-variant", nil)}
      >
        {@label}
      </label>

      <div class={Helpers.classes(@paperize, wrapper_classes(@variant, @errors), nil)}>
        <button
          type="button"
          tabindex="-1"
          disabled={@disabled}
          onclick={step_script(@input_id, "stepDown")}
          class={Helpers.classes(@paperize, stepper_classes(), nil)}
        >
          <PhoenixPaper.Icon.pp_icon name="hero-minus" />
        </button>
        <input
          type="number"
          id={@input_id}
          name={@name}
          value={@value}
          min={@min}
          max={@max}
          step={@step}
          disabled={@disabled}
          class={Helpers.classes(@paperize, input_classes(), nil)}
          {@rest}
        />
        <button
          type="button"
          tabindex="-1"
          disabled={@disabled}
          onclick={step_script(@input_id, "stepUp")}
          class={Helpers.classes(@paperize, stepper_classes(), nil)}
        >
          <PhoenixPaper.Icon.pp_icon name="hero-plus" />
        </button>
      </div>
      <p
        :if={@supporting_text && @errors == []}
        class={Helpers.classes(@paperize, "px-4 pp-body-small text-pp-on-surface-variant", nil)}
      >
        {@supporting_text}
      </p>
      <p :for={msg <- @errors} class={Helpers.classes(@paperize, "px-4 pp-body-small text-pp-error", nil)}>
        {msg}
      </p>
    </div>
    """
  end

  defp step_script(id, fun) do
    "var i=document.getElementById(#{inspect(to_string(id))});i.#{fun}();i.dispatchEvent(new Event('input',{bubbles:true}))"
  end

  defp wrapper_classes("outlined", []),
    do:
      "relative flex h-14 items-center gap-1 rounded-pp-xs border border-pp-outline px-1 hover:border-pp-on-surface focus-within:border-2 focus-within:!border-pp-primary has-[:disabled]:opacity-38"

  defp wrapper_classes("outlined", _errors),
    do: "relative flex h-14 items-center gap-1 rounded-pp-xs border-2 border-pp-error px-1"

  defp wrapper_classes("filled", []),
    do:
      "relative flex h-14 items-center gap-1 rounded-t-pp-xs bg-pp-surface-container-highest px-1 shadow-[inset_0_-1px_0_0_var(--color-pp-on-surface-variant)] focus-within:shadow-[inset_0_-2px_0_0_var(--color-pp-primary)] has-[:disabled]:opacity-38"

  defp wrapper_classes("filled", _errors),
    do:
      "relative flex h-14 items-center gap-1 rounded-t-pp-xs bg-pp-surface-container-highest px-1 shadow-[inset_0_-2px_0_0_var(--color-pp-error)]"

  defp input_classes do
    "w-full min-w-0 flex-1 bg-transparent px-1 text-center pp-body-large text-pp-on-surface outline-none [appearance:textfield] disabled:cursor-default [&::-webkit-inner-spin-button]:appearance-none [&::-webkit-outer-spin-button]:appearance-none"
  end

  # The steppers are standard MD3 icon buttons (40dp, on-surface-variant,
  # state layer).
  defp stepper_classes do
    "relative inline-flex size-10 shrink-0 cursor-pointer items-center justify-center overflow-hidden rounded-pp-full text-pp-on-surface-variant pp-state-layer pp-motion-spatial-fast active:rounded-pp-sm disabled:cursor-default disabled:text-pp-on-surface/38"
  end
end
