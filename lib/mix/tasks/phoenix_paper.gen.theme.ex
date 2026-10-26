defmodule Mix.Tasks.PhoenixPaper.Gen.Theme do
  @shortdoc "Generates an MD3 color theme for PhoenixPaper from a seed color"

  @moduledoc """
  Generates an MD3 color theme (every PhoenixPaper color role, light and
  dark) from a seed color, the way Material Theme Builder does, and/or
  from explicit role values in a palette file.

      $ mix phoenix_paper.gen.theme --seed "#0b57d0"
      $ mix phoenix_paper.gen.theme --seed "#0b57d0" --scheme vibrant --tertiary "#a4407f"
      $ mix phoenix_paper.gen.theme --palette catppuccin.json
      $ mix phoenix_paper.gen.theme --seed "#8839ef" --palette brand.json

  Writes `assets/css/phoenix_paper_theme.css` (see `--output`); import it
  after `phoenix_paper.css` in your `app.css`.

  ## Options

    * `--seed` — the seed color, as hex. Required unless `--palette`
      gives every role for both light and dark.
    * `--palette` — a JSON file of explicit role values, which replace the
      generated ones:

          {
            "light": {"primary": "#8839ef", "on-primary": "#eff1f5", ...},
            "dark":  {"primary": "#cba6f7", "on-primary": "#1e1e2e", ...}
          }

      Keys are PhoenixPaper's role names (`primary`, `surface-container-high`,
      ..., see `PhoenixPaper.Theme.role_names/0`; a `--color-pp-` prefix is
      accepted). Give a role in both modes or the seed fills the other.
      The dark values are written to both the `[data-theme="dark"]` block
      and the `prefers-color-scheme` block, so you write them once.
    * `--scheme` — `tonal_spot` (default), `neutral`, `vibrant`,
      `expressive`, `fidelity` or `monochrome`. See `PhoenixPaper.Theme`.
    * `--secondary`, `--tertiary`, `--neutral`, `--error` — pin a core
      color: its hue and chroma replace that palette's.
    * `--output` — the file to write (default
      `assets/css/phoenix_paper_theme.css`).
    * `--stdout` — print the CSS instead of writing a file.
    * `--force` — overwrite an existing file.
  """
  use Mix.Task

  @switches [
    seed: :string,
    palette: :string,
    scheme: :string,
    secondary: :string,
    tertiary: :string,
    neutral: :string,
    error: :string,
    output: :string,
    stdout: :boolean,
    force: :boolean
  ]

  @impl true
  def run(argv) do
    {opts, _args, invalid} = OptionParser.parse(argv, strict: @switches)

    if invalid != [] do
      Mix.raise("Invalid options: #{inspect(invalid)}")
    end

    overrides = if path = opts[:palette], do: read_palette!(path), else: %{}
    seed = opts[:seed]

    if seed do
      validate_hex!(seed, "--seed")
    else
      if overrides == %{} do
        Mix.raise("--seed is required, e.g. --seed \"#0b57d0\" (or pass a complete --palette)")
      end
    end

    for key <- [:secondary, :tertiary, :neutral, :error],
        hex = opts[key],
        do: validate_hex!(hex, "--#{key}")

    variant = parse_variant!(opts[:scheme] || "tonal_spot")

    css =
      theme_css!(seed,
        variant: variant,
        secondary: opts[:secondary],
        tertiary: opts[:tertiary],
        neutral: opts[:neutral],
        error: opts[:error],
        overrides: overrides
      )

    if opts[:stdout] do
      Mix.shell().info(css)
    else
      path = opts[:output] || "assets/css/phoenix_paper_theme.css"

      if File.exists?(path) and !opts[:force] do
        Mix.raise("#{path} already exists. Pass --force to overwrite it.")
      end

      File.mkdir_p!(Path.dirname(path))
      File.write!(path, css)

      Mix.shell().info("""
      * creating #{path}

      Import it after phoenix_paper.css in your app.css:

          @import "./#{Path.basename(path)}";
      """)
    end
  end

  defp theme_css!(seed, opts) do
    PhoenixPaper.Theme.css(seed, opts)
  rescue
    e in ArgumentError ->
      Mix.raise("--palette is incomplete without --seed: #{Exception.message(e)}")
  end

  defp read_palette!(path) do
    data =
      case File.read(path) do
        {:ok, body} ->
          body

        {:error, reason} ->
          Mix.raise("Can't read --palette #{path}: #{:file.format_error(reason)}")
      end

    case Jason.decode(data) do
      {:ok, %{} = map} ->
        try do
          PhoenixPaper.Theme.normalize_overrides(map)
        rescue
          e in ArgumentError -> Mix.raise("--palette #{path}: #{Exception.message(e)}")
        end

      {:ok, _} ->
        Mix.raise("--palette #{path} must be a JSON object with light and/or dark keys")

      {:error, e} ->
        Mix.raise("--palette #{path} isn't valid JSON: #{Exception.message(e)}")
    end
  end

  defp validate_hex!(hex, flag) do
    PhoenixPaper.Theme.Hct.parse_hex(hex)
  rescue
    _ -> Mix.raise("#{flag} must be a hex color like \"#0b57d0\", got #{inspect(hex)}")
  end

  defp parse_variant!(name) do
    variant = Enum.find(PhoenixPaper.Theme.variants(), &(Atom.to_string(&1) == name))

    variant ||
      Mix.raise(
        "--scheme must be one of #{Enum.map_join(PhoenixPaper.Theme.variants(), ", ", &Atom.to_string/1)}"
      )
  end
end
