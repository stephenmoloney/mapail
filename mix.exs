defmodule Mapail.Mixfile do
  use Mix.Project
  @elixir_versions "~> 1.2 or ~> 1.3 or ~> 1.4 or ~> 1.5"
  @version "0.2.1"
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
    description: description(),
    package: package(),
    deps: deps(),
    docs: docs()
    ]
  end



  def application() do
    [applications: [:logger, :maptu]]
  end

  defp deps() do
    [
      {:maptu, "~> 1.0"},
      {:earmark, ">= 0.0.0", only: :dev},
      {:ex_doc, ">= 0.0.0", only: :dev}
    ]
  end

  defp description() do
    ~s"""
    Convert maps with string keys to an elixir struct with Mapail.
    """
  end

  defp package() do
    %{
      licenses: ["MIT"],
      maintainers: @maintainers,
      links: %{ "GitHub" => @source_url},
      files: ~w(lib mix.exs README* LICENSE* CHANGELOG*)
     }
  end

  defp docs() do
    [main: "api-reference"]
  end

end
