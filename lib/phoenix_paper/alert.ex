defmodule PhoenixPaper.Alert do
  @moduledoc """
  A Material-flavored alert banner (`pp_alert/1`) — a colored, icon-led
  message for status feedback, in the spirit of MUI's `Alert`.

      <.pp_alert severity="success">Changes saved.</.pp_alert>

      <.pp_alert severity="error" variant="outlined">
        <:title>Something went wrong</:title>
        Could not save your changes. Try again.
        <:action><.pp_button variant="text">Retry</.pp_button></:action>
      </.pp_alert>

  `severity` (`success`/`info`/`warning`/`error`) picks both the color and
  the leading icon — a distinct axis from every other component's `color`
  attr (`primary`/`secondary`/`tertiary`/`error`), since these are status
  colors (see `priv/static/phoenix_paper.css`'s `--color-pp-success`/
  `-warning`/`-info`), not brand/action colors. `error` happens to be the
  one name shared with the rest of the library's `color` scale, and does
  mean the same red in both places.
  """
  use Phoenix.Component

  alias PhoenixPaper.Helpers

  import PhoenixPaper.Icon, only: [pp_icon: 1]

  attr(:paperize, :boolean, default: true)
  attr(:severity, :string, default: "info", values: ~w(success info warning error))
  attr(:variant, :string, default: "standard", values: ~w(standard outlined filled))
  attr(:class, :any, default: nil)
  attr(:rest, :global)

  slot(:title)
  slot(:action)
  slot(:inner_block, required: true)

  @doc "Renders an alert. See the module doc."
  def pp_alert(assigns) do
    ~H"""
    <div
      role="alert"
      data-pp-component="alert"
      data-pp-severity={@severity}
      class={Helpers.classes(@paperize, paper_classes(@severity, @variant), @class)}
      {@rest}
    >
      <.pp_icon name={icon_name(@severity)} class={icon_classes(@severity, @variant)} />
      <div class="min-w-0 flex-1">
        <div :if={@title != []} class="mb-0.5 font-medium">{render_slot(@title)}</div>
        <div class="text-sm">{render_slot(@inner_block)}</div>
      </div>
      <div :if={@action != []} class="flex shrink-0 items-center">{render_slot(@action)}</div>
    </div>
    """
  end

  defp icon_name("success"), do: "hero-check-circle"
  defp icon_name("info"), do: "hero-information-circle"
  defp icon_name("warning"), do: "hero-exclamation-triangle"
  defp icon_name("error"), do: "hero-x-circle"

  defp icon_classes(_severity, "filled"), do: "shrink-0"
  defp icon_classes("success", _variant), do: "shrink-0 text-pp-success"
  defp icon_classes("info", _variant), do: "shrink-0 text-pp-info"
  defp icon_classes("warning", _variant), do: "shrink-0 text-pp-warning"
  defp icon_classes("error", _variant), do: "shrink-0 text-pp-error"

  defp paper_classes(severity, variant) do
    ["flex items-start gap-3 rounded-lg px-4 py-3 text-sm", variant_classes(severity, variant)]
  end

  defp variant_classes("success", "standard"), do: "bg-pp-success/10 text-pp-on-surface"
  defp variant_classes("info", "standard"), do: "bg-pp-info/10 text-pp-on-surface"
  defp variant_classes("warning", "standard"), do: "bg-pp-warning/10 text-pp-on-surface"
  defp variant_classes("error", "standard"), do: "bg-pp-error/10 text-pp-on-surface"

  defp variant_classes("success", "outlined"),
    do: "border border-pp-success bg-transparent text-pp-on-surface"

  defp variant_classes("info", "outlined"),
    do: "border border-pp-info bg-transparent text-pp-on-surface"

  defp variant_classes("warning", "outlined"),
    do: "border border-pp-warning bg-transparent text-pp-on-surface"

  defp variant_classes("error", "outlined"),
    do: "border border-pp-error bg-transparent text-pp-on-surface"

  defp variant_classes("success", "filled"), do: "bg-pp-success text-pp-on-success"
  defp variant_classes("info", "filled"), do: "bg-pp-info text-pp-on-info"
  defp variant_classes("warning", "filled"), do: "bg-pp-warning text-pp-on-warning"
  defp variant_classes("error", "filled"), do: "bg-pp-error text-pp-on-error"
end
