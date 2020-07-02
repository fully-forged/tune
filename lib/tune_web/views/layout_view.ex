defmodule TuneWeb.LayoutView do
  use TuneWeb, :view

  defp authenticated?(conn) do
    conn.assigns.status == :authenticated
  end
end
