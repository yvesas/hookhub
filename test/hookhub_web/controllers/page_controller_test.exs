defmodule HookhubWeb.PageControllerTest do
  use HookhubWeb.ConnCase

  test "GET /", %{conn: conn} do
    conn = get(conn, ~p"/")
    assert redirected_to(conn) == ~p"/dashboard"
  end
end
