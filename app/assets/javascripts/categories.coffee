# Place all the behaviors and hooks related to the matching controller here.
# All this logic will automatically be available in application.js.
# You can use CoffeeScript in this file: http://coffeescript.org/
        
{renderable, div, text, label, input, a} = teacup

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
    totalCount = tags.reduce(((a, b) -> a + b.bookCount), 0)

    label '.btn.active.btn-sm.badge', name: "label-tag", for: "tag-all", 'data-badge': totalCount, ->
        text 'All'
    input '#tag-all', name: "tags", type: "radio", hidden: true, checked: true, onchange: "tagSelected(this)"
        
    for tag in tags
        continue if tag.bookCount == 0
        input '#tag-'+tag.name, name: "tags", type: "radio", hidden: true, onchange: "tagSelected(this)"
        label '.btn.btn-sm.badge', name: "label-tag", for: "tag-"+tag.name, 'data-badge': tag.bookCount, style: "margin-left: 1em;", ->
            text tag.name
    
books_list = renderable (books) ->
    for book in books
        div '.column.col-4', ->
            div '.card', ->
                div '.card-header', ->
                    div '.card-title', ->
                        a book.name, href: '/books/' + book.id
                    div '.card-subtitle', ->
                        text book.categories.join(" ")
                    
ready = ->
    return if $("#categoryPage").length < 1
    
    books_url = location.origin + "/books.json"
    tags_url = location.origin + "/categories.json"
    $.getJSON books_url, (books) ->
        window.books = books # save books for later filtering
        $("#books").append books_list(books)
    $.getJSON tags_url, (tags) ->
        $("#tags").append tags_list(tags)   

$(document).on('turbolinks:load', ready)