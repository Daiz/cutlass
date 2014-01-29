{cat} = require \shelljs
module.exports = (file) ->
  cat file .replace /\r\n|\r/g '\n' .replace /^\ufeff/ '' .trim!