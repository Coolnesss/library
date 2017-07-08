# Place all the behaviors and hooks related to the matching controller here.
# All this logic will automatically be available in application.js.
# You can use CoffeeScript in this file: http://coffeescript.org/
        
{renderable, div, text, label, input} = teacup

@tagSelected = (e) ->
    label = $("label[for='"+$(e).attr('id')+"']");
    if ($(e).is(":checked")) 
        $('[name="label-tag"]').removeClass("active")
        $(label).addClass("active")
        
        # Filter books
        if label.text() == 'All'
            $("#books").empty()
            $("#books").append(books_list(window.books))
            return

        toRender = (book for book in window.books when label.text() in book.categories)
        $("#books").empty()
        $("#books").append(books_list(toRender))
    
tags_list = renderable (tags) ->
    tags = tags.sort((a, b) -> b.name < a.name)
    
    label '.chip.active', name: "label-tag", for: "tag-all", ->
        text 'All'
    input '#tag-all', name: "tags", type: "radio", hidden: true, checked: true, onchange: "tagSelected(this)"
        
    for tag in tags
        input '#tag-'+tag.name, name: "tags", type: "radio", hidden: true, onchange: "tagSelected(this)"
        label '.chip', name: "label-tag", for: "tag-"+tag.name, ->
            text tag.name
    
books_list = renderable (books) ->
    for book in books
        div '.column.col-4', ->
            div '.card', ->
                div '.card-header', ->
                    div '.card-title', ->
                        text book.name_eng
                    div '.card-subtitle', ->
                        text book.categories.join(" ")
                    
                    

ready = ->
    books_url = location.origin + "/books.json"
    tags_url = location.origin + "/categories.json"
    $.getJSON books_url, (books) ->
        window.books = books # save books for later filtering
        $("#books").append books_list(books)
    $.getJSON tags_url, (tags) ->
        $("#tags").append tags_list(tags)   

$(document).on('turbolinks:load', ready)