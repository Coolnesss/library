module ApplicationHelper

  # Descriptions and thoughts are written in Markdown by the people who can
  # edit them. Sanitize the result: rendering it raw let anyone with an
  # account put a script on a book's page.
  def markdown(text)
    renderer = Redcarpet::Markdown.new(Redcarpet::Render::HTML, autolink: true)
    sanitize renderer.render(text.to_s)
  end

  # A Font Awesome 5 Free solid icon (CC BY 4.0), inlined as SVG, with an
  # optional label. The icons in use are copied into app/assets/images/icons.
  def fa_icon(name, text: nil)
    @fa_icons ||= {}
    svg = @fa_icons[name] ||= Rails.root.join("app/assets/images/icons/#{name}.svg").read
                                    .sub('<svg ', '<svg class="fa-icon" aria-hidden="true" ').html_safe
    text ? safe_join([svg, text]) : svg
  end

  def bootstrap_class_for flash_type
    { success: "toast-success", error: "toast-error", alert: "toast-warning", notice: "toast-primary" }[flash_type.to_sym] || flash_type.to_s
  end

  def flash_messages(opts = {})
    flash.each do |msg_type, message|
      concat(content_tag(:div, message, class: "toast #{bootstrap_class_for(msg_type)} alert-dismissible", role: 'alert') do
        concat(content_tag(:button, class: 'btn btn-clear float-right', data: { dismiss: 'alert' }) do
          concat content_tag(:span, 'Close', class: 'sr-only')
        end)
        concat message
      end)
    end
    nil
  end
  

end
