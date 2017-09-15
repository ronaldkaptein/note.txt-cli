#!/bin/bash

#Set defaults:
Directory=~/Notes/
Extension='.txt'
ListExtensions='.txt'
Prefix=""
NoteHistoryFile=.notetxthistory
NoteHistoryN=10 #Number of notes to save in history file
DefaultNoArguments='list history'
QueryForEditor=0
ListArchivedNotes=0
ListOnly=0
CommandForNonText='cygstart'
Locale='nl_NL.utf8'
HeaderFormat="### %A %d %B %Y %H:%M"
SearchFulltext=0
AppendTimeStamp=0 #Append timestamp (Y%m%dT%H%M%S) to title.
AlwaysInsertHeader=0 #0=no, but ask, 1=yes and don't ask, -1 = no and don't ask
OpenExistingWithoutQuery=0 #If a note already exists, don't ask to open it
NeverQueryForTitle=0 #Don't ask for title. If no title is specified as input, only the prefix is used.
NoPrefix=0 #Do not use a prefix for the note title
SortOptions=""

usage()
{
   cat << EOF
   usage: note.sh [OPTIONS] ACTION [ARGUMENTS]

   ACTIONS:
    add|a [title]
    open|o [ITEM#] ["last"]
    list|ls [query] ["history" | "h" [N] ]
    move|mv [query] [folder]
    help
EOF
}

longhelp()
{
   cat << EOF
SYNOPSIS
   note.sh [OPTIONS] ACTION [ARGUMENTS]

DESCRIPTION
   creates, opens or lists notes

   Notes get a filename PrefixTitle.Extension. All of this can be specified as input argument or option. When no title
   is specified, the user is queried for one, unless the -n option is present. All notes get extension .txt by default,
   and spaces in note names are replaced with underscores.

   If no arguments are given, the last 10 opened notes are shown ("note.sh list history"), unless specified
   otherwise using the -s option

   OPTIONS:
    -a      Also lists archived notes, i.e. notes in the subdirectory "Archive". Default is not to list those.  
    -d      Set notes directory (default is ~/Notes)  
    -e EXT  Use extension EXT instead of .txt for new notes
    -f      Search full text and filenames instead of only filenames when using LIST
    -g      Specify file name for saving note history (default is .notetxthistory). Useful when using multiple
    instances for e.g. home and work. Should normally be a hidden file (.filename)
    -h      Show short usage info
    -i      Always insert date header in VIM and start in insert mode. If -i and -j are both not specified, 
            user is queried
    -j      Never insert date header in VIM, and start in normal mode. If -i and -j are both not specified, 
            user is queried
    -k NUMBER
            Number of files to save in the note history (see option -g). Default is 10.
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
    -t      Append a timestamp to the filename. Usefull when no title is specified. The filename will become PrefixTitle_Timestamp.Extension
    -u      Reverse sort order of file lists

   ACTIONS:
    add|a [TITLE]
      Create a new note. TITLE is optional, if no title is given, user is queried for
      one.
    open|o [ITEM#] [QUERY] ["last"]
      Open an existing note. The note number ITEM# corresponds to the number in the
      output of "note.sh list". If the argument is "last", the last opened note is opened. If the argument is
      another string, a filename query is performed, and if this returns a single file, this file is opened.
    list|ls [QUERY] ["history" | "h" [N]]
      Lists notes. Without argument, all notes in the notes directory are listed, including notes in
      subdirectories. If QUERY is given, only notes with QUERY in either the filename of content are
      shown. If the argument is "history" or "h", the files in the history are shown (see option -g). If a 
      numerical argument N is passed after "history", the most recent N notes are shown.
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
    $ note.sh list history
    $ note.sh list history 5
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

   Title="$@"

   if [[ $AppendTimeStamp == 1 ]]; then
     TitleWhenEmpty=$Prefix$Title_$(date +%Y%m%dT%H%M%S)
   else
     TitleWhenEmpty=$Prefix$Title
   fi

   if [[ $# -eq 0 ]] && [[ $NeverQueryForTitle == 0 ]]; then
      read -p "Title of note (leave empty for $TitleWhenEmpty): " Title
      if [ "$Title" == "" ]; then
         Title=$Prefix
      else
        Title=$Prefix$Title
      fi
   else
      Title=$Prefix"$@" 
   fi

   if [[ $AppendTimeStamp == 1 ]]; then
     Title="${Title}_$(date +%Y%m%dT%H%M%S)"
   fi

   File=$Title$Extension

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
   Num='^[0-9]+$'

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
      Files=`grep -R --color -l -i "" * | grep $ListExtensions | grep "/" | sort $SortOptions `
      Files2=`ls -R --format single-column *.* 2> /dev/null  | grep $ListExtensions`
      Files="$Files2
$Files"
      Files=`printf '%s\n' "${Files[@]}" | sort $SortOptions`
   elif [ "$Query" == "history" -o "$Query" == "h" ]; then
      Files=`cat $NoteHistoryFile`
      ListArchivedNotes=1 #Always show archived notes
   elif  [[ ("$(echo $Query | sed 's/ .*//')" == "history") && ( ! -z $(echo $Query | sed -n 's/^history \([0-9]*\)$/\1/p')) ]] || \
          [[ ("$(echo $Query | sed 's/ .*//')" == "h") && ( ! -z $(echo $Query | sed -n 's/^h \([0-9]*\)$/\1/p')) ]]; then
      N=`echo $Query | sed -n 's/^[a-z]* \([0-9]*\)$/\1/p'`
      Files=`head -$N $NoteHistoryFile`
      ListArchivedNotes=1 #Always show archived notes
   else
     if [[ $SearchFulltext == 1 ]]; then
       #Find in content:
       Files=`grep -R --color -l -i "$Query" * | grep $ListExtensions 2> /dev/null `
     else
       Files=''
     fi
     #Find in file names. Sed is to remove leading ./ in find output
      Files2=`find -name "*${Query}*"| sed 's/.\/\(.*\)/\1/g' 2> /dev/null`
      Files="$Files
$Files2"
      Files=`printf '%s\n' "${Files[@]}" | sort -u $SortOptions`
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
   elif [[ $# -gt 0 ]] && [[ $1 =~ $Num ]] && [[ $1 -lt 100000 ]]; then #Argument is number of note
      Files=`grep -R --color -l -i "" * | grep $ListExtensions | grep "/" | sort -u`
      Files2=`ls -R --format single-column *.* 2> /dev/null  | grep $ListExtensions`
      Files="$Files2
$Files"
      Files=`printf '%s\n' "${Files[@]}" | sort $SortOptions `
      if [[ $ListArchivedNotes == 0 ]]; then
        FilesHidden=`echo "$Files" | grep -E "^Archive/" | wc -l`
        Files=`echo "$Files" |  grep -v -E "^Archive/"  `
      else
        FilesHidden=0
      fi
      File=`echo "$Files" |  sed "${1}q;d" `
    else
      Query="$@"
      if [[ $SearchFulltext == 1 ]]; then
        #Find in content:
        Files=`grep -R --color -l -i "$Query" * | grep $ListExtensions 2> /dev/null `
      else
        Files=''
      fi
      Files2=`find -name "*${Query}*"| sed 's/.\/\(.*\)/\1/g' 2> /dev/null`
      Files=`echo "$Files
$Files2" | sed '/^\$*$/d' `
      Count=`echo "$Files" | sed '/^\$*$/d' |  wc -l`
      if [ "$Count" -gt "1" ]; then
        echo $Count matches found, please specify unique query
        exit
      elif [[ $Count == 0 ]]; then
        echo Nothing found...
        exit
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
      #File already in lastnotefile, remove it from list, and add it to top later
      LastFiles=`grep -vFx "$File" $NoteHistoryFile | head -$(echo "$NoteHistoryN -1" | bc)`
   else
      #trash oldest file in lastnotefile and add new file on top
      LastFiles=`head -$(echo "$NoteHistoryN -1" | bc) $NoteHistoryFile`
   fi

   #Add opened file to top:
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
  if [[ $AlwaysInsertHeader == 0 ]]; then
    read -p "insert date-time header and open in insert mode? " yn
  else
    yn=0
  fi

  if [[ $yn =~ [yY] ]] || [[ $AlwaysInsertHeader == 1 ]]; then
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

while getopts "afhmd:l:qp:e:g:s:tijonrk:u" OPTION
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
         ListExtensions=$OPTARG
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
        AppendTimeStamp=1
        ;;
      i)
        AlwaysInsertHeader=1
        ;;
      j)
        AlwaysInsertHeader=-1 #Meaning no and don't ask
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
      k)
        NoteHistoryN=$OPTARG
        ;;
      u)
        SortOptions="-r"
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
