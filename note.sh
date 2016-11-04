#!/bin/bash

#Set defaults:
Directory=~/Notes/
Extension='.txt'
Prefix=""
NoteHistoryFile=~/.notetxthistory
DefaultNoArguments='list history'

usage()
{
   cat << EOF
   usage: note.sh [-h] [-d directory] [-p prefix]  action [arguments]

   ACTIONS:
    add|a [title]
    open|o [ITEM#] ["last"]
    list|ls [query] ["history" | "h"]
    help
EOF
}

longhelp()
{
   cat << EOF
SYNOPSIS
   note.sh [-h] [-d directory] [-p prefix]  action [arguments]

DESCRIPTION
   creates, opens or lists notes
   if no title is given, user is queried for title. All notes get extension .txt, and spaces in note
      names are replaced with underscores.

   OPTIONS:
    -h      Show short usage info
    -d      Set notes directory (default is ~/Notes)
    -p      Prefix to use before title  (default is none). Accepts bash date sequences
            such as %Y, %y, %m etc. So "note.sh -p %Y%m%d_ add Title" creates a note 201604030_Title.txt

   ACTIONS:
    add|a [TITLE]
      Create a new note. TITLE is optional, if no title is given, user is queried for
      one.
    open|o [ITEM#] ["last"]
      Open an existing note. The note number ITEM# corresponds to the number in the output of
      "note.sh list". If the argument is "last", the last opened note is opened.
    list|ls [QUERY] ["history" | "h"]
      Lists notes. Without argument, all notes in the notes directory are listed, including notes in
      subdirectories. If QUERY is given, only notes with QUERY in either the filename of content are
      shown. If the argument is "history" or "h", the last 10 opened notes are shown.
    help
      Displays this help

EXAMPLES
    $ note.sh add
    $ note.sh a title
    $ note.sh list
    $ note.sh ls query
    $ note.sh ls last
    $ note.sh open
    $ note.sh o 22
    $ note.sh open last

CREDITS & COPYRIGHTS
   Copyright (C) 2016 Ronald Kaptein
   This software is distributed under the GPLv3, see https://www.gnu.org/licenses/gpl-3.0.html

SEE ALSO
   See https://bitbucket.org/ronaldk/note.txt-cli for more info
EOF
}

function add()
{
   Prefix=`date +$Prefix`
   cd $Directory

   if [ $# -eq 0 ]; then
      read -p "Title of note (leave empty for DateTime): " Title
      if [ "$Title" == "" ]; then
         Title=`date +%Y%m%dT%H%M%S`
      fi
      Title=$Prefix$Title
      File=$Title$Extension
   else
      #TODO: what to do with spaces in title/filename?
      Title=$Prefix"$@" 
      File=$Title$Extension
   fi

   FileWithoutSpaces=`echo $File |  sed 's/ /_/g' `
   if [[ "$File" != "$FileWithoutSpaces" ]]; then
      echo Replacing spaces: renaming $File to $FileWithoutSpaces
      File=$FileWithoutSpaces
   fi

   if [ -f "$File" ]; then
      echo "File $File already exists."
      read -p "Open existing file (y/n, default y)? " Openexisting
      if [ "$Openexisting" == "n" ]; then
         exit
      fi
   fi

   echo Opening $File
   openfile $File
}

function list()
{
   ShowAll=0
   ShowLast=0

   #Removing trailing / from Directory:
   Directory=`echo $Directory | sed 's/\(.*\)[-\/]$/\1/g' `

   cd $Directory

   #If no input, show all notes:
   if [ "$#" -eq 0 -o "$1" == "all" ]; then
      ShowAll=1
      echo Showing all notes in $Directory:
   else
      Query="$@"
   fi

   if [ "$Query" == "*" -o "$ShowAll" == "1" ]; then
      Files=`grep -R --color -l -i "" * | grep .txt | grep "/" | sort -u`
      Files2=`ls -R --format single-column *.txt 2> /dev/null`
      Files="$Files2
$Files"
      Files=`printf '%s\n' "${Files[@]}" `
   elif [ "$Query" == "history" -o "$Query" == "h" ]; then
      Files=`cat $NoteHistoryFile`
   else
      #Find in content:
      Files=`grep -R --color -l -i "$Query" * | grep .txt `
      #Find in file names. Sed is to remove leading ./ in find output
      Files2=`find -name "*${Query}*"| sed 's/.\/\(.*\)/\1/g'`
      Files="$Files
$Files2"
      Files=`printf '%s\n' "${Files[@]}" | sort -u`
   fi

   if [ "$Files" == "" ]; then
      echo Nothing found...
      exit
   fi

   SAVEIFS=$IFS
   IFS=$(echo -en "\n\b")
   select Line in $Files
   do
      File=$Line
     break
   done
   IFS=$SAVEIFS

   echo Opening $File
   openfile $File

}

function open(){

   cd $Directory
   
   if [ "$1" == "last" -o "$1" == "l" ]; then
      File=`head -1 $NoteHistoryFile`
      if [ "$File" == "" ];then 
         echo "No last file found"
         exit
      fi
   elif [ $# -eq 0 ]; then
      Files=`cat $NoteHistoryFile`

      SAVEIFS=$IFS
      IFS=$(echo -en "\n\b")
      select Line in $Files
      do
         File=$Line
         break
      done
      IFS=$SAVEIFS
   elif [ $# -gt 0 ]; then
      Files=`grep -R --color -l -i "" * | grep .txt | grep "/" | sort -u`
      Files2=`ls -R --format single-column *.txt 2> /dev/null`
      Files="$Files2
$Files"
      Files=`printf '%s\n' "${Files[@]}" `
      File=`echo "$Files" |  sed "${1}q;d" `
   fi

   echo Opening $File
   openfile $File
}

function openfile(){

   File="$*"

   read -p "Open with vim (default), notepad++ (np,n) or more (m)? " EditorQ

   if [ "$EditorQ" == "np" -o "$EditorQ" == "n" ]; then
      Winfile=`cygpath -w "$File"`
      /c/Program\ Files\ \(x86\)/Notepad++/notepad++.exe "$Winfile" &
   elif [ "$EditorQ" == "m" -o "$EditorQ" == "more" ]; then
      more "$File"
   else
      vim "$File"
      if [ ! -f "$File" ]; then
         echo "Note not saved, file $File not created"
         exit
      fi
   fi

   CheckExists=`grep -Fx "$File" $NoteHistoryFile`
   if [[ "$CheckExists" != "" ]]; then
      #File already in lastnotefile, move it to top
      LastFiles=`grep -vFx "$File" $NoteHistoryFile`
   else
      #trash oldest file in lastnotefile and add new file on top
      LastFiles=`head -9 $NoteHistoryFile`
   fi

   echo "$File" > $NoteHistoryFile
   echo "$LastFiles" >> $NoteHistoryFile

}

#MAIN#

while getopts “hd:lqp:” OPTION
do
   case $OPTION in
      h)
         usage
         exit 1
         ;;
      d)
         Directory=$OPTARG
         ;;
      l)
         Openlastnote=1
         ;;
      p)
         Prefix=$OPTARG
         ;;
      ?)
         usage
         exit
         ;;
   esac
done
shift $((OPTIND-1))

if [[ "$1" == "" ]]; then
   action=`echo $DefaultNoArguments | cut -d " " -f 1`
   arguments=`echo $DefaultNoArguments | cut -d " " -f 2-`
else
   action=$1
   shift
   arguments=$*
fi

if [ ! -f "$NoteHistoryFile" ]; then
   touch $NoteHistoryFile
fi

case $action in 
   add | a | new | n)
      add $arguments
      exit
      ;;
   list | find | ls | f)
      list $arguments
      exit
      ;;
   open | o)
      open $arguments
      exit 
      ;;
   help )
      longhelp
      exit 
      ;;
   *)
      echo unknown option $action
      echo
      usage
      exit
esac
