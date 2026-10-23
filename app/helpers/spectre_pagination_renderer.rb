# will_paginate loads its view helpers lazily; production eager-loads this
# file before that, so load the base class here.
require 'will_paginate/view_helpers/action_view'

# will_paginate's page links in Spectre's pagination markup:
# ul.pagination > li.page-item > a, with .active and .disabled items. The
# first and last pages are marked .page-edge, so phones can leave them out.
class SpectrePaginationRenderer < WillPaginate::ActionView::LinkRenderer
  protected

  def html_container(html)
    tag(:ul, html, container_attributes)
  end

  def page_number(page)
    aria_label = @template.will_paginate_translate(:page_aria_label, page: page.to_i) { "Page #{page}" }
    edge = 'page-edge' if page == 1 || page == total_pages
    if page == current_page
      item(link(page, page, 'aria-label': aria_label, 'aria-current': 'page'), 'active')
    else
      item(link(page, page, rel: rel_value(page), 'aria-label': aria_label), edge)
    end
  end

  def previous_or_next_page(page, text, classname, aria_label = nil)
    if page
      item(link(text, page, 'aria-label': aria_label), classname)
    else
      item(tag(:a, text, 'aria-label': aria_label, 'aria-disabled': true), "#{classname} disabled")
    end
  end

  def gap
    item(tag(:span, @template.will_paginate_translate(:page_gap) { '&hellip;' }), 'gap')
  end

  private

  def item(content, classname = nil)
    tag(:li, content, class: ['page-item', classname].compact.join(' '))
  end
end
