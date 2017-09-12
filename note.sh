#!/bin/bash

#Set defaults:
Directory=~/Notes/
Extension='.txt'
GrepExtension='.txt'
Prefix=""
NoteHistoryFile=.notetxthistory
DefaultNoArguments='list history'
QueryForEditor=0
ListArchivedNotes=0
ListOnly=0
CommandForNonText='cygstart'
Locale='nl_NL.utf8'
HeaderFormat="### %A %d %B %Y %H:%M"
SearchFulltext=0
InsertTimeStampIfNoTitle=0
AlwaysInsertDateHeader=0 #0=no, but ask, 1=yes and don't ask, -1 = no and don't ask
OpenExistingWithoutQuery=0
NeverQueryForTitle=0
NoPrefix=0

usage()
{
   cat << EOF
   usage: note.sh [-h] [-d directory] [-p prefix] [-g historyfile] [-e extension] [-l listextension] 
          [-q] [-a] [-m] [-f] [-i] [-j] [-o] [-n] [-r] action [arguments]

   ACTIONS:
    add|a [title]
    open|o [ITEM#] ["last"]
    list|ls [query] ["history" | "h"]
    move|mv [query] [folder]
    help
EOF
}

longhelp()
{
   cat << EOF
SYNOPSIS
   note.sh [-h] [-d directory] [-p prefix] [-g historyfile] [-e extension] [-l listextension] 
          [-q] [-a] [-m] [-f] [-i] [-j] [-n] [-o] [-r] action [arguments]

DESCRIPTION
   creates, opens or lists notes

   All notes get extension .txt by default, and spaces in note names are replaced with underscores.

   If no arguments are given, the last 10 opened notes are shown ("note.sh list history"), unless specified
   otherwise using the -s option

   OPTIONS:
    -a      Also lists archived notes, i.e. notes in the subdirectory "Archive". Default is not to list those.
    -d      Set notes directory (default is ~/Notes)
    -e EXT  Use extension EXT instead of .txt for new notes
    -f      Search full text and filenames instead of only filenames
    -g      Specify file name for saving note history (default is .notetxthistory). Useful when using multiple
    instances for e.g. home and work. Should normally be a hidden file (.filename)
    -h      Show short usage info
    -i      Always insert date header in VIM and start in insert mode. If -i and -j are  both not specified, 
            user is queried
    -j      Never insert date header in VIM, and startin normal mode. If -i and -j are  both not specified, 
            user is queried
    -l SEARCHEXT
            Use string SEARCHEXT to determine extensions to list. Default is '.txt'. To specify multiple, 
            use e.g. '.txt\|.md'. To list all files, use '.'
    -m      With LIST action, only output the notes, do not query for opening.
    -n      Never query for title. If no title is specified as input, the prefix is the title.
    -o      Always open existing files immediately, don't query first
    -p      Prefix to use before title  (default is none). Accepts bash date sequences
            such as %Y, %y, %m etc. So "note.sh -p %Y%m%d_ add Title" creates a note 201604030_Title.txt
    -q      Query user for editor to use. If not specified, use vim. If specified, currently vim, notepad++ and
            more are listed. 
    -r      Do not use prefix. Specified title will be filename
    -s ACTION
            Action to use when none is specified. Default is "list history"
    -t      Insert a timestamp in the filename when no title is specified

   ACTIONS:
    add|a [TITLE]
      Create a new note. TITLE is optional, if no title is given, user is queried for
      one.
    open|o [ITEM#] [QUERY] ["last"]: Open an existing note. The note number ITEM# corresponds to the number in the
       output of "note.sh list". If the argument is "last", the last opened note is opened. If the argument is
       another string, a filename query is performed, and if this returns a single file, this file is opened.
    list|ls [QUERY] ["history" | "h"]
      Lists notes. Without argument, all notes in the notes directory are listed, including notes in
      subdirectories. If QUERY is given, only notes with QUERY in either the filename of content are
      shown. If the argument is "history" or "h", the last 10 opened notes are shown.
    move|mv [QUERY] [FOLDER] 
      move the files matching QUERY to FOLDER. Only filenames are searched, not content and directory
      names. User is queried before each move.
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
    $ note.sh open 170913_p
    $ note.sh mv 170430_project Project

CREDITS & COPYRIGHTS
   Copyright (C) 2016-2017 Ronald Kaptein
   This software is distributed under the GPLv3, see https://www.gnu.org/licenses/gpl-3.0.html

SEE ALSO
   https://github.com/ronaldkaptein/note.txt-cli
EOF
}

function add()
{
   if [[ ! -z $Prefix ]] && [[ $NoPrefix == 0 ]]; then
     Prefix=`LC_ALL=$Locale date +$Prefix`
   else
     Prefix=""
   fi
   cd $Directory

   if [[ $InsertTimeStampIfNoTitle == 1 ]]; then
     TitleWhenEmpty=$Prefix$(date +%Y%m%dT%H%M%S)
   else
     TitleWhenEmpty=$Prefix
   fi

   if [[ $# -eq 0 ]] && [[ $NeverQueryForTitle == 0 ]]; then
      read -p "Title of note (leave empty for $TitleWhenEmpty): " Title
      if [ "$Title" == "" ]; then
         Title=$TitleWhenEmpty
      else
        Title=$Prefix$Title
      fi
      File=$Title$Extension
   else
      Title=$Prefix"$@" 
      File=$Title$Extension
   fi

   FileWithoutSpaces=`echo $File |  sed 's/ /_/g' `
   if [[ "$File" != "$FileWithoutSpaces" ]]; then
      echo Replacing spaces: renaming $File to $FileWithoutSpaces
      File=$FileWithoutSpaces
   fi

   if [[ -f "$File" ]] && [[ $OpenExistingWithoutQuery == 0 ]]; then
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
      echo Showing notes in $Directory:
   else
      Query="$@"
   fi

   if [ "$Query" == "*" -o "$ShowAll" == "1" ]; then
      Files=`grep -R --color -l -i "" * | grep $GrepExtension | grep "/" | sort -u `
      Files2=`ls -R --format single-column *.* 2> /dev/null  | grep $GrepExtension`
      Files="$Files2
$Files"
      Files=`printf '%s\n' "${Files[@]}" `
   elif [ "$Query" == "history" -o "$Query" == "h" ]; then
      Files=`cat $NoteHistoryFile`
      ListArchivedNotes=1 #Always show archived notes
   else
     if [[ $SearchFulltext == 1 ]]; then
       #Find in content:
       Files=`grep -R --color -l -i "$Query" * | grep $GrepExtension 2> /dev/null `
     else
       Files=''
     fi
     #Find in file names. Sed is to remove leading ./ in find output
      Files2=`find -name "*${Query}*"| sed 's/.\/\(.*\)/\1/g' 2> /dev/null`
      Files="$Files
$Files2"
      Files=`printf '%s\n' "${Files[@]}" | sort -u`
   fi

   if [[ $ListArchivedNotes == 0 ]]; then
      FilesHidden=`echo "$Files" | grep -E "^Archive/" | wc -l`
      Files=`echo "$Files" |  grep -v -E "^Archive/"  `
   else
      FilesHidden=0
   fi

   if [ "$Files" == "" ]; then
      if [[ $FilesHidden == 0 ]]; then
         echo Nothing found...
      elif [[ $FilesHidden == 1 ]]; then
         echo "Nothing found ($FilesHidden archived file matches, use -a to show)"
      else
         echo "Nothing found ($FilesHidden archived files match, use -a to show)"
      fi
      exit
   fi

   if [[ $ListOnly == 1 ]]; then
     echo "$Files"
   else
     if [[ $ListArchivedNotes == 1 ]]; then
       PS3='Choose file: '
     else
       PS3="Choose files ($FilesHidden archived files hidden): "
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
   fi

 }

function open(){
  Num='^[0-9]+$'
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
   elif [[ $# -gt 0 ]] && [[ $1 =~ $Num ]] && [[ "$1" < "100000" ]]; then #Argument is number of note
      Files=`grep -R --color -l -i "" * | grep $GrepExtension | grep "/" | sort -u`
      Files2=`ls -R --format single-column *.* 2> /dev/null  | grep $GrepExtension`
      Files="$Files2
$Files"
      Files=`printf '%s\n' "${Files[@]}" `
      if [[ $ListArchivedNotes == 0 ]]; then
        FilesHidden=`echo "$Files" | grep -E "^Archive/" | wc -l`
        Files=`echo "$Files" |  grep -v -E "^Archive/"  `
      else
        FilesHidden=0
      fi
      File=`echo "$Files" |  sed "${1}q;d" `
    else
      Query="$@"
      Files=`find -name "*${Query}*"| sed 's/.\/\(.*\)/\1/g' 2> /dev/null`
      Count=`echo "$Files" | wc -l`
      if [ "$Count" -gt "1" ]; then
        echo $Count matches found, please specify unique query
      else
        File=$Files
      fi
   fi

   echo Opening $File
   openfile $File
}

function openfile(){

   File="$*"

   if [[ $QueryForEditor == 1 ]]; then
      read -p "Open with vim (default), notepad++ (np,n) or more (m)? " EditorQ

      if [ "$EditorQ" == "np" -o "$EditorQ" == "n" ]; then
         Winfile=`cygpath -w "$File"`
         /c/Program\ Files\ \(x86\)/Notepad++/notepad++.exe "$Winfile" &
      elif [ "$EditorQ" == "m" -o "$EditorQ" == "more" ]; then
         more "$File"
      else
         openinvim "$File"
         if [ ! -f "$File" ]; then
            echo "Note not saved, file $File not created"
            exit
         fi
      fi
   else
      openinvim "$File"
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

function openinvim(){
  File=$*
  FileType=`file "$File" | cut -d: -f2 | cut -d \  -f2`
  if [[ -f $File ]] && [[ ! $FileType = "ASCII" ]] && [[ ! $FileType = "UTF-8" ]]; then
    echo "File is not a plain text file. Opening using $CommandForNonText"
    $CommandForNonText "$File"
    exit
  fi
  if [[ $AlwaysInsertDateHeader == 0 ]]; then
    read -p "insert date-time header and open in insert mode? " yn
  else
    yn=0
  fi

  if [[ $yn =~ [yY] ]] || [[ $AlwaysInsertDateHeader == 1 ]]; then
    if [ -f "$File" ]; then #Insert empty line when file already exists
      LastLine=`tail -1 "$File"`
      if [[ ! -z "${LastLine// }" ]]; then
        echo "" >> "$File"
      fi
    fi
    echo `LC_ALL=$Locale date +"$HeaderFormat"` >> "$File"
    vim -c ":normal Go" "$File"
    exit
  fi
  vim "$File"
}

function move(){
  Query="$1"
  Folder="$2"

  #Removing trailing / from Directory:
  Directory=`echo $Directory | sed 's/\(.*\)[-\/]$/\1/g' `
  cd $Directory

  #Check and create directory if necessary:
  if [[ -f "$Folder" ]]; then
    echo "ERROR: $Folder is an existing file"
    exit
  elif [[ ! -d "$Folder" ]]; then #Directory does not exist
    read -p "The directory \"$Folder\" does not exist. Create it? " yn
    case $yn in
      [Yy]* ) 
          mkdir -p "$Folder"
          ;;
      [Nn]* ) 
        exit
        ;;
      * ) echo "Please answer yes or no.";;
    esac
  fi

  #Find in file names. Sed is to remove leading ./ in find output
  Files=`find -name "*${Query}*"| sed 's/.\/\(.*\)/\1/g' 2> /dev/null`
  Files=`printf '%s\n' "${Files[@]}" | sort -u`

  SAVEIFS=$IFS
  IFS=$(echo -en "\n\b")
  for File in $Files
  do
    if [[ "$Folder" == "." ]]; then
      read -p "Move $File to /Notes ? " yn
    else
      read -p "Move $File to /Notes/$Folder? " yn
    fi
    case $yn in
      [Yy]* ) 
          ;;
      [Nn]* ) 
        echo Skipping "$file"
        continue;;
      * ) echo "Please answer yes or no.";;
    esac
    mv "$File" --target-directory="$Folder"
  done
  IFS=$SAVEIFS
}

#MAIN#

while getopts “afhmd:l:qp:e:g:s:tijonr” OPTION
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
         GrepExtension=$OPTARG
         ;;
      p)
         Prefix=$OPTARG
         ;;
      e) 
         Extension=$OPTARG
         ;;
      g)
         NoteHistoryFile=$OPTARG
         ;;
      q)
         QueryForEditor=1
         ;;
      a)
         ListArchivedNotes=1
         ;;
      m)
         ListOnly=1;
         ;;
      f)
        SearchFulltext=1;
        ;;
      s)
        DefaultNoArguments=$OPTARG
        ;;
      t)
        InsertTimeStampIfNoTitle=1
        ;;
      i)
        AlwaysInsertDateHeader=1
        ;;
      j)
        AlwaysInsertDateHeader=-1 #Meaning no and don't ask
        ;;
      o)
        OpenExistingWithoutQuery=1
        ;;
      n)
        NeverQueryForTitle=1
        ;;
      r)
        NoPrefix=1
        ;;
      ?)
         usage
         exit
         ;;
   esac
done
shift $((OPTIND-1))

NoteHistoryFile="$HOME/$NoteHistoryFile"

if [[ "$1" == "" ]]; then
   action=`echo $DefaultNoArguments | cut -d " " -f 1`
   arguments=`echo $DefaultNoArguments | cut -s -d " " -f 2-`
else
   action=$1
   shift
   arguments="$@"
fi

#Check extension
ExtensionStart=`echo $Extension | cut -c 1`
if [ "$ExtensionStart" != "." ]; then
   Extension=`echo ".$Extension"`
fi

if [ ! -f "$NoteHistoryFile" ]; then
   touch "$NoteHistoryFile"
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
    move | mv)
      if [ ! -z "$3" ]; then
        echo ERROR: too many arguments passed
        echo
        usage
        exit
      fi

      move "$1" "$2"
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
