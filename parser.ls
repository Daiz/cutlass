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
    (\d+?)                # encoding
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
    (.*?)                 # text (string)
  //

# style format (&HAABBGGRR)
  alpha-color: //
    &H
    ([\dA-F]{2})          # alpha
    ([\dA-F]{2})          # blue
    ([\dA-F]{2})          # green
    ([\dA-F]{2})          # red
  //

# inline color format (&HBBGGRR&)
  color: //
    &H
    ([\dA-F]{2})          # blue
    ([\dA-F]{2})          # green
    ([\dA-F]{2})          # red
    &
  //

# inline alpha format (&HAA&)
  alpha: //
    &H([\dA-F]{2})&       # alpha
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
    if !a && !b && !g && r then
      res = r.match regex.alpha-color
      if res
        @r = parse-int res.4, 16
        @b = parse-int res.2, 16
        @g = parse-int res.3, 16
        @a = parse-int res.1, 16
      else res = r.match regex.color
      if res
        @r = parse-int res.3, 16
        @g = parse-int res.2, 16
        @b = parse-int res.1, 16
        @a = 0
      else res = r.match regex.alpha
      if res
        @r = 0
        @g = 0
        @b = 0
        @a = parse-int res.1, 16

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