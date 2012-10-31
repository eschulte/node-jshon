fs  = require 'fs'                                  # -*- coffee-tab-width:2 -*-

# global variables
version = 20121030
args  = []
file  = '-'

bail = (arg) ->
  process.stdout.write "jshon: invalid option -- '#{arg}'\n"
  process.stdout.write "Valid: -[P|S|Q|V|C|I] [-F path] -[t|l|k|u|p|a] -[s|n] value -[e|i|d] index\n"
  process.exit 1


# parse the arguments
argv = process.argv
argv.shift(); argv.shift();
while argv.length > 0
  arg = argv.shift()
  args.push switch arg
              when '-P' then ['jsonp',     0]
              when '-S' then ['sort',      0]
              when '-Q' then ['quiet',     0]
              when '-V' then ['by-value',  0]
              when '-C' then ['continue',  0]
              when '-I' then ['in-place',  0]
              when '-F' then file = argv.shift()
              when '-t' then ['type',      0]
              when '-l' then ['length',    0]
              when '-k' then ['keys',      0]
              when '-u' then ['unstring',  0]
              when '-p' then ['pop',       0]
              when '-a' then ['across',    0]
              when '-s' then ['string',    argv.shift()] # takes a value, encodes as json
              when '-n' then ['nonstring', argv.shift()] # takes [true, false, null, array, object, integer, float]
              when '-e' then ['extract',   argv.shift()] # takes an index (number or key)
              when '-i' then ['insert',    argv.shift()] # takes an index
              when '-d' then ['delete',    argv.shift()] # takes an index
              when '--version' then process.stdout.write "#{version}\n"; process.exit 0
              else bail arg


# read the JSON and put it on the stack
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
  process.stdout.write (JSON.stringify stack.shift())
  process.stdout.write '\n'
