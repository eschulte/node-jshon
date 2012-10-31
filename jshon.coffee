# MIT licensed, Copyright (C) 2012  Eric Schulte      -*- coffee-tab-width:2 -*-

fs  = require 'fs'


# Global variables
version = 'VERSION'
args  = []
file  = '-'
jsonp   = false # TODO: implement
sort    = false
quiet   = false
dodebug = false
byvalue = false # TODO: implement
cont    = false # TODO: implement (maybe, check C code)
inplace = false


# Utility functions
err   = (str) -> process.stderr.write str+"\n" unless quiet
out   = (str) -> process.stdout.write str+"\n"
debug = (str) -> console.log str if dodebug

type = (it) ->
  switch typeof it
    when "number" then "number"
    when "string" then "string"
    when "boolean" then "bool"
    else
      if it instanceof Array then 'array'
      else if it == null     then 'null'
      else                        'object'

length = (it) ->
  my_type = type it
  switch my_type
    when "array"  then it.length
    when "object" then (Object.keys it).length
    else
      err "parse error: type '#{my_type}' has no length"
      process.exit 1

dosort = (it) ->
  my_type = type it
  switch my_type
    when "array"  then it.sort()
    when "object"
      out = {}
      (out[key] = it[key] for key in (Object.keys it).sort())
      out
    else it


# Parse the arguments
argv = process.argv
argv.shift(); argv.shift();
while argv.length > 0
  arg = argv.shift()
  switch arg
    when '-P' then jsonp   = true
    when '-S' then sort    = true
    when '-Q' then quiet   = true
    when '-D' then dodebug = true
    when '-V' then byvalue = true
    when '-C' then cont    = true
    when '-I' then inplace = true
    when '-F' then file    = argv.shift()
    when '-t' then args.push ['type',      null]
    when '-l' then args.push ['length',    null]
    when '-k' then args.push ['keys',      null]
    when '-u' then args.push ['unstring',  null]
    when '-p' then args.push ['pop',       null]
    when '-a' then args.push ['across',    null]
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
    debug "# args:#{JSON.stringify args} stack:#{JSON.stringify stack}"
    arg = args.shift()
    it = stack.pop() unless arg[0] == 'string' or arg[0] == 'nonstring'
    if it == undefined and arg[1] == null
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
          when 'array'
            for el in it
              stack.push el
              args = args.concat remaining
          when 'object'
            for k,v of it
              stack.push v
              args = args.concat remaining
          else
            err 'parse error: type not mappable'
            process.exit 1
      when 'string'
        stack.push arg[1]
      when 'nonstring'
        switch arg[1]
          when 'true'   then stack.push true
          when 'false'  then stack.push false
          when 'null'   then stack.push null
          when 'array'  then stack.push []
          when 'object' then stack.push {}
          else err "parse error: illegal nonstring, \"#{argv[1]}\""; process.exit 1
      when 'extract'
        switch type it
          when 'array', 'object'
            stack.push it[arg[1]]
          else
            err "parse error: type '#{type it}' has no elements to extract"
            process.exit 1
      when 'insert'
        top = stack.pop()
        switch type top
          when 'array', 'object'
            if arg[1] == 'append' then top.push it
            else                       top[arg[1]] = it
            stack.push top
          else
            err "parse error: type '#{type it}' has no elements to extract"
            process.exit 1
      when 'delete'
        delete it[arg[1]]
        stack.push it
  if stack.length > 0
    if inplace and file != '-'
      fs.writeFile file, (JSON.stringify (dosort stack.pop()))
    else
      out (JSON.stringify (dosort stack.pop()))
  process.exit 0


# Read the input JSON and put it on the stack
if file == '-'
  if process.stdin.isTTY
    err "warning: nothing to read"
    run []
  else
    debug "# reading from STDIN"
    json = ""
    process.stdin.resume()
    process.stdin.setEncoding 'utf8'
    process.stdin.on 'data', (chunk) -> json += chunk
    process.stdin.on 'end', () ->
      if json.length > 0
        run [JSON.parse(json)]
      else
        err "warning: nothing to read"
        run []
else
  debug "# reading from file '#{file}'"
  fs.readFile file, 'utf8', (err,data) ->
    if err then throw err
    run [JSON.parse(data)]
