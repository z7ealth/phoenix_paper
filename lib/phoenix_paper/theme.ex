defmodule PhoenixPaper.Theme do
  @moduledoc """
  Generates MD3 color schemes from a seed color — the engine behind
  `mix phoenix_paper.gen.theme`.

  As in Material Theme Builder, a seed becomes five tonal palettes (hue
  and chroma in `PhoenixPaper.Theme.Hct`, every tone 0–100 available)
  plus an error palette, and every MD3 color role is one tone of one
  palette — `primary` is tone 40 of the primary palette in light mode and
  tone 80 in dark, `surface-container` tone 94 / 12 of the neutral
  palette, and so on. Because tone is CIELAB L*, those fixed tone pairs
  give MD3's contrast guarantees for any hue.

      PhoenixPaper.Theme.scheme("#0b57d0", :light)["primary"]
      #=> "#3a5ba9" (approximately)

  ## Scheme variants

  | `variant` | palettes (hue, chroma) |
  |-----------|------------------------|
  | `:tonal_spot` (default, MD3's default) | primary (h, 36), secondary (h, 16), tertiary (h+60, 24), neutral (h, 6), neutral variant (h, 8) |
  | `:neutral` | primary (h, 12), secondary (h, 8), tertiary (h, 16), neutral (h, 2), neutral variant (h, 2) |
  | `:vibrant` | primary (h, 200 → as vivid as the gamut allows), secondary (h, 24), tertiary (h+60, 32), neutral (h, 10), neutral variant (h, 12) |
  | `:expressive` | primary (h+240, 40), secondary (h+15, 24), tertiary (h+90, 32), neutral (h+15, 8), neutral variant (h+15, 12) |
  | `:fidelity` | primary keeps the seed's own chroma, secondary (h, max(c−32, c/2)), tertiary (h+60, max(c/2, 24)), neutral (h, c/8), neutral variant (h, c/8+4) |
  | `:monochrome` | everything at chroma 0 |

  These follow material-color-utilities' scheme definitions, simplified
  where the library uses lookup tables or a "dislike" adjustment
  (`:vibrant`/`:expressive` hue rotations are fixed offsets here; the
  `:fidelity` tertiary isn't the analyzed complement). `:tonal_spot`,
  `:neutral` and `:monochrome` match the library's definitions.

  Core colors can be pinned like Theme Builder's "custom colors":
  `secondary:`, `tertiary:`, `neutral:`, `error:` take a hex whose hue
  and chroma replace that palette's.
  """

  alias PhoenixPaper.Theme.Hct

  @variants ~w(tonal_spot neutral vibrant expressive fidelity monochrome)a

  @doc "The supported scheme variants."
  def variants, do: @variants

  @doc """
  The tonal palettes for a seed: a map of `:primary`, `:secondary`,
  `:tertiary`, `:neutral`, `:neutral_variant` and `:error` to
  `{hue, chroma}`.
  """
  def palettes(seed, opts \\ []) do
    variant = Keyword.get(opts, :variant, :tonal_spot)
    {h, c, _tone} = Hct.from_hex(seed)

    base =
      case variant do
        :tonal_spot ->
          %{
            primary: {h, 36},
            secondary: {h, 16},
            tertiary: {h + 60, 24},
            neutral: {h, 6},
            neutral_variant: {h, 8}
          }

        :neutral ->
          %{
            primary: {h, 12},
            secondary: {h, 8},
            tertiary: {h, 16},
            neutral: {h, 2},
            neutral_variant: {h, 2}
          }

        :vibrant ->
          %{
            primary: {h, 200},
            secondary: {h, 24},
            tertiary: {h + 60, 32},
            neutral: {h, 10},
            neutral_variant: {h, 12}
          }

        :expressive ->
          %{
            primary: {h + 240, 40},
            secondary: {h + 15, 24},
            tertiary: {h + 90, 32},
            neutral: {h + 15, 8},
            neutral_variant: {h + 15, 12}
          }

        :fidelity ->
          %{
            primary: {h, c},
            secondary: {h, max(c - 32, c * 0.5)},
            tertiary: {h + 60, max(c * 0.5, 24)},
            neutral: {h, c / 8},
            neutral_variant: {h, c / 8 + 4}
          }

        :monochrome ->
          %{
            primary: {h, 0},
            secondary: {h, 0},
            tertiary: {h, 0},
            neutral: {h, 0},
            neutral_variant: {h, 0}
          }
      end

    base
    |> Map.put(:error, {25, 84})
    |> pin(:secondary, opts[:secondary])
    |> pin(:tertiary, opts[:tertiary])
    |> pin(:neutral, opts[:neutral])
    |> pin(:error, opts[:error])
    |> Map.new(fn {k, {hue, chroma}} -> {k, {Hct.normalize_hue(hue / 1), chroma / 1}} end)
  end

  defp pin(palettes, _key, nil), do: palettes

  defp pin(palettes, key, hex) do
    {h, c, _} = Hct.from_hex(hex)
    Map.put(palettes, key, {h, c})
  end

  # Role → {palette, light tone, dark tone}. The MD3 (2024+) tone mapping.
  @roles [
    {"primary", :primary, 40, 80},
    {"on-primary", :primary, 100, 20},
    {"primary-container", :primary, 90, 30},
    {"on-primary-container", :primary, 30, 90},
    {"secondary", :secondary, 40, 80},
    {"on-secondary", :secondary, 100, 20},
    {"secondary-container", :secondary, 90, 30},
    {"on-secondary-container", :secondary, 30, 90},
    {"tertiary", :tertiary, 40, 80},
    {"on-tertiary", :tertiary, 100, 20},
    {"tertiary-container", :tertiary, 90, 30},
    {"on-tertiary-container", :tertiary, 30, 90},
    {"error", :error, 40, 80},
    {"on-error", :error, 100, 20},
    {"error-container", :error, 90, 30},
    {"on-error-container", :error, 30, 90},
    {"primary-fixed", :primary, 90, 90},
    {"primary-fixed-dim", :primary, 80, 80},
    {"on-primary-fixed", :primary, 10, 10},
    {"on-primary-fixed-variant", :primary, 30, 30},
    {"secondary-fixed", :secondary, 90, 90},
    {"secondary-fixed-dim", :secondary, 80, 80},
    {"on-secondary-fixed", :secondary, 10, 10},
    {"on-secondary-fixed-variant", :secondary, 30, 30},
    {"tertiary-fixed", :tertiary, 90, 90},
    {"tertiary-fixed-dim", :tertiary, 80, 80},
    {"on-tertiary-fixed", :tertiary, 10, 10},
    {"on-tertiary-fixed-variant", :tertiary, 30, 30},
    {"surface", :neutral, 98, 6},
    {"surface-dim", :neutral, 87, 6},
    {"surface-bright", :neutral, 98, 24},
    {"surface-container-lowest", :neutral, 100, 4},
    {"surface-container-low", :neutral, 96, 10},
    {"surface-container", :neutral, 94, 12},
    {"surface-container-high", :neutral, 92, 17},
    {"surface-container-highest", :neutral, 90, 22},
    {"surface-variant", :neutral_variant, 90, 30},
    {"on-surface", :neutral, 10, 90},
    {"on-surface-variant", :neutral_variant, 30, 80},
    {"outline", :neutral_variant, 50, 60},
    {"outline-variant", :neutral_variant, 80, 30},
    {"inverse-surface", :neutral, 20, 90},
    {"inverse-on-surface", :neutral, 95, 20},
    {"inverse-primary", :primary, 80, 40},
    {"shadow", :neutral, 0, 0},
    {"scrim", :neutral, 0, 0}
  ]

  @doc """
  A scheme: a map of role name (`"primary"`, `"surface-container-high"`,
  ...) to hex, for `mode` `:light` or `:dark`. Options as for
  `palettes/2`.
  """
  def scheme(seed, mode, opts \\ []) when mode in [:light, :dark] do
    palettes = palettes(seed, opts)

    Map.new(@roles, fn {name, palette, light, dark} ->
      {hue, chroma} = Map.fetch!(palettes, palette)
      {name, Hct.to_hex(hue, chroma, if(mode == :light, do: light, else: dark))}
    end)
  end

  @doc "The role names, in output order."
  def role_names, do: Enum.map(@roles, &elem(&1, 0))

  @doc """
  The CSS for a theme: `--color-pp-*` overrides for light (`:root`), dark
  (`[data-theme="dark"]`) and the system-preference fallback — to import
  after `phoenix_paper.css`.
  """
  def css(seed, opts \\ []) do
    light = scheme(seed, :light, opts)
    dark = scheme(seed, :dark, opts)
    names = role_names()
    variant = Keyword.get(opts, :variant, :tonal_spot)

    decls = fn scheme, indent ->
      Enum.map_join(names, "\n", fn name -> "#{indent}--color-pp-#{name}: #{scheme[name]};" end)
    end

    """
    /*
     * PhoenixPaper theme — generated by `mix phoenix_paper.gen.theme`.
     * Seed #{String.downcase(seed)}, #{variant} scheme.
     *
     * Import it after phoenix_paper.css:
     *
     *   @import "../../deps/phoenix_paper/priv/static/phoenix_paper.css";
     *   @import "./phoenix_paper_theme.css";
     *
     * Regenerate rather than hand-editing, so light and dark stay paired.
     */

    :root {
    #{decls.(light, "  ")}
    }

    [data-theme="dark"] {
    #{decls.(dark, "  ")}
    }

    @media (prefers-color-scheme: dark) {
      :root:not([data-theme="light"]) {
    #{decls.(dark, "    ")}
      }
    }
    """
  end
end
