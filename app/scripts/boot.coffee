displayHomepage = ->
  $('html').addClass 'force-vscrollbar'
  $("#homepage").css "display", "block"
  _gaq.push ['_trackPageview'] # standard pageview

loadAndDisplayGist = (gistId) ->
  $("#comix-spinner").show()

  spinnerOpts =
    lines: 10, # The number of lines to draw
    length: 5, # The length of each line
    width: 3, # The line thickness
    radius: 4, # The radius of the inner circle
    corners: 1, # Corner roundness (0..1)
    rotate: 15, # The rotation offset
    color: '#666', # #rgb or #rrggbb
    speed: 1, # Rounds per second
    trail: 72, # Afterglow percentage
    shadow: false, # Whether to render a shadow
    hwaccel: false, # Whether to use hardware acceleration
    className: 'spinner', # The CSS class to assign to the spinner
    zIndex: 2e9, # The z-index (defaults to 2000000000)
    top: 'auto', # Top position relative to parent in px
    left: 'auto' # Left position relative to parent in px

  spinner = new Spinner(spinnerOpts).spin()
  $("#comix-spinner").append spinner.el

  window.gistId = gistId
  src = "https://api.github.com/gists/" + gistId
  src = "gist-test.html" if gistId is "test"

  $(document).ajaxError (event, xhr) ->
    spinner.stop()
    $("#error").css "display", "block"
    $("#error-response").text xhr.responseText
    $("#error-gist-number").text "#" + gistId
    $("#error-gist-link").attr("href", src).text src
    $("#error-gist-index-link").attr "href", "https://gist.github.com/" + gistId
    _gaq.push ['_trackPageview', '/error/'+gistId] # virtual error pageview
    console.log "failed to fetch the content"

  console.log "fetching #{src}..."
  $.get src, (content) ->
    console.log "received", content

    description = "A Comix"
    if gistId is "test"
      header = "some custom header"
      comix = content
      footer = "some custom footer"
      description = "Hello world! TEST\nsecond line"
      author = "Antonin Hildebrand"
      authorUrl = "https://gist.github.com/4770953"
      date = "Jan 16, 2013"
    else
      header = content.files?["header.html"]?.content
      comix = content.files?["index.html"]?.content
      footer = content.files?["footer.html"]?.content
      description = content.description if content.description
      author = content.user?.login
      authorUrl = content.html_url
      d = new Date(content.created_at)
      date = d.format "mmm d, yyyy"

    description = description.split("\n")[0]

    $stage = $("<iframe/>",
      class: "stage"
      scrolling: "no"
      frameborder: 0
      allowTransparency: "true"
    )
    $comix = $("#comix")
    $placeholder = $("#comix-placeholder")
    $placeholder.append header if header
    $placeholder.append $stage
    $placeholder.append footer if footer

    $banner = $("#comix-banner")
    $banner.find(".comix-title").append description if description
    $banner.find(".comix-author").append "by <a href=\"#{authorUrl}\">#{author}</a>" if author?
    $banner.find(".comix-date").append "on #{date}" if date?

    window.messageFromCMX = (event, cmx) ->
      switch event
        when 'cmx:ready'
          window.cmxref = cmx

          $comix.css
            opacity: 0
            display: "block"

          $comix.animate
            opacity: 1

          spinner.stop()

          # find contents' width sweet spot
          lW = 0
          lH = undefined
          rW = 10000
          $stage.css width:"#{rW}px"
          rH = $stage.contents().height()
          while rW - lW > 2 and rW > 600 # 600px is our cointainer's min-width anyway
            midW = Math.floor((lW + rW) / 2)
            $stage.css width:"#{midW}px"
            h = $stage.contents().height()
            # console.log lW, rW, lH, rH

            if rH is h
              rW = midW
            else
              lW = midW
              lH = h

          console.log "flex width detected w=#{rW} h=#{rH}"

          $stage.css height:"#{rH}px", width:"#{rW}px"
          $comix.css width:"#{rW}px"
          $placeholder.css width:"#{rW}px"

    doc = $stage.contents().get(0)
    doc.open()
    doc.write comix
    doc.close()

    _gaq.push ['_trackPageview', '/gist/'+gistId] # virtual gist pageview

$ ->

  hash = location.hash.substring(1)

  # disqus uses #comment-12345 style hashes
  if hash.match /^comment/
    hash = undefined

  if hash
    loadAndDisplayGist(hash)
  else
    displayHomepage()

