defmodule Phutilx.Inertia.Controller do
  alias Plug.Conn

  def assign_title(conn, title) do
    conn
    |> Conn.assign(:page_title, title)
    |> Inertia.Controller.assign_prop(:page_title, title)
  end

  def assign_meta(conn, map) do
    conn
    |> Conn.assign(:meta, map)
    |> Inertia.Controller.assign_prop(:meta, map)
  end
end
