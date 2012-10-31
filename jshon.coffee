fs  = require 'fs'                                  # -*- coffee-tab-width:2 -*-


# Global variables
version = 20121030
args  = []
file  = '-'
jsonp   = false
sort    = false
quiet   = false
byvalue = false
cont    = false
inplace = false

bail = (arg) ->


# Utility functions
err = (str) -> process.stderr.write str+"\n"
out = (str) -> process.stdout.write str+"\n"

type = (it) ->
  switch typeof it
    when "number" then "number"
    when "string" then "string"
    when "boolean" then "bool"
    else (if it instanceof Array then 'array' else 'object')

length = (it) ->
  my_type = type it
  switch my_type
    when "array"  then it.length
    when "object" then (Object.keys it).length
    else
      console.log "parse error: type '#{my_type}' has no length"
      process.exit 1


# Parse the arguments
argv = process.argv
argv.shift(); argv.shift();
while argv.length > 0
  arg = argv.shift()
  switch arg
    when '-P' then jsonp   = true
    when '-S' then sort    = true
    when '-Q' then quiet   = true
    when '-V' then byvalue = true
    when '-C' then cont    = true
    when '-I' then inplace = true
    when '-F' then file    = argv.shift()
    when '-t' then args.push ['type',      0]
    when '-l' then args.push ['length',    0]
    when '-k' then args.push ['keys',      0]
    when '-u' then args.push ['unstring',  0]
    when '-p' then args.push ['pop',       0]
    when '-a' then args.push ['across',    0]
    when '-s' then args.push ['string',    argv.shift()] # takes a value, encodes as json
    when '-n' then args.push ['nonstring', argv.shift()] # takes [true, false, null, array, object, integer, float]
    when '-e' then args.push ['extract',   argv.shift()] # takes an index (number or key)
    when '-i' then args.push ['insert',    argv.shift()] # takes an index
    when '-d' then args.push ['delete',    argv.shift()] # takes an index
    when '--version' then process.stdout.write "#{version}\n"; process.exit 0
    else
      err "jshon: invalid option -- '#{arg}'"
      err "Valid: -[P|S|Q|V|C|I] [-F path] -[t|l|k|u|p|a] -[s|n] value -[e|i|d] index"
      process.exit 1


# Run
run = (stack) ->
  while args.length > 0
    arg = args.shift()
    it = stack.shift()
    console.log "# arg is #{JSON.stringify arg} top is #{JSON.stringify it}"
    if it == undefined and not arg[0] == 'string'
      out "internal error: stack underflow"
      process.exit 1
    switch arg[0]
      when 'type'
        out (type it)
      when 'length'
        out (length it)
      when 'keys'
        switch type it
          when "object"
            stack.push Object.keys(it)
          else
            err "parse error: type #{type it} has no keys"
      when 'unstring'
        out "#{it}"
      when 'pop' then undefined
      when 'across'
        remaining = args
        args = []
        switch type it
          when "array"
            for el in it
              stack.push el
              args = args.concat remaining
          when "object"
            for k,v of it
              stack.push v
              args = args.concat remaining
          else
            err "parse error: type not mappable"
            process.exit 1
      when 'string'
        out JSON.stringify arg[1]
      when 'nonstring'
        console.log 'nonstring'
      when 'extract'
        console.log 'extract'
      when 'insert'
        console.log 'insert'
      when 'delete'
        console.log 'delete'
  process.exit 0


# Read the input JSON and put it on the stack
if file == '-'
  if process.stdin.isTTY
    err "warning: nothing to read"
    run []
  else
    json = ""
    process.stdin.resume()
    process.stdin.setEncoding 'utf8'
    process.stdin.on 'data', (chunk) -> json += chunk
    process.stdin.on 'end', () -> run [JSON.parse(json)]
else
  fs.readFile file, 'utf8', (err,data) ->
    if err then throw err
    run [JSON.parse(data)]
