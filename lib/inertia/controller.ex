defmodule Phutilx.Inertia.Controller do
  alias Plug.Conn
  use Phoenix.Component

  @spec assign_title(Conn.t(), String.t()) :: Conn.t()
  @spec assign_meta(Conn.t(), list()) :: Conn.t()
  @spec render_meta(map()) :: Phoenix.LiveView.Rendered.t()
  @spec render_title(map()) :: Phoenix.LiveView.Rendered.t()
  @spec render_error(map(), String.t()) :: Conn.t()
  @spec assign_params(Conn.t(), map()) :: Conn.t()

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
  Get the params from the plug function and assign them to the inertia props so they can be used on the client side.
  This is especially useful when you want to use the params for filtering or pagination.
  """
  def assign_params(conn, params) do
    conn |> Inertia.Controller.assign_prop(:params, params)
  end
end
