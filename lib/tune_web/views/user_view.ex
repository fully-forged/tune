defmodule TuneWeb.UserView do
  use TuneWeb, :view

  defp avatar(user) do
    name = user["display_name"]
    image_url = get_in(user, ["images", Access.at(0), "url"])
    img_tag(image_url, alt: name, class: "user-avatar")
  end
end
