defmodule GuitarVaultWeb.PageController do
  use GuitarVaultWeb, :controller

  def home(conn, _params) do
    render(conn, :home)
  end
end
