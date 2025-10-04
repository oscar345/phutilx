defmodule Phutilx.Database.Paginate do
  defstruct values: nil, page: 1, size: 10, count: 0

  @type t :: %__MODULE__{
          values: list(),
          page: integer(),
          size: integer(),
          count: integer()
        }

  @moduledoc """
  Helps with creating filters on resources in the database by creating a helper macros and function and by
  consuming the module with use, it will also import the ecto modules needed to create filter schemas and
  importing ecto query functions.
  """
  alias Ecto.Changeset
  import Ecto.Query

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

  @doc """
  A small helper function which converts a changeset into a schema or a changeset error by using the
  `apply_action/2` function. The action is set to `:query`. When there are no errors the function passed
  into the `fun_ok` parameter is called with the schema as argument. When there are errors the function
  passed into the `fun_error` parameter is called with the error tuple as argument. The `fun_error`
  parameter defaults to an identity function.
  """
  def apply_query(changeset, fun_ok, fun_error \\ fn result -> result end) do
    case Changeset.apply_action(changeset, :query) do
      {:ok, params} -> fun_ok.(params)
      {:error, _changeset} = error -> fun_error.(error)
    end
  end

  defmacro __using__(_opts) do
    quote do
      import Phutilx.Database.Paginate
      use Ecto.Schema
      import Ecto.Changeset
      import Ecto.Query

      Module.register_attribute(__MODULE__, :pagination_options, accumulate: false)

      @before_compile Phutilx.Database.Paginate
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

  def paginate(repo, query, %{page: page, size: size}) do
    values =
      query
      |> limit(^size)
      |> offset((^page - 1) * ^size)
      |> repo.all()

    count = query |> repo.aggregate(:count, :id)

    %__MODULE__{
      values: values,
      page: page,
      size: size,
      count: count
    }
  end
end
