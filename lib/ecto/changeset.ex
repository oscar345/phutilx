defmodule Phutilx.Ecto.Changeset do
  defmacro __using__(_opts) do
    quote do
      import Ecto.Changeset
      import Phutilx.Ecto.Changeset, only: [__before_compile__: 1]

      @before_compile Phutilx.Ecto.Changeset
    end
  end

  defmacro __before_compile__(_env) do
    quote do
      def validate(attrs) do
        %__MODULE__{}
        |> changeset(attrs)
        |> apply_action(:validate)
      end
    end
  end
end
