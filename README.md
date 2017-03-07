# NOTE.TXT Command Line Interface

A simple cli for working with plain text notes, inspired by [todo.txt](https://github.com/ginatrapani/todo.txt-cli/).

# Installing

Just download `note.sh` to your computer. Type `note.sh -h` or `note.sh help` for more info on how to use it. 

# Usage

note.sh [-h] [-d directory] [-p prefix] [-g historyfile] [-e extension] [-l listextension] 
[-q] [-a] action [arguments]

All notes get extension .txt by default, and spaces in note names are replaced with underscores.

If no arguments are given, the last 10 opened notes are shown (`note.sh list history`)

## OPTIONS:

-a      Also lists archived notes, i.e. notes in the subdirectory "Archive". Default is not to list those.
-g      Specify file name for saving note history (default is .notetxthistory). Useful when using multiple
instances for e.g. home and work. Should normally be a hidden file (.filename)
-h      Show short usage info
-e EXT  Use extension EXT instead of .txt for new notes
-l SEARCHEXT
Use string SEARCHEXT to determine extensions to list. Default is '.txt'. To specify multiple, 
use e.g. '.txt\|.md'
-d      Set notes directory (default is ~/Notes)
-p      Prefix to use before title  (default is none). Accepts bash date sequences
such as %Y, %y, %m etc. So "note.sh -p %Y%m%d_ add Title" creates a note 201604030_Title.txt
-q      Query user for editor to use. If not specified, use vim. If specified, currently vim, notepad++ and
more are listed. 

## ACTIONS:

* add|a [TITLE]: Create a new note. TITLE is optional, if no title is given, user is queried for one.
* open|o [ITEM#] ["last"]: Open an existing note. The note number ITEM# corresponds to the number in the output of "note.sh list". If the argument is "last", the last opened note is opened.
* list|ls [QUERY] ["history" | "h"]: Lists notes. Without argument, all notes in the notes directory are listed, including notes in subdirectories. If QUERY is given, only notes with QUERY in either the filename of content are shown. If the argument is "history" or "h", the last 10 opened notes are shown.
* help: Displays this help

## EXAMPLES

* $ note.sh add
* $ note.sh a title
* $ note.sh list
* $ note.sh ls query
* $ note.sh ls last
* $ note.sh open
* $ note.sh o 22
* $ note.sh open last
