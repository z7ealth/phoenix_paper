defmodule Mix.Tasks.PhoenixPaper.Gen.Theme do
  @shortdoc "Generates an MD3 color theme for PhoenixPaper from a seed color"

  @moduledoc """
  Generates an MD3 color theme (every PhoenixPaper color role, light and
  dark) from a seed color, the way Material Theme Builder does.

      $ mix phoenix_paper.gen.theme --seed "#0b57d0"
      $ mix phoenix_paper.gen.theme --seed "#0b57d0" --scheme vibrant --tertiary "#a4407f"

  Writes `assets/css/phoenix_paper_theme.css` (see `--output`); import it
  after `phoenix_paper.css` in your `app.css`.

  ## Options

    * `--seed` (required) — the seed color, as hex.
    * `--scheme` — `tonal_spot` (default), `neutral`, `vibrant`,
      `expressive`, `fidelity` or `monochrome`. See `PhoenixPaper.Theme`.
    * `--secondary`, `--tertiary`, `--neutral`, `--error` — pin a core
      color: its hue and chroma replace that palette's.
    * `--no-status` — leave out the success/warning/info roles.
    * `--output` — the file to write (default
      `assets/css/phoenix_paper_theme.css`).
    * `--stdout` — print the CSS instead of writing a file.
    * `--force` — overwrite an existing file.
  """
  use Mix.Task

  @switches [
    seed: :string,
    scheme: :string,
    secondary: :string,
    tertiary: :string,
    neutral: :string,
    error: :string,
    status: :boolean,
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

    seed = opts[:seed] || Mix.raise("--seed is required, e.g. --seed \"#0b57d0\"")
    validate_hex!(seed, "--seed")

    for key <- [:secondary, :tertiary, :neutral, :error],
        hex = opts[key],
        do: validate_hex!(hex, "--#{key}")

    variant = parse_variant!(opts[:scheme] || "tonal_spot")

    css =
      PhoenixPaper.Theme.css(seed,
        variant: variant,
        secondary: opts[:secondary],
        tertiary: opts[:tertiary],
        neutral: opts[:neutral],
        error: opts[:error],
        status: Keyword.get(opts, :status, true)
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
