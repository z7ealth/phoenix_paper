defmodule PhoenixPaper.Input do
  @moduledoc """
  A Material Design text field (`pp_input/1`) with a floating label — pure
  CSS, no JavaScript. Two variants: `outlined` (bordered box) and `filled`
  (filled background with an underline accent).

  Accepts either a Phoenix `Phoenix.HTML.FormField` via `field=` (idiomatic
  `to_form/2` usage, same as the default `core_components.ex` input) or
  plain `name`/`value` attrs.
  """
  use Phoenix.Component

  alias PhoenixPaper.{Helpers, Shape}

  attr(:id, :any, default: nil)
  attr(:name, :any, default: nil)
  attr(:label, :string, default: nil)
  attr(:value, :any, default: nil)
  attr(:type, :string, default: "text")
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

  attr(:rest, :global,
    include:
      ~w(autocomplete autofocus form list max maxlength min minlength pattern placeholder readonly required step)
  )

  def pp_input(%{field: %Phoenix.HTML.FormField{} = field} = assigns) do
    errors = if Phoenix.Component.used_input?(field), do: field.errors, else: []

    assigns
    |> assign(field: nil)
    |> assign_new(:name, fn -> field.name end)
    |> assign_new(:id, fn -> field.id end)
    |> assign_new(:value, fn -> field.value end)
    |> assign(:errors, Enum.map(errors, &Helpers.translate_error/1))
    |> pp_input()
  end

  def pp_input(assigns) do
    ~H"""
    <div data-pp-component="input" class={Helpers.classes(@paperize, "flex flex-col gap-1", @class)}>
      <div class={Helpers.classes(@paperize, wrapper_classes(@variant, @shape, @errors), nil)}>
        <input
          type={@type}
          id={@id}
          name={@name}
          value={@value}
          disabled={@disabled}
          placeholder=" "
          class={Helpers.classes(@paperize, input_classes(@variant), nil)}
          {@rest}
        />
        <label :if={@label} for={@id} class={Helpers.classes(@paperize, label_classes(@variant, @errors), nil)}>
          {@label}
        </label>
      </div>
      <p :if={@helper_text && @errors == []} class="text-xs text-pp-outline">{@helper_text}</p>
      <p :for={msg <- @errors} class="text-xs text-pp-error">{msg}</p>
    </div>
    """
  end

  defp wrapper_classes("outlined", shape, []) do
    [
      "relative border border-pp-outline transition-colors focus-within:border-2 focus-within:border-pp-primary",
      Shape.class(shape)
    ]
  end

  defp wrapper_classes("outlined", shape, _errors) do
    ["relative border-2 border-pp-error", Shape.class(shape)]
  end

  defp wrapper_classes("filled", shape, []) do
    [
      "relative border-b border-pp-outline bg-pp-surface-variant transition-colors focus-within:border-b-2 focus-within:border-pp-primary",
      Shape.class(shape, :top)
    ]
  end

  defp wrapper_classes("filled", shape, _errors) do
    ["relative border-b-2 border-pp-error bg-pp-surface-variant", Shape.class(shape, :top)]
  end

  defp input_classes(_variant) do
    "peer block w-full bg-transparent px-3 pt-5 pb-2 text-sm text-pp-on-surface outline-none placeholder:text-transparent disabled:cursor-not-allowed disabled:opacity-40"
  end

  defp label_classes(_variant, []) do
    "pointer-events-none absolute left-3 top-1/2 -translate-y-1/2 text-sm text-pp-outline transition-all peer-focus:top-3 peer-focus:text-xs peer-focus:text-pp-primary peer-[:not(:placeholder-shown)]:top-3 peer-[:not(:placeholder-shown)]:text-xs"
  end

  defp label_classes(_variant, _errors) do
    "pointer-events-none absolute left-3 top-1/2 -translate-y-1/2 text-sm text-pp-error transition-all peer-focus:top-3 peer-focus:text-xs peer-[:not(:placeholder-shown)]:top-3 peer-[:not(:placeholder-shown)]:text-xs"
  end
end
