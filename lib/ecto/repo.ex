defmodule Phutilx.Ecto.Repo do
  import Ecto.Query, only: [limit: 2, offset: 2]

  @spec paginate(Ecto.Repo.t(), Ecto.Query.t(), %{page: integer(), size: integer()}) ::
          Phutilx.Ecto.Paginate.t()

  def paginate(repo, query, %{page: page, size: size}) do
    values =
      query
      |> limit(^size)
      |> offset((^page - 1) * ^size)
      |> repo.all()

    count = query |> repo.aggregate(:count, :id)

    %Phutilx.Ecto.Paginate{
      values: values,
      page: page,
      size: size,
      count: count
    }
  end
end
