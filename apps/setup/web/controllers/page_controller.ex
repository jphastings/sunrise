defmodule Setup.PageController do
  use Setup.Web, :controller

  def index(conn, _params) do
    render conn, "index.html"
  end
end
