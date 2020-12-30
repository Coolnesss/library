$(document).on "turbolinks:load", ->
    $('#nav-toggle').on 'click', ->
        $('#sidebar-id').addClass('active')
    $('#nav-toggle-remove').on 'click', ->
        $('#sidebar-id').removeClass('active')