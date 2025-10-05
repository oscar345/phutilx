defmodule Phutilx.Inertia.Controller do
  alias Plug.Conn

  @doc """
  Assign a title to both the normal assigns from plug and to the inertia prop assigns so the title
  can be used on the server and on the client.
  """
  def assign_title(conn, title) do
    conn
    |> Conn.assign(:page_title, title)
    |> Inertia.Controller.assign_prop(:page_title, title)
  end

  @doc """
  Assign metadata to both the normal assigns from plug and to the inertia prop assigns so the metadata
  can be used on the server and on the client.

  The maps parameter should be a list containing maps with the keys `:name` and `:content`.

  ## Examples

      iex> assign_meta(conn, [%{name: "description", content: "A description of the page"}, %{name: "keywords", content: "elixir, phoenix, inertia"}])
      %Plug.Conn{...}
  """
  def assign_meta(conn, maps) do
    conn
    |> Conn.assign(:meta, maps)
    |> Inertia.Controller.assign_prop(:meta, maps)
  end
end
