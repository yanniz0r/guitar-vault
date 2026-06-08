defmodule GuitarVault.Repo do
  use Ecto.Repo,
    otp_app: :guitar_vault,
    adapter: Ecto.Adapters.SQLite3
end
