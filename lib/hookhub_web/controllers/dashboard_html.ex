defmodule HookhubWeb.DashboardHTML do
  use HookhubWeb, :html

  embed_templates("dashboard_html/*")

  def format_datetime(nil), do: "-"

  def format_datetime(datetime) do
    Calendar.strftime(datetime, "%Y-%m-%d %H:%M:%S UTC")
  end

  def truncate(nil, _length), do: ""

  def truncate(text, length) when byte_size(text) <= length, do: text

  def truncate(text, length) do
    String.slice(text, 0, length) <> "..."
  end
end
