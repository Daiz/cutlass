require! {
  \stable
}

###################################
######### PARSING REGEXES #########
###################################

regex =

# Parsing regex for style lines
  style: //
    Style:\s              # type
    (.*?),                # name (string)
    (.*?),                # font name (string)
    (\d+?),               # font size (int)
    (&H[\dA-F]{8}),       # primary color   (&HAABBGGRR)
    (&H[\dA-F]{8}),       # secondary color (&HAABBGGRR)
    (&H[\dA-F]{8}),       # border color    (&HAABBGGRR)
    (&H[\dA-F]{8}),       # shadow color    (&HAABBGGRR)
    (-1|0),               # bold      (-1 - true, 0 - false)
    (-1|0),               # italic    (-1 - true, 0 - false)
    (-1|0),               # underline (-1 - true, 0 - false)
    (-1|0),               # strikeout (-1 - true, 0 - false)
    ([\d\.]+?),           # X scale (float)
    ([\d\.]+?),           # Y scale (float)
    ([\d\.]+?),           # spacing (float)
    ([\d\.]+?),           # angle (float)
    (1|3),                # border style (1 - normal, 3 - opaque box)
    ([\d\.]+?),           # border size (float)
    ([\d\.]+?),           # shadow size (float)
    ([1-9]),              # alignment (1-9, numpad notation)
    (\d+?),               # margin left  (int)
    (\d+?),               # margin right (int)
    (\d+?),               # margin vert  (int)
    (\d+)                 # encoding
  //

# Parsing regex for event lines
  evt: //
    (Dialogue|Comment):\s # type (string)
    (\d+?),               # layer (int)
    (\d:\d\d:\d\d\.\d\d), # start time (0:00:00.00)
    (\d:\d\d:\d\d\.\d\d), # end time   (0:00:00.00)
    (.*?),                # style (string)
    (.*?),                # actor (string)
    (\d+?),               # margin left  (int)
    (\d+?),               # margin right (int)
    (\d+?),               # margin vert  (int)
    (.*?),                # effect (string)
    (.*)                  # text (string)
  //

# style format (&HAABBGGRR)
  alpha-color: //^
    &H
    ([\dA-F]{2})          # alpha
    ([\dA-F]{2})          # blue
    ([\dA-F]{2})          # green
    ([\dA-F]{2})          # red
  $//

# inline color format (&HBBGGRR&)
  color: //^
    &H
    ([\dA-F]{2})          # blue
    ([\dA-F]{2})          # green
    ([\dA-F]{2})          # red
    &
  $//

# inline alpha format (&HAA&)
  alpha: //^
    &H([\dA-F]{2})&       # alpha
  $//

# ASS timestamp (0:00:00.00)
  time: //
    (\d):                 # hours
    (\d\d):               # minutes
    (\d\d)\.              # seconds
    (\d\d)                # centiseconds
  //

# script info key/value pair
  info: //
    (.*?):\s              # key
    (.*)                  # value
  //

####################################
######### HELPER FUNCTIONS #########
####################################

# pad number / string with zeroes
pad = (n, m = 2) ->
  "0" * (m - (""+n).length) + n

# convert number to hex (00-FF)
hex = (num) ->
  str = num.to-string 16 .to-upper-case! |> pad

# convert ASS timestamp to milliseconds
parse-time = (text) ->
  res = text.match regex.time

  hh = parse-int res.1, 10
  mm = parse-int res.2, 10
  ss = parse-int res.3, 10
  cs = parse-int res.4, 10

  (hh * 60 * 60 * 1000) + (mm * 60 * 1000) + (ss * 1000) + (cs * 10)

# convert milliseconds to ASS timestamp
format-time = (ms) ->
  HOUR = 60 * 60 * 1000
  MINUTE = 60 * 1000
  SECOND = 1000
  hh = 0; mm = 0; ss = 0; cs = 0;

  hh = ~~  (ms / HOUR)
  mm = ~~ ((ms - hh * HOUR) / MINUTE)
  ss = ~~ ((ms - hh * HOUR - mm * MINUTE) / SECOND)
  cs = ~~ ((ms - hh * HOUR - mm * MINUTE - ss * SECOND) / 10 + 0.5)

  "#{hh}:#{pad mm}:#{pad ss}.#{pad cs}"

# get time as an object containing hours, minutes, seconds and centi/millisecs
get-time = (ms) ->
  HOUR = 60 * 60 * 1000
  MINUTE = 60 * 1000
  SECOND = 1000
  hh = 0; mm = 0; ss = 0; cs = 0;

  hh = ~~  (ms / HOUR)
  mm = ~~ ((ms - hh * HOUR) / MINUTE)
  ss = ~~ ((ms - hh * HOUR - mm * MINUTE) / SECOND)
  cs = ~~  (ms - hh * HOUR - mm * MINUTE - ss * SECOND / 10 + 0.5)
  ms = ~~  (ms - hh * HOUR - mm * MINUTE - ss * SECOND + 0.5)

  {hh, mm, ss, cs, ms}

#####################################
######### CLASS DEFINITIONS #########
#####################################

class Color

  # constructor
  # acceptable inputs:
  # r, g, b, a   (int) [a optional]
  # "&HAABBGGRR" (string)
  # "&HBBGGRR&"  (string)
  (r, g, b, a) ->
    if r && g && b then
      @r = r
      @g = g
      @b = b
      @a = a or 0
      return
    if !a && !b && !g && r then
      res = r.match regex.alpha-color
      if res
        @r = parse-int res.4, 16
        @b = parse-int res.2, 16
        @g = parse-int res.3, 16
        @a = parse-int res.1, 16
        return
      else res = r.match regex.color
      if res
        @r = parse-int res.3, 16
        @g = parse-int res.2, 16
        @b = parse-int res.1, 16
        @a = 0
        return
      else res = r.match regex.alpha
      if res
        @r = 0
        @g = 0
        @b = 0
        @a = parse-int res.1, 16
        return

  # return color in style format (&HAABBGGRR)
  style: ->
    "&H" + (hex @a) + (hex @b) + (hex @g) + (hex @r)

  # type (int) [optional]
  # 1 - primary color
  # 2 - secondary color
  # 3 - border color
  # 4 - shadow color
  inline: (type) ->
    case type and @a != 0
      "\\#{type}c&H#{hex @b}#{hex @g}#{hex @r}&\\#{type}a&H#{hex @a}&"
    case type and @a == 0
      "\\#{type}c&H#{hex @b}#{hex @g}#{hex @r}&"
    default
      "&H#{hex @b}#{hex @g}#{hex @r}&"

class Style

  # constructor
  # takes a raw style line or a regex match array as input
  # if no input is given, returns an empty style
  (text) ->
    res = switch typeof! text
    | \String => text.match regex.style
    | \Array  => text
    | _       => false

    if !res then
      res = ['', '', 0, '', '', '', '', '',
             0, 0, 0, 0, 100, 100, 0, 0, 1,
             0, 0, 2, 0, 0, 0, 0]

    @name         = res.1
    @font-name    = res.2
    @font-size    = (parse-int res.3, 10) or 40
    @color-prim   = new Color res.4
    @color-kara   = new Color res.5
    @color-bord   = new Color res.6
    @color-shad   = new Color res.7
    @bold         = res.8  is "-1" and true or false
    @italic       = res.9  is "-1" and true or false
    @underline    = res.10 is "-1" and true or false
    @strikeout    = res.11 is "-1" and true or false
    @scale-x      = (parse-float res.12, 10) or 100
    @scale-y      = (parse-float res.13, 10) or 100
    @spacing      = (parse-float res.14, 10) or 0
    @angle        = (parse-float res.15, 10) or 0
    @opaque-box   = res.16 is "3" and true or false
    @border       = (parse-float res.17, 10)
    @shadow       = (parse-float res.18, 10)
    @align        = (parse-int res.19, 10) or 2
    @margin-left  = (parse-int res.20, 10)
    @margin-right = (parse-int res.21, 10)
    @margin-vert  = (parse-int res.22, 10)
    @encoding     = (parse-int res.23, 10) or 0

    if @border == null then @border = 0
    if @shadow == null then @shadow = 0
    if @margin-left  == null then @margin-left  = 0
    if @margin-right == null then @margin-right = 0
    if @margin-vert  == null then @margin-vert  = 0

  # bold/italic/etc boolean treatment
  prop: ->
    switch it
    | true => "-1"
    | false => "0"

  # opaque box boolean treatment
  border-style: ->
    switch it
    | true  => "3"
    | false => "1"

  # ASS output
  to-ass: ->
    [
      "Style: "
      "#{@name},"
      "#{@font-name},"
      "#{@font-size},"
      "#{@color-prim.style!},"
      "#{@color-kara.style!},"
      "#{@color-bord.style!},"
      "#{@color-shad.style!},"
      "#{@prop @bold},"
      "#{@prop @italic},"
      "#{@prop @underline},"
      "#{@prop @strikeout},"
      "#{@scale-x},"
      "#{@scale-y},"
      "#{@spacing},"
      "#{@angle},"
      "#{@border-style @opaque-box},"
      "#{@border},"
      "#{@shadow},"
      "#{@align},"
      "#{@margin-left},"
      "#{@margin-right},"
      "#{@margin-vert},"
      "#{@encoding}"
    ].join ""

class Event

  # constructor
  # takes a raw event line or a regex match array as input
  # if no input is given, returns an empty event
  (text) ->
    res = switch typeof! text
    | \String => text.match regex.evt
    | \Array  => text
    | _       => false

    if !res then
      res = ['', 0, "0:00:00.00", "0:00:00.00", '', '', 0, 0, 0, '', '']

    @comment      = res.1 is "Comment" and true or false
    @layer        = (parse-int res.2, 10) or 0
    @start-time   = parse-time res.3
    @end-time     = parse-time res.4
    @style        = res.5 or ""
    @actor        = res.6 or ""
    @margin-left  = (parse-int res.7, 10) or 0
    @margin-right = (parse-int res.8, 10) or 0
    @margin-vert  = (parse-int res.9, 10) or 0
    @effect       = res.10 or ""
    @text         = res.11 or ""

  # get times as objects
  get-start-time: -> get-time @start-time
  get-end-time:   -> get-time @end-time

  # get line duration in milliseconds
  duration: -> @end-time - @start-time

  # characters per second
  cps: ->
    second = @duration! / 1000
    # remove all extra stuff from the text so that only characters remain
    characters = @text.replace //
      \\(N|n|h)     # line breaks and hard spaces
      |[\.,?!]      # punctuation
      |{.*?}        # tags and comments
      |\s+          # whitespace
      //g ''
      .length

    Math.round characters / second

  # output type
  type: -> @comment and "Comment" or "Dialogue"

  # ASS output
  to-ass: ->
    [
      "#{@type!}: "
      "#{@layer},"
      "#{format-time @start-time},"
      "#{format-time @end-time},"
      "#{@style},"
      "#{@actor},"
      "#{@margin-left},"
      "#{@margin-right},"
      "#{@margin-vert},"
      "#{@effect},"
      "#{@text}"
    ].join ""

class Header

  (type, key, value) ->
    @type = type
    @key = key
    @value = value

  to-ass: ->
    switch @type
    | \Comment => \; + @value
    | \Key     => @key + ': ' + @value

class Script

  # constructor
  # takes a raw script as input
  (text) ->
    @info = []
    @styles = []
    @events = []

    # just give an empty script if no text is given
    if !text then return

    text .= replace /\r\n|\r/g '\n'
    rows = text.split '\n'

    block = \info

    for line in rows
      switch line
      | '[Script Info]' => block = \info;   continue
      | '[V4+ Styles]'  => block = \styles; continue
      | '[Events]'      => block = \events; continue

      if block != \info and line.match /^Format: / then continue

      switch block
        case \info
          if line.match /^;/
            res = line.split \;
            @info.push new Header \Comment void res.1
          else if res = line.match regex.info
            @info.push new Header \Key res.1, res.2

        case \styles
          if res = line.match regex.style
            @styles.push new Style res

        case \events
          if res = line.match regex.evt
            @events.push new Event res

    # check script for basic headers and add them if they are missing
    if !@header 'ScriptType'
      @header 'ScriptType' 'v4.00+'
    if !@header 'WrapStyle'
      @header 'WrapStyle' '0'
    if !@header 'ScaledBorderAndShadow'
      @header 'ScaledBorderAndShadow' 'yes'

  header: (key, value) ->
    switch typeof key
    case \object
      for k, v of key
        @header k, v
    case \string
      if !value
        for h in @info
          if h.type is \Key and h.key is key then return h.value
      else
        res = void
        for h in @info
          if h.type is \Key and h.key is key then res = h
        if res then res.value = value
        else
          res = new Header \Key key, value
          @info.push res

  add-style: (input) ->
    switch typeof! input
      case \Style
        @styles.push input
      case \String
        if res = input.match regex.style
          @styles.push new Style res

  add-event: (input) ->
    switch typeof! input
      case \Eventt
        @events.push input
      case \String
        if res = input.match regex.evt
          @events.push new Event res

  # default sort
  sort: ->
    stable.inplace @events, (a, b) ->
      c = a.start-time - b.start-time
      if c == 0 then return a.layer - b.layer
      else return c
    return @

  # return a clone of the current script
  clone: -> new Script @to-ass!
  
  # ASS output
  to-ass: ->
    text = "[Script Info]\n"

    for h in @info
      text += "#{h.to-ass!}\n"

    text += "\n[V4+ Styles]\n"
    text += "Format: Name, Fontname, Fontsize, "
    text += "PrimaryColour, SecondaryColour, OutlineColour, BackColour, "
    text += "Bold, Italic, Underline, StrikeOut, ScaleX, ScaleY, Spacing, "
    text += "Angle, BorderStyle, Outline, Shadow, Alignment, "
    text += "MarginL, MarginR, MarginV, Encoding\n"

    for s in @styles
      text += "#{s.to-ass!}\n"

    text += "\n[Events]\n"
    text += "Format: Layer, Start, End, Style, Name, "
    text += "MarginL, MarginR, MarginV, Effect, Text\n"

    for e in @events
      text += "#{e.to-ass!}\n"

    # UTF-8 BOM is included in the beginning
    ('\ufeff' + text.trim!)

module.exports = {Color, Style, Event, Header, Script}