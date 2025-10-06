defmodule Mix.Tasks.Ecto.Gen.Schemas do
  use Mix.Task

  @requirements ["app.start"]

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

    path = Map.get(args, "path")

    Mix.Shell.IO.yes?("This will delete and overwrite all files in #{path}. Are you sure?") ||
      Mix.raise("Aborted")

    File.rm_rf(path)

    app = Mix.Project.config()[:app]
    {:ok, modules} = :application.get_key(app, :modules)
    app_module = app |> Atom.to_string() |> Macro.camelize()

    schemas =
      modules
      |> Enum.filter(fn mod ->
        String.starts_with?(Atom.to_string(mod), "Elixir." <> app_module)
      end)
      |> Enum.filter(fn mod -> is_schema_module?(mod) end)
      |> Enum.map(fn mod -> get_types_schema(mod) end)

    schema_associations =
      schemas
      |> Enum.map(fn %{module: mod, associations: assocs} ->
        for assoc <- assocs do
          {mod, assoc}
        end
      end)
      |> List.flatten()
      |> Enum.uniq()

    schema_direct_associations =
      schema_associations
      |> Enum.reject(fn {_mod, {_, assoc}} ->
        is_struct(assoc, Ecto.Association.HasThrough)
      end)
      |> Enum.map(fn {mod, {assoc_name, assoc}} ->
        {{mod, assoc_name}, {assoc.related, assoc.cardinality}}
      end)
      |> Map.new()
      |> IO.inspect()

    schema_indirect_associations =
      schema_associations
      |> Enum.filter(fn {_mod, {_, assoc}} ->
        is_struct(assoc, Ecto.Association.HasThrough)
      end)
      |> Enum.map(fn {mod, {assoc_name, assoc}} ->
        {related, _} =
          cycle_through(schema_direct_associations, mod, assoc.through) |> IO.inspect()

        {{mod, assoc_name}, {related, :many}}
      end)
      |> Map.new()

    all_schema_associations =
      Map.merge(schema_direct_associations, schema_indirect_associations)
      |> Enum.map(fn {{mod, assoc_name}, {related, cardinality}} ->
        {mod, {assoc_name, related, cardinality}}
      end)
      |> Enum.group_by(fn {mod, _} -> mod end, fn {_, assoc} -> assoc end)
      |> Map.new()
      |> IO.inspect()

    schemas
    |> Enum.map(fn %{module: mod, fields: fields} ->
      assoc =
        Map.get(all_schema_associations, mod, %{})
        |> Enum.map(fn {name, rel, card} -> {name, {rel, card}} end)
        |> Map.new()

      fields = Enum.map(fields, &to_typescript(:field, &1, app_module))
      assoc = Enum.map(assoc, &to_typescript(:association, &1, app_module))

      {types, imports} =
        (fields ++ assoc)
        |> Enum.map(fn %{line: line, import: import} -> {line, import} end)
        |> Enum.unzip()

      %{
        types: types,
        imports: imports,
        filename: mod_to_filename(mod, app_module),
        type_name: mod_to_type_name(mod),
        mod: mod
      }
    end)
    |> Enum.group_by(fn %{filename: filename} -> filename end, fn item -> item end)
    |> Enum.each(fn {filename, items} ->
      mod = items |> List.first() |> Map.get(:mod)

      import =
        items
        |> Enum.map(fn %{imports: imports} -> imports end)
        |> List.flatten()
        |> Enum.uniq()
        |> Enum.reject(fn import -> import == "" end)
        |> Enum.reject(fn import ->
          String.contains?(import, mod_to_import(mod, app_module))
        end)
        |> Enum.join("\n")

      types =
        for %{types: items, type_name: type_name} <- items do
          """
          export type #{type_name} = {
            #{items |> Enum.join("\n  ")}
          }
          """
        end

      types = Enum.join(types, "\n\n")

      content = """
      #{import}

      #{types}
      """

      full_path = Path.join(path, filename)
      dir = Path.dirname(full_path)
      File.mkdir_p!(dir)
      File.write!(full_path, content)
    end)
  end

  def mod_to_filename(mod, app_module) do
    [_ | path] =
      mod
      |> Atom.to_string()
      |> String.replace("Elixir." <> app_module, "")
      |> String.split(".")
      |> Enum.reverse()

    path = path |> Enum.reverse() |> Enum.map(&Macro.underscore/1) |> Path.join()

    path <> ".ts"
  end

  def mod_to_type_name(mod) do
    mod
    |> Atom.to_string()
    |> String.split(".")
    |> List.last()
    |> Macro.camelize()
  end

  def mod_to_import(mod, app_module) do
    "$schemas/#{mod_to_filename(mod, app_module) |> String.replace(".ts", "")}"
  end

  def cycle_through(schema_direct_associations, mod, [first | through]) do
    case through do
      [] ->
        Map.get(schema_direct_associations, {mod, first})

      [next | rest] ->
        {next_mod, _} = Map.get(schema_direct_associations, {mod, first})
        cycle_through(schema_direct_associations, next_mod, [next | rest])
    end
  end

  defp get_types_schema(mod) do
    fields = mod.__schema__(:fields)
    fields_and_types = for field <- fields, into: %{}, do: {field, mod.__schema__(:type, field)}
    associations = mod.__schema__(:associations)

    associations_and_types =
      for assoc <- associations, into: %{} do
        {assoc, mod.__schema__(:association, assoc)}
      end

    embeds = mod.__schema__(:embeds)
    embeds_and_types = for embed <- embeds, into: %{}, do: {embed, mod.__schema__(:embed, embed)}

    %{
      module: mod,
      fields: fields_and_types,
      associations: associations_and_types,
      embeds: embeds_and_types
    }
  end

  defp is_schema_module?(module) do
    Code.ensure_loaded?(module) and function_exported?(module, :__schema__, 1)
  end

  def to_typescript(:field, {key, type}, _app_module) do
    %{line: "#{key}: #{type_to_typescript(type)};", import: ""}
  end

  def to_typescript(:association, {key, {mod, card}}, app_module) do
    type_name = mod_to_type_name(mod)

    ts_type =
      case card do
        :one -> type_name <> " | null"
        :many -> type_name <> "[]"
      end

    %{
      line: "#{key}: #{ts_type};",
      import: "import { type #{type_name} } from '#{mod_to_import(mod, app_module)}';"
    }
  end

  def type_to_typescript(:id), do: "number"
  def type_to_typescript(:integer), do: "number"
  def type_to_typescript(:float), do: "number"
  def type_to_typescript(:boolean), do: "boolean"
  def type_to_typescript(:string), do: "string"
  def type_to_typescript(:utc_datetime), do: "string"
  def type_to_typescript(:naive_datetime), do: "string"
  def type_to_typescript(:binary_id), do: "string"
  def type_to_typescript(:binary), do: "string"
  def type_to_typescript(:map), do: "Record<string, any>"
  def type_to_typescript({:array, inner_type}), do: type_to_typescript(inner_type) <> "[]"

  def type_to_typescript({:map, inner_type}),
    do: "Record<string, #{type_to_typescript(inner_type)}>"

  def type_to_typescript({:parameterized, {Ecto.Enum, %{mappings: mappings}}}) do
    mappings |> Keyword.values() |> Enum.map(fn item -> "'#{item}'" end) |> Enum.join(" | ")
  end

  def type_to_typescript(_), do: "any"
end
