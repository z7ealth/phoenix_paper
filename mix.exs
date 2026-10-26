defmodule PhoenixPaper.MixProject do
  use Mix.Project

  @version "0.5.4"
  @source_url "https://github.com/z7ealth/phoenix_paper"
  @website_url "https://phoenixpaper.dev"
  @description "Material Design 3 (including M3 Expressive) components for Phoenix and LiveView, styled with Tailwind CSS."

  def project do
    [
      app: :phoenix_paper,
      version: @version,
      elixir: "~> 1.18",
      start_permanent: Mix.env() == :prod,
      elixirc_paths: elixirc_paths(Mix.env()),
      deps: deps(),
      description: @description,
      package: package(),
      docs: docs(),
      name: "PhoenixPaper",
      source_url: @source_url,
      homepage_url: @website_url
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger]
    ]
  end

  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(_), do: ["lib"]

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:phoenix_live_view, "~> 1.1"},
      # `phoenix_live_view` only lists `jason` as an *optional* dependency,
      # but `Phoenix.LiveView.JS.to_iodata/1` needs it at runtime to encode
      # its command payloads — used by `Tabs`/`Dialog`. This library used
      # to get `jason` for free transitively through `tails` (which
      # required it); now that `tails` is gone, it needs to be a direct
      # dependency here or those components break at render time in any
      # consuming app that doesn't happen to pull `jason` in some other way.
      {:jason, "~> 1.4"},
      {:ex_doc, "~> 0.38", only: :dev, runtime: false},
      # `Phoenix.LiveViewTest.live_isolated/3` (the date/time picker event tests)
      # needs it to parse rendered HTML. Test-only: not shipped to consumers.
      {:lazy_html, ">= 0.1.0", only: :test}
    ]
  end

  defp package do
    [
      licenses: ["MIT"],
      maintainers: ["Héctor Salinas"],
      links: %{
        "Website" => @website_url,
        "GitHub" => @source_url,
        "Changelog" => @source_url <> "/blob/master/CHANGELOG.md"
      },
      files:
        ~w(lib priv .formatter.exs mix.exs package.json README.md LICENSE CHANGELOG.md AGENTS.md)
    ]
  end

  defp docs do
    [
      main: "readme",
      source_ref: "v#{@version}",
      source_url: @source_url,
      extras: [
        "README.md",
        {"Live demo", url: @website_url},
        {"Components", url: @website_url <> "/components"},
        {"Theme creator", url: @website_url <> "/theme-creator"},
        "CHANGELOG.md",
        "AGENTS.md",
        "LICENSE"
      ]
    ]
  end
end
