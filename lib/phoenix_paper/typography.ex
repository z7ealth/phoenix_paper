defmodule PhoenixPaper.Typography do
  @moduledoc """
  The MD3 type scale (`pp_typography/1`): 15 roles — display, headline,
  title, body and label, each large/medium/small — plus `code`.

      <.pp_typography variant="headline-medium">Account settings</.pp_typography>
      <.pp_typography variant="body-large">Regular paragraph text.</.pp_typography>
      <.pp_typography variant="label-small" color="on-surface-variant">
        Last updated 2 minutes ago
      </.pp_typography>

  Each role sets family, size, line height, tracking and weight together
  (the `pp-<role>` utilities in `phoenix_paper.css`). Display, headline and
  title-large use the *brand* typeface (`--font-pp-brand`), the rest the
  *plain* one (`--font-pp-plain`); both default to Roboto Flex, which
  PhoenixPaper doesn't load for you.

  `emphasized` turns on the M3 Expressive emphasized style: same metrics,
  heavier weight (medium for display/headline/title-large/body, bold for
  title-medium/small and labels).

  ## Tags

  `variant` picks a sensible default tag, and `tag` overrides it, so the
  visual role and the document outline stay independent (an `h2` that
  looks like `title-large` is common):

  | `variant`                         | default tag |
  |-----------------------------------|-------------|
  | `display-*`                       | `h1` |
  | `headline-large` / `-medium` / `-small` | `h2` / `h3` / `h4` |
  | `title-large`                     | `h5` |
  | `title-medium`, `title-small`     | `h6` |
  | `body-*`                          | `p` |
  | `label-*`                         | `span` |
  | `code`                            | `code` |

  ## Color

  Leave `color` unset to inherit. Otherwise pick a role: `primary`,
  `secondary`, `tertiary`, `error`, `on-surface` or `on-surface-variant`
  (MD3's de-emphasized text color, what MUI calls `text.secondary`).

  ## Migrating from 0.3

  | 0.3 variant  | 0.4 variant       |
  |--------------|-------------------|
  | `h1`         | `display-large`   |
  | `h2`         | `display-medium`  |
  | `h3`         | `display-small`   |
  | `h4`         | `headline-medium` |
  | `h5`         | `headline-small`  |
  | `h6`         | `title-large`     |
  | `subtitle1`  | `title-medium`    |
  | `subtitle2`  | `title-small`     |
  | `body1`      | `body-large`      |
  | `body2`      | `body-medium`     |
  | `caption`    | `body-small`      |
  | `overline`   | `label-small`     |
  | `button`     | `label-large`     |

  MD3 has no uppercase "overline" role; add `class="uppercase"` to a
  `label-small` if you want one.
  """
  use Phoenix.Component

  alias PhoenixPaper.Helpers

  @variants ~w(display-large display-medium display-small headline-large headline-medium headline-small title-large title-medium title-small body-large body-medium body-small label-large label-medium label-small code)

  attr(:variant, :string, default: "body-large", values: @variants)

  attr(:tag, :string,
    default: nil,
    values: [nil | ~w(h1 h2 h3 h4 h5 h6 p span div label legend figcaption code strong em small)],
    doc: "overrides the tag the variant picks"
  )

  attr(:emphasized, :boolean, default: false, doc: "M3 Expressive emphasized (heavier) style")

  attr(:color, :string,
    default: nil,
    values: [nil, "primary", "secondary", "tertiary", "error", "on-surface", "on-surface-variant"],
    doc: "text color role; unset inherits"
  )

  attr(:paperize, :boolean, default: true)
  attr(:class, :any, default: nil)
  attr(:rest, :global)

  slot(:inner_block, required: true)

  @doc "Renders text styled by the MD3 type scale. See the module doc."
  def pp_typography(assigns) do
    assigns = assign(assigns, :tag_name, assigns.tag || default_tag(assigns.variant))

    ~H"""
    <.dynamic_tag
      tag_name={@tag_name}
      data-pp-component="typography"
      class={Helpers.classes(@paperize, paper_classes(@variant, @emphasized, @color), @class)}
      {@rest}
    >{render_slot(@inner_block)}</.dynamic_tag>
    """
  end

  defp default_tag("display-" <> _), do: "h1"
  defp default_tag("headline-large"), do: "h2"
  defp default_tag("headline-medium"), do: "h3"
  defp default_tag("headline-small"), do: "h4"
  defp default_tag("title-large"), do: "h5"
  defp default_tag("title-" <> _), do: "h6"
  defp default_tag("body-" <> _), do: "p"
  defp default_tag("label-" <> _), do: "span"
  defp default_tag("code"), do: "code"

  defp paper_classes(variant, emphasized, color),
    do: [variant_classes(variant, emphasized), color_classes(color)]

  @doc false
  # Public so other components can reuse a role's utility by name.
  def variant_classes("display-large", false), do: "pp-display-large"
  def variant_classes("display-medium", false), do: "pp-display-medium"
  def variant_classes("display-small", false), do: "pp-display-small"
  def variant_classes("headline-large", false), do: "pp-headline-large"
  def variant_classes("headline-medium", false), do: "pp-headline-medium"
  def variant_classes("headline-small", false), do: "pp-headline-small"
  def variant_classes("title-large", false), do: "pp-title-large"
  def variant_classes("title-medium", false), do: "pp-title-medium"
  def variant_classes("title-small", false), do: "pp-title-small"
  def variant_classes("body-large", false), do: "pp-body-large"
  def variant_classes("body-medium", false), do: "pp-body-medium"
  def variant_classes("body-small", false), do: "pp-body-small"
  def variant_classes("label-large", false), do: "pp-label-large"
  def variant_classes("label-medium", false), do: "pp-label-medium"
  def variant_classes("label-small", false), do: "pp-label-small"
  def variant_classes("code", false), do: "font-mono text-[0.8125rem] leading-5"

  def variant_classes("display-large", true), do: "pp-display-large-emphasized"
  def variant_classes("display-medium", true), do: "pp-display-medium-emphasized"
  def variant_classes("display-small", true), do: "pp-display-small-emphasized"
  def variant_classes("headline-large", true), do: "pp-headline-large-emphasized"
  def variant_classes("headline-medium", true), do: "pp-headline-medium-emphasized"
  def variant_classes("headline-small", true), do: "pp-headline-small-emphasized"
  def variant_classes("title-large", true), do: "pp-title-large-emphasized"
  def variant_classes("title-medium", true), do: "pp-title-medium-emphasized"
  def variant_classes("title-small", true), do: "pp-title-small-emphasized"
  def variant_classes("body-large", true), do: "pp-body-large-emphasized"
  def variant_classes("body-medium", true), do: "pp-body-medium-emphasized"
  def variant_classes("body-small", true), do: "pp-body-small-emphasized"
  def variant_classes("label-large", true), do: "pp-label-large-emphasized"
  def variant_classes("label-medium", true), do: "pp-label-medium-emphasized"
  def variant_classes("label-small", true), do: "pp-label-small-emphasized"
  def variant_classes("code", true), do: "font-mono font-semibold text-[0.8125rem] leading-5"

  defp color_classes(nil), do: nil
  defp color_classes("primary"), do: "text-pp-primary"
  defp color_classes("secondary"), do: "text-pp-secondary"
  defp color_classes("tertiary"), do: "text-pp-tertiary"
  defp color_classes("error"), do: "text-pp-error"
  defp color_classes("on-surface"), do: "text-pp-on-surface"
  defp color_classes("on-surface-variant"), do: "text-pp-on-surface-variant"
end
