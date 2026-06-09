defmodule GuitarVaultWeb.HealthController do
  use GuitarVaultWeb, :controller

  def check(conn, _params) do
    send_resp(conn, 200, "OK")
  end
end
