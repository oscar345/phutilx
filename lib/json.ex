defmodule Phutilx.JSON do
  @doc """
  ## Options
  Makes it possible to encode Ecto schemas and other structs to JSON. Since Ecto schemas can sometimes be
  difficult to encode, with associations that are not loaded. This macro ejects any fields that are not
  loaded, as well as the `:__struct__` and `:__meta__` fields and any fields specified in the `:except` option.

    * `:only` - A list of fields to include in the JSON output. If this option is provided, only the
      specified fields will be included.
    * `:except` - A list of fields to exclude from the JSON output. This option is ignored if `:only`
      is provided. `:__struct__` and `:__meta__` are always excluded.
  """
  defmacro encoder(opts \\ []) do
    quote do
      defimpl JSON.Encoder do
        def encode(struct, opts) do
          only = Keyword.get(unquote(opts), :only)
          drop = Keyword.get(unquote(opts), :except, []) ++ [:__struct__, :__meta__]

          struct =
            if only != nil do
              Map.take(struct, only)
            else
              Map.drop(struct, drop)
            end

          struct
          |> Map.reject(fn {_k, v} -> match?(%Ecto.Association.NotLoaded{}, v) end)
          |> JSON.encode!()
        end
      end
    end
  end

  defimpl JSON.Encoder, for: Tuple do
    def encode(tuple, _) do
      tuple
      |> Tuple.to_list()
      |> JSON.encode!()
    end
  end
end
