defmodule Backdoor.MixProject do
  use Mix.Project

  @version "0.0.1"

  def project do
    [
      app: :backdoor,
      version: @version,
      elixir: "~> 1.7",
      compilers: [:phoenix] ++ Mix.compilers(),
      elixirc_paths: elixirc_paths(Mix.env()),
      deps: deps(),
      package: package(),
      name: "Backdoor",
      docs: docs(),
      homepage_url: "https://www.amberbit.com",
      description: "Web IEx console for Phoenix applications.",
      aliases: aliases()
    ]
  end

  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(_), do: ["lib"]

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      mod: {Backdoor.Application, []},
      extra_applications: [:logger]
    ]
  end

  defp aliases do
    [
      setup: ["deps.get", "cmd npm install --prefix assets"],
      dev: "run --no-halt dev.exs"
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:phoenix_live_view, "~> 0.14"},
      {:phoenix_html, "~> 2.14.1 or ~> 2.15"},
      {:phoenix_live_reload, "~> 1.2", only: :dev},
      {:plug_cowboy, "~> 2.0", only: :dev},
      {:jason, "~> 1.0", only: [:dev, :test, :docs]},
      {:floki, "~> 0.27.0", only: :test},
      {:ex_doc, "~> 0.21", only: :docs},
      {:stream_data, "~> 0.1", only: :test}
    ]
  end

  defp docs do
    [
      main: "Backdoor",
      source_ref: "v#{@version}",
      source_url: "https://github.com/amberbit/backdoor",
      extra_section: "GUIDES",
      extras: extras(),
      nest_modules_by_prefix: [Backdoor]
    ]
  end

  defp extras do
    []
  end

  defp package do
    [
      maintainers: ["Hubert Łępicki"],
      licenses: ["MIT"],
      links: %{github: "https://github.com/amberbit/backdoor"},
      files: ~w(lib priv CHANGELOG.md LICENSE.md mix.exs README.md)
    ]
  end
end
