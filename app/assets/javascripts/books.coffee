# Place all the behaviors and hooks related to the matching controller here.
# All this logic will automatically be available in application.js.
# You can use CoffeeScript in this file: http://coffeescript.org/

capitalize = (string) ->
    return string.charAt(0).toUpperCase() + string.slice(1) 

@removeChoice = (element) ->
    element.parent().remove()

createTag = (name) ->
    return '<label class="chip">' + name + 
            '<button  onclick="removeChoice($(this))" class="btn btn-clear"></button>
             <input type="hidden" id="tags[]" name="tags[]" value="' + name + '" />
             </label>'

ready = ->
    # Target specific views
    if $("#addNewTag").length < 1
        return

    current_book_id = location.pathname.split("/")[2]
    url = location.origin + "/books/" + current_book_id + "/categories.json"
    
    $.getJSON url, (tags) ->
        $.each tags, (index, tag) ->
            $("#tags").append(createTag(tag.name))

    $("#addNewTag").on 'keydown', (e) ->
        if e.which == 13 # User pressed enter
            e.preventDefault() 
            tag = createTag(capitalize($("#addNewTag").val()))
            $("#tags").append(tag)
            $("#addNewTag").val("")

$(document).on('turbolinks:load', ready)