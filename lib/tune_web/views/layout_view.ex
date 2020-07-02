defmodule TuneWeb.LayoutView do
  use TuneWeb, :view

  defp user_avatar(user) do
    name = user["display_name"]
    image_url = get_in(user, ["images", Access.at(0), "url"])
    img_tag(image_url, alt: name, class: "user-avatar")
  end

  defp authenticated?(conn) do
    conn.assigns.status == :authenticated
  end
end
