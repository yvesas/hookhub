defmodule HookhubWeb.PageController do
  use HookhubWeb, :controller

  def home(conn, _params) do
    redirect(conn, to: "/dashboard")
  end
end
