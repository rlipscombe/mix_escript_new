defmodule Mix.Tasks.Escript.New do
  use Mix.Task

  import Mix.Generator

  @shortdoc "Creates a new Elixir escript project"

  @moduledoc """
  Creates a new Elixir escript project.
  It expects the path of the project as argument.

      mix escript.new PATH [--app APP] [--noinput]

  A project at the given PATH will be created. The
  application name will be generated from the path,
  unless `--app` is given.

  A `--noinput` option can be given to add "-noinput"
  to the emulator flags.
  """

  @switches [
    app: :string,
    noinput: :boolean
  ]

  @impl Mix.Task
  def run(argv) do
    {opts, argv} = OptionParser.parse!(argv, strict: @switches)
    case argv do
      [] -> Mix.raise("Expected PATH to be given, please use \"mix escript.new PATH\"")

      [path | _] ->
        app = opts[:app] || Path.basename(Path.expand(path))
        script = Path.basename(Path.expand(path))
        check_application_name!(app, !opts[:app])
        noinput = opts[:noinput]

        unless path == "." do
          check_directory_existence!(path)
          File.mkdir_p!(path)
        end

        File.cd!(path, fn ->
          generate(script, app, noinput)
        end)
    end
  end

  defp check_application_name!(name, inferred?) do
    unless name =~ ~r/^[a-z][a-z0-9_]*$/ do
      Mix.raise(
        "Application name must start with a lowercase ASCII letter, followed by " <>
          "lowercase ASCII letters, numbers, or underscores, got: #{inspect(name)}" <>
          if inferred? do
            ". The application name is inferred from the path, if you'd like to " <>
              "explicitly name the application then use the \"--app APP\" option"
          else
            ""
          end
      )
    end
  end

  defp generate(script, app, noinput) do
    assigns = [
      app: app,
      project: Macro.camelize(app),
      main_module: Macro.camelize(app),
      path: script,
      noinput: noinput
    ]
    create_file(".gitignore", gitignore_template(assigns))
    create_file("README.md", readme_template(assigns))
    create_file("mix.exs", mix_exs_template(assigns))
    create_file("lib/#{app}.ex", main_module_template(assigns))
  end

  defp check_directory_existence!(path) do
    msg = "The directory #{inspect(path)} already exists. Are you sure you want to continue?"

    if File.dir?(path) and not Mix.shell().yes?(msg) do
      Mix.raise("Please select another directory for installation")
    end
  end

  embed_template(:gitignore, """
  <%= @path %>
  _build/
  deps/
  .elixir_ls/
  """)

  embed_template(:readme, """
  # <%= @project %>

  ## Building

      mix escript.build
  """)

  embed_template(:mix_exs, """
  defmodule <%= @project %>.MixProject do
    use Mix.Project

    def project do
      [
        app: :<%= @app %>,
        version: "0.1.0",
        deps: deps(),
        default_task: "escript.build",
        escript: escript_options()
      ]
    end
    <%= if @noinput do %>
    defp escript_options do
      [
        main_module: <%= @main_module %>,
        path: "<%= @path %>",
        emu_args: "--erl -noinput"
      ]
    end
    <% else %>
    defp escript_options do
      [
        main_module: <%= @main_module %>,
        path: "<%= @path %>"
      ]
    end
    <% end %>
    defp deps do
      [
        # {:dep_from_hexpm, "~> 0.3.0"},
        # {:dep_from_git, git: "https://github.com/elixir-lang/my_dep.git", tag: "0.1.0"}
      ]
    end
  end
  """)

  embed_template(:main_module, """
  defmodule <%= @main_module %> do
    def main(_args) do
      IO.puts("Hello World!")
    end
  end
  """)
end
