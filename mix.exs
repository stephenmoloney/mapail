defmodule Mapail.Mixfile do
  use Mix.Project
  @elixir_versions "~> 1.3 or ~> 1.4 or ~> 1.5"
  @version "1.0.2"
  @source_url "https://github.com/stephenmoloney/mapail"
  @maintainers ["Stephen Moloney"]

  def project do
    [
    app: :mapail,
    name: "Mapail",
    version: @version,
    source_url: @source_url,
    elixir: @elixir_versions,
    build_embedded: Mix.env == :prod,
    start_permanent: Mix.env == :prod,
    elixirc_paths: elixirc_paths(Mix.env),
    description: description(),
    package: package(),
    deps: deps(),
    docs: docs()
    ]
  end



  def application() do
    [
      applications: [:maptu]
    ]
  end

  defp deps() do
    [
      {:maptu, "~> 1.0.0"},
      {:earmark, ">= 0.0.0", only: :dev},
      {:ex_doc, ">= 0.0.0", only: :dev}
    ]
  end

  defp description() do
    ~s"""
    Helper library to convert a map into a struct or a struct to a struct.
    """
  end

  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(_),     do: ["lib"]


  defp package() do
    %{
      licenses: ["MIT"],
      maintainers: @maintainers,
      links: %{ "GitHub" => @source_url},
      files: ~w(lib mix.exs README* LICENSE* CHANGELOG*)
     }
  end

  defp docs() do
    [
      main: "Mapail"
    ]
  end

end
