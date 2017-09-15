# NOTE.TXT Command Line Interface

A simple cli for working with plain text notes, inspired by [todo.txt](https://github.com/ginatrapani/todo.txt-cli/).

# Installing

Just download `note.sh` to your computer. Type `note.sh -h` or `note.sh help` for more info on how to use it. 

# Usage

    note.sh [OPTIONS] ACTION [ARGUMENTS]


Notes get a filename PrefixTitle.Extension. All of this can be specified as input argument or option. When no title
is specified, the user is queried for one, unless the -n option is present. All notes get extension .txt by default,
and spaces in note names are replaced with underscores.

If no arguments are given, the last 10 opened notes are shown (`note.sh list history`), unless specified
otherwise using the -s option

## OPTIONS:

* -a      Also lists archived notes, i.e. notes in the subdirectory "Archive". Default is not to list those.
* -d      Set notes directory (default is ~/Notes)
* -f      Search full text and filenames instead of only filenames
* -g      Specify file name for saving note history (default is .notetxthistory). Useful when using multiple instances for e.g. home and work. Should normally be a hidden file (.filename)
* -h      Show short usage info
* -e EXT  Use extension EXT instead of .txt for new notes
* -i      Always insert date header in VIM and start in insert mode. If -i and -j are both not specified, user is queried
  -j      Never insert date header in VIM, and startin normal mode. If -i and -j are both not specified, user is queried
* -l SEARCHEXT Use string SEARCHEXT to determine extensions to list. Default is `.txt`. To specify multiple, use e.g. `.txt\|.md`
* -k NUMBER Number of files to save in the note history (see option -g). Default is 10.
* -m      With LIST action, only output the notes, do not query for opening.
* -n      Never query for title. If no title is specified as input, the prefix is the title.
* -o      Always open existing files immediately, don't query first
* -p      Prefix to use before title  (default is none). Accepts bash date sequences such as %Y, %y, %m etc. So `note.sh -p %Y%m%d_ add Title` creates a note 201604030_Title.txt
* -q      Query user for editor to use. If not specified, use vim. If specified, currently vim, notepad++ and more are listed. 
* -r      Do not use prefix. Specified title will be filename
* -s ACTION  Action to use when none is specified. Default is "list history"
* -t      Append a timestamp to the filename. Usefull when no title is specified. The filename will become PrefixTitle_Timestamp.Extension
* -u      Reverse sort order of file lists

## ACTIONS:

* add|a [TITLE]:
  Create a new note. TITLE is optional, if no title is given, user is queried for one.
* open|o [ITEM#] [QUERY] ["last"]: Open an existing note. The note number ITEM# corresponds to the number in the output of "note.sh list". If the argument is "last", the last opened note is opened. If the argument is another string, 
  a filename query is performed, and if this returns a single file, this file is opened.
* list|ls [QUERY] ["history" | "h" [N]]: Lists notes. Without argument, all notes in the notes directory are listed, including notes in subdirectories. If QUERY is given, only notes with QUERY in either the filename of content are shown. If the argument is "history" or "h", the files in the history are shown (see option -g). If a numerical argument N is passed after "history", the most recent N notes are shown.
* move|mv [QUERY] [FOLDER] move the files matching QUERY to FOLDER. Only filenames are searched, not content and directory names. User is queried before each move.
* help: Displays this help

## EXAMPLES

     $ note.sh add
     $ note.sh a title
     $ note.sh list
     $ note.sh ls query
     $ note.sh list history
     $ note.sh list history 5
     $ note.sh open
     $ note.sh o 22
     $ note.sh open last
     $ note.sh open 170913_p
     $ note.sh mv 170430_project Project
