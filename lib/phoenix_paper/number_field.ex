defmodule PhoenixPaper.NumberField do
  @moduledoc """
  A Material Design number field (`pp_number_field/1`) — a numeric input
  with increment/decrement stepper buttons.

  The steppers use two lines of vanilla inline JS (`stepUp()`/`stepDown()`
  plus dispatching a real `input` event so `phx-change`/`phx-debounce` on
  the field still fire) — no JS hook, no bundler, no extra dependency.
  """
  use Phoenix.Component

  alias PhoenixPaper.{Helpers, Shape}

  attr(:id, :any, default: nil)
  attr(:name, :any, default: nil)
  attr(:label, :string, default: nil)
  attr(:value, :any, default: nil)
  attr(:min, :any, default: nil)
  attr(:max, :any, default: nil)
  attr(:step, :any, default: 1)
  attr(:variant, :string, default: "outlined", values: ~w(outlined filled))

  attr(:shape, :atom,
    default: :sm,
    values: ~w(none xs sm md lg xl full)a,
    doc: "corner radius token, see PhoenixPaper.Shape"
  )

  attr(:field, Phoenix.HTML.FormField, default: nil)
  attr(:errors, :list, default: [])
  attr(:helper_text, :string, default: nil)
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
      <label :if={@label} for={@input_id} class="text-xs font-medium text-pp-outline">{@label}</label>

      <div class={Helpers.classes(@paperize, wrapper_classes(@variant, @shape, @errors), nil)}>
        <button
          type="button"
          tabindex="-1"
          disabled={@disabled}
          onclick={step_script(@input_id, "stepDown")}
          class={Helpers.classes(@paperize, stepper_classes(), nil)}
        >
          {"−"}
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
          {"+"}
        </button>
      </div>
      <p :if={@helper_text && @errors == []} class="text-xs text-pp-outline">{@helper_text}</p>
      <p :for={msg <- @errors} class="text-xs text-pp-error">{msg}</p>
    </div>
    """
  end

  defp step_script(id, fun) do
    "var i=document.getElementById(#{inspect(to_string(id))});i.#{fun}();i.dispatchEvent(new Event('input',{bubbles:true}))"
  end

  defp wrapper_classes("outlined", shape, []) do
    [
      "relative flex items-center border border-pp-outline transition-colors focus-within:border-2 focus-within:border-pp-primary",
      Shape.class(shape)
    ]
  end

  defp wrapper_classes("outlined", shape, _errors) do
    ["relative flex items-center border-2 border-pp-error", Shape.class(shape)]
  end

  defp wrapper_classes("filled", shape, []) do
    [
      "relative flex items-center border-b border-pp-outline bg-pp-surface-variant transition-colors focus-within:border-b-2 focus-within:border-pp-primary",
      Shape.class(shape, :top)
    ]
  end

  defp wrapper_classes("filled", shape, _errors) do
    [
      "relative flex items-center border-b-2 border-pp-error bg-pp-surface-variant",
      Shape.class(shape, :top)
    ]
  end

  defp input_classes do
    "w-full min-w-0 flex-1 bg-transparent px-1 py-2 text-center text-sm text-pp-on-surface outline-none [appearance:textfield] disabled:cursor-not-allowed disabled:opacity-40 [&::-webkit-inner-spin-button]:appearance-none [&::-webkit-outer-spin-button]:appearance-none"
  end

  defp stepper_classes do
    "shrink-0 cursor-pointer px-3 py-2 text-lg leading-none text-pp-on-surface transition-colors hover:bg-pp-on-surface/10 disabled:cursor-not-allowed disabled:opacity-40"
  end
end
