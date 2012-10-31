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
  process.stdout.write "jshon: invalid option -- '#{arg}'\n"
  process.stdout.write "Valid: -[P|S|Q|V|C|I] [-F path] -[t|l|k|u|p|a] -[s|n] value -[e|i|d] index\n"
  process.exit 1


# Utility functions
type = (it) ->
  switch typeof it
    when "number" then "number"
    when "string" then "string"
    when "boolean" then "bool"
    else (if it instanceof Array then 'array' else 'object')

length = (it) ->
  my_type = type it
  if my_type == "array" or my_type == "object"
    it.length
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
    when '-F' then file = argv.shift()
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
    else bail arg


# Read the input JSON and put it on the stack
if file == '-'
  json = ""
  process.stdin.resume
  process.stdin.setEncoding 'utf8'
  process.stdin.on 'data', (chunk) -> json += chunk
  process.stdin.on 'end', () -> run [JSON.parse(json)]
else
  fs.readFile file, 'utf8', (err,data) ->
    if err then throw err
    run [JSON.parse(data)]


# Run
run = (stack) ->
  while args.length > 0
    arg = args.shift()
    it = stack.shift()
    console.log "# arg is #{JSON.stringify arg} top is #{JSON.stringify it}"
    if it == undefined
      console.log "internal error: stack underflow"
      process.exit 1
    switch arg[0]
      when 'type'
        console.log (type it)
      when 'length'
        console.log (length it)
      when 'keys'
        console.log 'keys'
      when 'unstring'
        console.log 'unstring'
      when 'pop'
        console.log 'pop'
      when 'across'
        console.log 'across'
      when 'string'
        console.log 'string'
      when 'nonstring'
        console.log 'nonstring'
      when 'extract'
        console.log 'extract'
      when 'insert'
        console.log 'insert'
      when 'delete'
        console.log 'delete'
  process.exit 0
