defmodule Mix.Tasks.Phx.Gen.Routes do
  use Mix.Task

  @shortdoc "Generate routes in JavaScript based on Phoenix routes"

  @requirements [
    "app.start"
  ]

  def run(args) do
    if rem(length(args), 2) != 0 do
      Mix.raise("Invalid number of arguments")
    end

    args =
      args
      |> Enum.chunk_every(2)
      |> Enum.map(fn [name, value] -> {String.trim_leading(name, "-"), value} end)
      |> Enum.into(%{})

    keys = Map.keys(args)

    if "path" not in keys do
      Mix.raise("Missing required argument: path")
    end

    if "router" not in keys do
      Mix.raise("Missing required argument: router")
    end

    path = Map.get(args, "path")

    Mix.Shell.IO.yes?("This will overwrite all files in #{path}, are you sure?") ||
      Mix.raise("Aborted")

    File.rm_rf(path)

    router = ("Elixir." <> Map.get(args, "router")) |> String.to_atom()

    Phoenix.Router.routes(router)
    |> Stream.filter(fn %{plug_opts: opts} -> is_atom(opts) end)
    |> Stream.map(fn route -> route_add_path_params(route) end)
    |> Stream.map(fn route -> route_add_filename(route) end)
    |> Stream.map(fn route -> route_add_function_name(route) end)
    |> Stream.map(fn route -> Map.put(route, :function, route_to_function(route)) end)
    |> Enum.to_list()
    |> Enum.group_by(fn %{filename: filename} -> filename end)
    |> Enum.map(fn {filename, group} -> {filename, group_to_file_content(group)} end)
    |> IO.inspect()
    |> Enum.each(fn {filename, content} -> write_file(path, filename, content) end)
  end

  defp write_file(path, filename, content) do
    path = Path.join(path, filename)
    path |> Path.dirname() |> File.mkdir_p()
    File.write(path, content)
  end

  defp route_add_path_params(%{path: path} = route) do
    Map.put_new(route, :path_params, Plug.Router.Utils.build_path_match(path))
  end

  defp route_add_filename(%{plug: plug} = route) do
    Map.put_new(route, :filename, Phoenix.Naming.underscore(plug) <> ".ts")
  end

  defp route_to_function(route) do
    function_name = route |> Map.get(:function_name)
    path = route |> Map.get(:path)
    method = route |> Map.get(:verb)

    params_type =
      route
      |> Map.get(:path_params)
      |> then(fn {names, _} -> names end)
      |> Enum.map(fn name -> "#{name}?: string | number" end)
      |> then(fn names -> ["query?: string" | names] end)
      |> Enum.join(", ")
      |> then(fn names -> "{#{names}}" end)

    """
    export function #{function_name}(params: #{params_type} = {}): URLMethod {
      let path = "#{path}";

      Object.keys(params).forEach(key => {
        path = path.replace(`:${key}`, params[key]);
      });

      if (params.query) {
        path += `${params.query}`;
      }

      return {
        url: path,
        method: "#{method}"
      };
    }
    """
  end

  defp group_to_file_content(group) do
    content =
      group
      |> Enum.uniq_by(fn %{function_name: name} -> name end)
      |> Enum.map(fn %{function: function} -> function end)
      |> Enum.join("\n\n")

    """
    import { type Method } from "@inertiajs/core";

    type URLMethod = {
      url: string;
      method: Method;
    };

    #{content}
    """
  end

  defp route_add_function_name(route) do
    function_name = route |> Map.get(:plug_opts) |> Atom.to_string()

    function_name =
      case function_name do
        "delete" -> "delete_"
        "import" -> "import_"
        "new" -> "new_"
        "confirm" -> "confirm_"
        _ -> function_name
      end

    Map.put(route, :function_name, function_name)
  end
end
