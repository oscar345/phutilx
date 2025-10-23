defmodule Phutilx.Ecto.Repo do
  import Ecto.Query, only: [limit: 2, offset: 2]

  @spec paginate(Ecto.Repo.t(), Ecto.Query.t(), %{page: integer(), size: integer()}) ::
          Phutilx.Ecto.Paginate.t()

  def paginate(repo, query, %{page: page, size: size}) do
    items =
      query
      |> limit(^size)
      |> offset((^page - 1) * ^size)
      |> repo.all()

    count = query |> repo.aggregate(:count, :id)

    %Phutilx.Ecto.Paginate{
      items: items,
      page: page,
      size: size,
      total: count
    }
  end
end
