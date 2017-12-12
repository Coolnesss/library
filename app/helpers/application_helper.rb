module ApplicationHelper

  def bootstrap_class_for flash_type
    { success: "toast-success", error: "toast-error", alert: "toast-warning", notice: "toast-primary" }[flash_type.to_sym] || flash_type.to_s
  end

  def sortable(column, title = nil)
    title ||= column.titleize
    css_class = column == sort_column ? "current #{sort_direction}" : nil
    direction = column == sort_column && sort_direction == "asc" ? "desc" : "asc"
    link_to title, {:sort => column, :direction => direction}, {:class => css_class}
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
