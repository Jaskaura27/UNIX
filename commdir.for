#!/bin/sh

readonly real0="$(realpath -e "$0")"
readonly scriptDir="${real0%/*}"
. "$scriptDir/commdir.shared"

dir1=$1
dir2=$2

files=$(getAllFileNames $dir1 $dir2)


IFS='
'
status="0"
for file in $files; do
  case "$(classifyFile $dir1 $dir2 $file)" in
    "- $file") 
      echo "- $file"
      if [ "$status" -ne "2" ];then
        status="1"
      fi
      ;;
      
    "+ $file")
      echo "+ $file"
      if [ "$status" -ne "2" ];then
        status="1"
      fi
      ;;
        
   "x $file")
      echo "x $file"
      if [ "$status" -ne "2" ];then
        status="1"
      fi
      ;;
      
    "= $file")
      echo "= $file"
      ;;
    
    "! $file")
      echo "! $file"
      if [ "$status" -ne "2" ];then
        status="1"
      fi
      ;;
    
    "? $file")
      echo "? $file" 
      status="2"
      ;;
    
  esac

done


exit $status