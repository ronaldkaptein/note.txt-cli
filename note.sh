#!/bin/bash

#Set defaults:
Directory=~/Notes/
Extension='.txt'
Prefix=""
Lastnotefile=~/.notetxthistory
DefaultNoArguments='list last'

usage()
{
   cat << EOF
   usage: note.sh [-h] [-d directory] [-p prefix]  action [arguments]

   creates, opens or lists notes
   if no title is given, user is queried for title. All notes get extension .txt. 

   OPTIONS:
    -h      Show this message
    -d      Set notes directory (default is ~/Notes)
    -p      Prefix to use before title  (default is none). Accepts bash date sequences 
            such as %Y, %y, %m etc. So "note.sh -p %Y%m%d_ add Title" creates a note 201604030_Title.txt

   ACTIONS:
    add|o       Creates a new note. Takes title of note as argument. If no argument given, user is queried for one.
    open|o      Opens an existing note. Takes a number as argument, taken from the list action. If no argument, list with 10 last notes is shown.
                If argument is "last", last note is opened.
    list|ls     lists existing notes. Takes search query as argument. If query is "last", 10 last opened files are listed

   EXAMPLES
    note.sh add
    note.sh a title
    note.sh list 
    note.sh ls query
    note.sh ls last
    note.sh open
    note.sh o 22
    note.sh open last
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

   if [ -f "$File" ]; then
      echo "File $File already exists."
      read -p "Open existing file (y/n, default y)? " Openexisting
      if [ "$Openexisting" == "n" ]; then
         exit
      fi
   fi

   echo Opening $File
   openfile $File

   CheckExists=`grep -Fx "$File" $Lastnotefile`
   if [[ "$CheckExists" != "" ]]; then
      #File already in lastnotefile, move it to top
      LastFiles=`grep -vFx "$File" $Lastnotefile`
   else
      #trash oldest file in lastnotefile and add new file on top
      LastFiles=`head -9 $Lastnotefile`
   fi
   echo "$File" > $Lastnotefile
   echo "$LastFiles" >> $Lastnotefile
}

function list()
{
   Showall=0
   ShowLast=0

   #Removing trailing / from Directory:
   Directory=`echo $Directory | sed 's/\(.*\)[-\/]$/\1/g' `

   cd $Directory

   #If no input, show all notes:
   if [ "$#" -eq 0 -o "$1" == "all" ]; then
      Showall=1
      echo Showing all notes in $Directory:
   else
      Query="$@"
   fi

   if [ "$Query" == "*" -o "$Showall" == "1" ]; then
      Files=`grep -R --color -l -i "" * | grep .txt | grep "/" | sort -u`
      Files2=`ls -R --format single-column *.txt`
      Files="$Files2
$Files"
      Files=`printf '%s\n' "${Files[@]}" `
   elif [ "$Query" == "last" ]; then
      Files=`cat $Lastnotefile`
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
      File=`head -1 $Lastnotefile`
      if [ "$File" == "" ];then 
         echo "No last file found"
         exit
      fi
   elif [ $# -eq 0 ]; then
      Files=`cat $Lastnotefile`

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
      Files2=`ls -R --format single-column *.txt`
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

   CheckExists=`grep -Fx "$File" $Lastnotefile`
   echo $CheckExists
   if [[ "$CheckExists" != "" ]]; then
      #File already in lastnotefile, move it to top
      LastFiles=`grep -vFx "$File" $Lastnotefile`
   else
      LastFiles=`head -9 $Lastnotefile`
   fi
   echo "$File" > $Lastnotefile
   echo "$LastFiles" >> $Lastnotefile
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
   help | usage)
      usage
      exit 
      ;;
   *)
      echo unknown option $action
      echo
      usage
      exit
esac
