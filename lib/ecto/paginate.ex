defmodule Phutilx.Ecto.Paginate do
  defstruct items: nil, page: 1, size: 10, total: 0

  @type t :: %__MODULE__{
          items: list(),
          page: integer(),
          size: integer(),
          total: integer()
        }

  @moduledoc """
  Helps with creating filters on resources in the database by creating a helper macros and function and by
  consuming the module with use, it will also import the ecto modules needed to create filter schemas and
  importing ecto query functions.
  """

  @doc """
  A pagination macro that adds the fields `:size` and `:page` to the embedded schema. The default
  values for these fields can be configured via options.

  ## Options

    * `:default_page` - The default page number (default: `1`)
    * `:default_size` - The default page size (default: `25`)
    * `:max_size` - The maximum page size allowed (default: `100`)
  """
  defmacro paginate(opts \\ []) do
    default_page = Keyword.get(opts, :default_page, 1)
    default_size = Keyword.get(opts, :default_size, 25)
    max_size = Keyword.get(opts, :max_size, 100)

    quote do
      field(:page, :integer, default: unquote(default_page))
      field(:size, :integer, default: unquote(default_size))

      @pagination_options %{
        page: unquote(default_page),
        size: unquote(default_size),
        max_size: unquote(max_size)
      }
    end
  end

  defmacro __using__(_opts) do
    quote do
      import Phutilx.Ecto.Paginate
      use Ecto.Schema
      import Ecto.Changeset
      import Ecto.Query

      Module.register_attribute(__MODULE__, :pagination_options, accumulate: false)

      @before_compile Phutilx.Ecto.Paginate
    end
  end

  defmacro __before_compile__(_env) do
    quote do
      @doc """
      Validates the pagination fields `:page` and `:size` in the given changeset. The function uses the
      pagination options defined in the module attribute `@pagination_options` to validate the fields.

      You do not need to pass the `:page` and `:size` fields to the changeset, they are extracted from the `attrs`,
      so you also do not have to pass them to the `cast/3` function in your changeset function.

      ## Examples

          iex> validate_pagination(%Ecto.Changeset{}, %{"page" => 2, "size" => 50})
          #Ecto.Changeset<...>

          iex> validate_pagination(%Ecto.Changeset{}, %{"page" => 0, "size" => 150})
          #Ecto.Changeset<...>
      """
      def validate_pagination(changeset, attrs) do
        %__MODULE__{}
        |> cast(attrs, [:page, :size])
        |> validate_number(:page, greater_than: 0)
        |> validate_number(:size,
          greater_than: 0,
          less_than_or_equal_to: @pagination_options[:max_size]
        )
        |> merge(changeset)
      end
    end
  end

  @doc """
  Updates the `:values` field of the given pagination struct using the provided update function.

  ## Examples

      iex> pagination = %Phutilx.Ecto.Paginate{values: [1, 2, 3], page: 1, size: 3, total: 3}
      iex> Phutilx.Ecto.Paginate.update_items(pagination, fn items -> Enum.map(items, &(&1 * 2)) end)
      %Phutilx.Ecto.Paginate{items: [2, 4, 6], page: 1, size: 3, total: 3}
  """
  def update_items(%__MODULE__{} = pagination, update_fn) do
    update_in(pagination, [Access.key!(:items)], update_fn)
  end
end
