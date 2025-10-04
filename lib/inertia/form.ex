defmodule Phutilx.Inertia.Form do
  defstruct key: nil, changeset: nil, map: nil

  @type t :: %__MODULE__{
          key: atom() | nil,
          changeset: Ecto.Changeset.t() | nil,
          map: map() | nil
        }

  def from_changeset(%Ecto.Changeset{} = changeset, key \\ nil) do
    %__MODULE__{key: key, changeset: changeset}
  end

  def from_map(map, key \\ nil) when is_map(map) do
    %__MODULE__{key: key, map: map}
  end

  defimpl Inertia.Errors do
    alias Ecto.Changeset

    @gettext_module Application.compile_env(:phutilx, :gettext_module)

    def to_errors(%Phutilx.Inertia.Form{changeset: %Changeset{} = changeset} = value, fun) do
      errors =
        if fun != nil do
          Inertia.Errors.to_errors(changeset, fun)
        else
          Inertia.Errors.to_errors(changeset)
        end

      if value.key == nil do
        errors
      else
        # Prefix the keys with the form's key
        errors |> Enum.map(fn {k, v} -> {"#{value.key}.#{k}", v} end) |> Map.new()
      end
    end

    def to_errors(%Phutilx.Inertia.Form{changeset: %Changeset{}} = value) do
      to_errors(value, fn {msg, opts} ->
        if count = opts[:count] do
          Gettext.dngettext(@gettext_module, "errors", msg, msg, count, opts)
        else
          Gettext.dgettext(@gettext_module, "errors", msg, opts)
        end
      end)
    end

    def to_errors(%Phutilx.Inertia.Form{map: %{} = map} = value) do
      errors = flatten_map(map)

      if value.key == nil do
        errors
      else
        # Prefix the keys with the form's key
        errors |> Enum.map(fn {k, v} -> {"#{value.key}.#{k}", v} end) |> Map.new()
      end
    end

    defp flatten_map(map, parent_key \\ nil, acc \\ %{}) do
      Enum.reduce(map, acc, fn {k, v}, acc ->
        key = if parent_key, do: "#{parent_key}.#{k}", else: to_string(k)

        if is_map(v) do
          flatten_map(v, key, acc)
        else
          Map.put(acc, key, v)
        end
      end)
    end
  end
end
