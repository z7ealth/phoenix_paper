defmodule PhoenixPaper.Checkbox do
  @moduledoc """
  A Material Design checkbox (`pp_checkbox/1`).

  Accepts either a Phoenix `Phoenix.HTML.FormField` via `field=` (idiomatic
  `to_form/2` usage, same as the default `core_components.ex` input) or plain
  `name`/`checked` attrs.

  When `paperize` is `false` this renders a bare native `<input
  type="checkbox">` (no hidden-input trick, no custom box) so it never fights
  a caller's own CSS — `class` targets that bare input directly in this
  case (not the wrapping `<label>`, which keeps its own unconditional
  layout classes regardless of `paperize`; see
  `PhoenixPaper.Helpers.toggle_label_classes/1`), so e.g.
  `class="size-5"` sizes the checkbox itself as expected.

  Ripples on click by default, wired to the small box rather than the whole
  label — see `PhoenixPaper.Ripple`.
  """
  use Phoenix.Component

  alias PhoenixPaper.{Helpers, Ripple, Shape}

  attr(:id, :any, default: nil)
  attr(:name, :any, default: nil)
  attr(:value, :any, default: "true")
  attr(:label, :string, default: nil)
  attr(:field, Phoenix.HTML.FormField, default: nil)
  attr(:checked, :boolean, default: nil)
  attr(:paperize, :boolean, default: true)

  attr(:ripple, :boolean,
    default: true,
    doc:
      "the Material ripple effect on click/tap — off whenever paperize is false, see PhoenixPaper.Ripple"
  )

  attr(:disabled, :boolean, default: false)
  attr(:class, :any, default: nil)
  attr(:rest, :global, include: ~w(form autofocus phx-click))

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
        class={[
          "has-[:checked]:border-pp-primary has-[:checked]:bg-pp-primary relative inline-flex size-5 shrink-0 items-center justify-center border-2 border-pp-outline transition-colors",
          Shape.class(:xs)
        ]}
        onclick={Ripple.on_click_centered(@ripple?)}
      >
        <input
          type="checkbox"
          id={@id}
          name={@name}
          value={@value}
          checked={@checked}
          disabled={@disabled}
          class="peer absolute inset-0 m-0 cursor-pointer opacity-0 disabled:cursor-not-allowed"
          {@rest}
        />
        <span class="pp-checkbox-check pointer-events-none opacity-0 peer-checked:opacity-100 text-pp-on-primary text-xs">
          {"✓"}
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

      <span :if={@label}>{@label}</span>
    </label>
    """
  end
end
