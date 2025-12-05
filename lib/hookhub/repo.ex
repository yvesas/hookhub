defmodule Hookhub.Repo do
  use Ecto.Repo,
    otp_app: :hookhub,
    adapter: Ecto.Adapters.Postgres
end
