class Kinotracker

    properties:
        AddTag:    false,
        Tag:       'DVDRip'
        Sort:      4
        SortOrder: 2

    links:          require './data/links'
    template:       require './templates/kinotracker'
    markerTemplate: require './templates/marker'
    bubbleTemplate: require './templates/bubble'

    constructor: ->
        @el = $ 'h1[itemprop=name]'
        @initialize()

    initialize: ->
        @loadProperties @properties
        @highlightMarkers()
        @bindEvents()

    render: (data)->
        @el.append @template data

    bindEvents: ->
        template = @bubbleTemplate

        document.addEventListener "mouseup", ->
            selection = window.getSelection().toString()
            selectedRange = window.getSelection().getRangeAt( 0 ).cloneRange()
            if selectedRange.startOffset is selectedRange.endOffset then return

            fetch "https://www.kinopoisk.ru/search/handler-chromium-extensions?v=1&query=" + encodeURIComponent( selection )
                .then ( res )-> res.json()
                .then ( data )->
                    selectedRangeRect = selectedRange.getBoundingClientRect()

                    $bubble = $ template { data }

                    $bubble.css
                        top: selectedRangeRect.top + window.scrollY
                        left: selectedRangeRect.right + window.scrollX

                    $ document.body
                        .append $bubble

                    hideBubble = ->
                        $bubble.remove()
                        document.removeEventListener "mousedown", hideBubble

                    document.addEventListener "mousedown", hideBubble


    addLinks: (dyn_url, options, filmname)->
        data =
            links: @links
            clue: dyn_url
            options: options
            marker: filmname

        @render data

    loadProperties: (options)->
        chrome.extension.sendRequest options, (response)=>
            @getInfo response

    getInfo: (opt)->
        banned_chars = /"|«|»|\(ТВ\)|&|:|!|·|\(сериал\)/g

        #mov_local_name = $('h1[itemprop=name]') # Блок названия на русском

        mov_orig_name = $('span[itemprop=alternativeHeadline]').text() # Оригинальное название
        year = $('table.info tr:first-of-type a:first-of-type').text() # Год выпуска
        filmname = (mov_orig_name || @el.text())
        mov = filmname.replace(banned_chars, '') # Название фильма (оригинал/рус)
        marker = [@el.text(), mov_orig_name].join("&")
        dyn_url = '?o=' + opt.Sort + '&s=' + opt.SortOrder + '&nm=' + mov + ' ' + year

        opt.Tag = if ( opt.AddTag is "true" ) then opt.Tag else ""

        @addLinks dyn_url, opt.Tag, marker


    highlightMarkers: ->
        markerTemplate = @markerTemplate

        if @links[location.hostname]
            markers = location
                .hash
                .replace "#marker=", ""
                .split "&"

            $scopeElements = $ @links[location.hostname].link_selector

            $scopeElements.each ->
                $this = $ @
                html = $this.html()
                
                markers.forEach (element)->
                    regexp = new RegExp element, "i"
                    marker = markerTemplate data: marker: element

                    html = html.replace regexp, marker

                $this.html html


module.exports =
    new Kinotracker()