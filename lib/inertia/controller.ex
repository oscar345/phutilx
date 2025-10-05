defmodule Phutilx.Inertia.Controller do
  alias Plug.Conn
  use Phoenix.Component

  @spec assign_title(Conn.t(), String.t()) :: Conn.t()
  @spec assign_meta(Conn.t(), list()) :: Conn.t()
  @spec render_meta(map()) :: Phoenix.LiveView.Rendered.t()
  @spec render_title(map()) :: Phoenix.LiveView.Rendered.t()
  @spec render_error(map(), String.t()) :: Conn.t()
  @spec assign_filter(
          Conn.t(),
          (-> {:ok, list()} | {:ok, any()} | {:error, Ecto.Changeset.t()}),
          keyword()
        ) :: Conn.t()

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

  @doc """
  Render meta tags from the assigned metadata. This function can be used in the layout template and in
  combination with `Phutilx.Inertia.Controller.assign_meta/2`.
  """
  def render_meta(assigns) do
    ~H"""
    <%= for %{name: name, content: content} <- @meta || [] do %>
      <meta name={name} content={content} />
    <% end %>
    """
  end

  @doc """
  Renders a title for the application. Should be used inside the layout template and can be used with the
  `Phutilx.Inertia.Controller.assign_title/2` function.
  """
  def render_title(assigns) do
    ~H"""
    <.live_title default="Welcome" suffix=" · MyApp">
      {assigns[:page_title]}
    </.live_title>
    """
  end

  @doc """
  Use the render function in the `ErrorHTML` module to render an error page with inertia inside your application.
  Only use this function for errors which are not recoverable, for example a 404 or 500 error.
  """
  def render_error(%{status: status, conn: conn} = _assigns, component \\ "Error") do
    Inertia.Controller.render_inertia(conn, component, %{
      status: status
    })
  end

  @doc """
  Expects a function that returns either a `{:ok, list()}`, `{:ok, %Paginate{}}` or `{:error, changeset}` tuple and
  assigns the result to the given key as an inertia prop, when the result is `:ok`. Otherwise the key is assigned
  `nil` and the changeset errors are assigned to the conn using the `Phutilx.Inertia.Errors` struct.

  ## Examples

      iex> assign_filter(conn, :users, fn -> Accounts.list_users(params) end)
      %Plug.Conn{...}

  ## Options
    * `:key` - The key to assign the result to, defaults to `:items`.
    * `:key_error` - The key to assign the errors to, defaults to `:filter`.

  """
  def assign_filter(conn, filter_fun, opts \\ []) do
    key = Keyword.get(opts, :key, :items)
    key_error = Keyword.get(opts, :key_error, :filter)

    case filter_fun.() do
      {:ok, values} ->
        conn |> Inertia.Controller.assign_prop(key, values)

      {:error, changeset} ->
        conn
        |> Inertia.Controller.assign_errors(%Phutilx.Inertia.Errors{
          changeset: changeset,
          key: key_error
        })
        |> Inertia.Controller.assign_prop(key, nil)
    end
  end
end
