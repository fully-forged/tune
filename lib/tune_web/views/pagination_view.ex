defmodule TuneWeb.PaginationView do
  @moduledoc false
  use TuneWeb, :view

  @max_left 3
  @max_right 2

  def pagination_opts(page, per_page, total) do
    total_pages = div(total, per_page)

    total_pages =
      case rem(total, per_page) do
        0 -> total_pages
        _other -> total_pages + 1
      end

    if total_pages > @max_left + @max_right do
      {all_left_pages, all_right_pages} = Enum.split_while(1..total_pages, fn i -> i <= page end)

      left_pages = Enum.take(all_left_pages, -@max_left)

      compensated_max_right = @max_right + @max_left - Enum.count(left_pages)

      right_pages = Enum.take(all_right_pages, compensated_max_right)

      %{
        mode: :split,
        left_pages: left_pages,
        right_pages: right_pages,
        per_page: per_page,
        current_page: page,
        total_pages: total_pages
      }
    else
      %{
        mode: :continuous,
        pages: 1..total_pages,
        per_page: per_page,
        current_page: page,
        total_pages: total_pages
      }
    end
  end

  defp prev_page(pagination_opts, url_fn) do
    page = max(pagination_opts.current_page - 1, 1)

    if page == pagination_opts.current_page do
      content_tag(:li, "<", class: "current")
    else
      content_tag :li do
        live_patch("<", to: url_fn.(page, pagination_opts.per_page))
      end
    end
  end

  defp next_page(pagination_opts, url_fn) do
    page = min(pagination_opts.current_page + 1, pagination_opts.total_pages)

    if page == pagination_opts.current_page do
      content_tag(:li, ">", class: "current")
    else
      content_tag :li do
        live_patch(">", to: url_fn.(page, pagination_opts.per_page))
      end
    end
  end

  defp numbered_page(page, pagination_opts, url_fn) do
    if page == pagination_opts.current_page do
      content_tag(:li, page, class: "current")
    else
      content_tag :li do
        live_patch(page, to: url_fn.(page, pagination_opts.per_page))
      end
    end
  end
end
