defmodule Mix.Tasks.Escript.New do
  use Mix.Task

  import Mix.Generator

  @switches [
    app: :string
  ]

  @impl Mix.Task
  def run(argv) do
    {opts, argv} = OptionParser.parse!(argv, strict: @switches)
    case argv do
      [] -> Mix.raise("Expected PATH to be given, please use \"mix escript.new PATH\"")

      [path | _] ->
        app = opts[:app] || Path.basename(Path.expand(path))

        unless path == "." do
          check_directory_existence!(path)
          File.mkdir_p!(path)
        end

        File.cd!(path, fn ->
          generate(app, path)
        end)
    end
  end

  defp generate(app, _path) do
    assigns = [
      app: app,
      main_module: Macro.camelize(app),
      project: Macro.camelize(app)
    ]
    create_file("mix.exs", mix_exs_template(assigns))
    create_file("lib/#{app}.ex", main_module_template(assigns))
  end

  defp check_directory_existence!(path) do
    msg = "The directory #{inspect(path)} already exists. Are you sure you want to continue?"

    if File.dir?(path) and not Mix.shell().yes?(msg) do
      Mix.raise("Please select another directory for installation")
    end
  end

  embed_template(:mix_exs, """
  defmodule <%= @project %>.MixProject do
    use Mix.Project

    def project do
      [
        app: :<%= @app %>,
        version: "0.1.0",
        deps: deps(),
        escript: [
          main_module: <%= @main_module %>
        ]
      ]
    end

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
