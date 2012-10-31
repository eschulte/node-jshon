                 A node.js clone of https://github.com/keenerd/jshon
             likely incomplete, but basically functional, patches welcome

                     (the man page of the original jshon follows)

    JSHON(1)                         Jshon Manual                         JSHON(1)
    
    NAME
         jshon -- JSON parser for the shell
    
    SYNOPSIS
         jshon -[P|S|Q|V|C|I] [-F path] -[t|l|k|u|p|a] -[s|n] value -[e|i|d] index
    
    DESCRIPTION
         jshon parses, reads and creates JSON.  It is designed to be as usable as
         possible from within the shell and replaces fragile adhoc parsers made
         from grep/sed/awk as well as heavyweight one-line parsers made from
         perl/python.
    
         jshon loads json text from stdin, performs actions, then displays the
         last action on stdout.  Some of the options output json, others output
         plain text summaries.  Because Bash has very poor nested datastructures,
         jshon does not return the JSON as a native object as a typical library
         would.  Instead jshon retains a history of edits in a stack, and you
         manipulate the topmost JSON element.
    
    ACTIONS
         Each action takes the form of a short option.  Some require arguments.
         While many instances of jshon can be piped through each other, actions
         should be chained sequentially to reduce calls.  All examples use this
         json sample:
    
           {"a":1,"b":[true,false,null,"str"],"c":{"d":4,"e":5}}
           jshon [actions] < sample.json
    
         Most common read-only uses will only need several -e actions and one -a
         in the middle of them.
    
         -t  (type) returns string, object, array, number, bool, null
    
               jshon -t -> object
    
         -l  (length) returns an integer.  Only works on string, object, array.
    
               jshon -l -> 3
    
         -k  (keys) returns a newline separated list of keys.  Only works on
             object.
    
               jshon -k -> a b c
    
         -e index
             (extract) returns json value at "index".  Only works on object,
             array.
    
               jshon -e c -> {"d":4,"e":5}
    
         -a  (across) maps the remaining actions across the selected element.
             Only works on objects and arrays.  Multiple -a calls can be nested,
             though the need is rare in practice.
    
               jshon -e b -a -t -> bool bool null string
    
         -s value
             (string) returns a json encoded string.  Can later be (-i)nserted to
             an existing structure.
    
               jshon -s "back\slash" -> "back\\slash"
    
         -n value
             (nonstring/number) returns a json element.  Can later be (-i)nserted
             to an existing structure.  Valid values are 'true', 'false', 'null',
             'array', 'object', integers and floats.  Abbreviations t, f, n, []
             and {} respectively also work.
    
               jshon -n object -> {}
    
         -u  (unstring) returns a decoded string.  Only works on simple types:
             string, int, real, boolean, null.
    
               jshon -e b -e 3 -u -> str
    
         -p  (pop) pops the last manipulation from the stack, rewinding the his-
             tory.  Useful for extracting multiple values from one object.
    
              jshon -e c -e d -u -p -e e -u -> 4 5
    
         -d index
             (delete) removes an item in an array or object.  Negative array
             indexes will wrap around.
    
               jshon -d b -> {"a":1,"c":{"d":4,"e":5}}
    
         -i index
             (insert) is complicated.  It is the reverse of extract.  Extract puts
             a json sub-element on the stack.  Insert removes a sub-element from
             the stack, and inserts that bit of json into the larger array/object
             underneath.  Use extract to dive into the json tree,
             delete/string/nonstring to change things, and insert to push the
             changes back into the tree.
    
               jshon -e a -i a -> the orginal json
               jshon -s one -i a -> {"a":"one", ...}
    
             Arrays are handled in a special manner.  Passing integers will insert
             a value without overwriting.  Negative integers are acceptable, as is
             the string 'append'.  To overwrite a value in an array: delete the
             index, -n/s the new value, and then insert at the index.
    
               jshon -e b -d 0 -s q -i 0 -> {"b":"q",false,null,"str"}
    
    NON-MANIPULATION
         There are several meta-options that do not directly edit json.  Call
         these at most once per invocation.
    
         -F <path>
             (file) reads from a file instead of stdin.  The only non-manipulation
             option to take an argument.
    
         -P  (jsonp) strips a jsonp callback before continuing normally.
    
         -S  (sort) returns json sorted by key, instead of the original ordering.
    
         -Q  (quiet) disables error reporting on stderr, so you don't have to
             sprinkle "2> /dev/null" throughout your script.
    
         -V  (by-value) enables pass-by-value on the edit history stack.  In
             extreme cases with thousands of deeply nested values this may result
             in jshon running several times slower while using several times more
             memory.  However by-value is safer than by-reference and generally
             causes less surprise.  By-reference is enabled by default because
             there is no risk during read-only operations and generally makes
             editing json more convenient.
    
              jshon    -e c -n 7 -i d -p   -> c["d"] == 7
              jshon -V -e c -n 7 -i d -p   -> c["d"] == 5
              jshon -V -e c -n 7 -i d -i c -> c["d"] == 7
    
             With -V , changes must be manually inserted back through the stack
             instead of simply popping off the intermediate values.
    
         -C  (continue) on potentially recoverable errors.  For example, extract-
             ing values that don't exist will add 'null' to the edit stack instead
             of aborting.  Behavior may change in the future.
    
         -I  (in-place) file editing.  Requires a file to modify and so only works
             with -F.  This is meant for making slight changes to a json file.
             When used, normal output is suppressed and the bottom of the edit
             stack is written out.
    
         --version
             Returns a YYYYMMDD timestamp and exits.
    
    OTHER TOOLS
         jshon always outputs one field per line.  Many unix tools expect multiple
         tab separated fields per line.  Pipe the output through 'paste' to fix
         this.  However, paste can not handle empty lines so pad those with a
         placeholder.  Here is an example:
    
           jshon ... | sed 's/^$/-/' | paste -s -d '\t\t\n'
    
         This replaces blanks with '-' and merges every three lines into one.
    
    GOLF
         If you care about extremely short one liners, arguments can be condensed
         when it does not cause ambiguity.  The example from -p(op) can be golfed
         as follows:
    
          jshon -e c -e d -u -p -e e -u == jshon -ec -ed -upee -u
    
         I do not recommend doing this (it makes things much harder to understand)
         but some people golf despite the consequences.
    
    AUTHORS
         jshon was written by Kyle Keen <keenerd@gmail.com> with patches from Dave
         Reisner <d@falconindy.com>, AndrewF (BSD, OSX, jsonp, sorting), and
         Jean-Marc A (solaris).
    
    BUGS
         Numerous!  Forward slashes are never escaped.  Could be more convenient
         to use.  Documentation is brief.
    
    
                                    March 11, 2012
