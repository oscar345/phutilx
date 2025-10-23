defmodule Phutilx.MixProject do
  use Mix.Project

  def project do
    [
      app: :phutilx,
      version: "0.1.7",
      elixir: "~> 1.18",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      authors: ["Oscar Zwagers"],
      package: [
        name: :phutilx,
        licenses: ["MIT"],
        links: %{"GitHub" => "https://github.com/oscar345/phutilx"}
      ],
      docs: docs(),
      source_url: "https://github.com/oscar345/phutilx",
      description: "A collection of utilities and helpers for Phoenix and Elixir projects."
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger]
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:phoenix, "~> 1.8"},
      {:ecto, "~> 3.13"},
      {:inertia, "~> 2.5.0"},
      {:gettext, "~> 0.26"},
      {:ex_doc, ">= 0.0.0", only: :dev, runtime: false},
      {:phoenix_live_view, "~> 1.1"}
      # {:dep_from_hexpm, "~> 0.3.0"},
      # {:dep_from_git, git: "https://github.com/elixir-lang/my_dep.git", tag: "0.1.0"}
    ]
  end

  defp docs do
    [
      main: "readme",
      extras: [
        "README.md"
      ]
    ]
  end
end
