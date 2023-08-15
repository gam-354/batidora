#!/bin/bash

function generate () {

  # Comprobar argumentos

  if [ $# -ne 4 ]; then
    echo "Usage:   generate  source_folder  segment_time_seconds  audio_preference  destination"
    echo ""
    echo "   audio_preference:  0 - remove"
    echo "                      1 - keep original audio track"
    echo "                      2 - convert to aac"
    echo ""
    echo "   destination:       output directory to write files in. It must exist."
    return
  fi

  SOURCE_FOLDER=$1
  TIME=$2
  AUDIO_PREFERENCE=$3
  DESTINATION=$4

  # Opciones de audio:

  AUDIO_OPTIONS="-an"

  if [ $AUDIO_PREFERENCE -eq 1 ]; then
  	AUDIO_OPTIONS="-c:a copy"
  elif [ $AUDIO_PREFERENCE -eq 2 ]; then
  	AUDIO_OPTIONS="-c:a aac -b:a 128k"
  fi

  VIDEO_OPTIONS="-vcodec mpeg4 -b:v 5000k -s 1920x1080 -r 30.00"

  OTHER_OPTIONS="-segment_time $TIME -f segment -reset_timestamps 1 -avoid_negative_ts make_zero -fflags +genpts"

  for file in ${SOURCE_FOLDER}* ; do
    inputFileName=$(basename "$file")
    outputFileName="${DESTINATION}/${inputFileName}_t_${TIME}_%04d.mp4"
    
    ./ffmpeg/bin/ffmpeg.exe -i "$file" -map 0 $VIDEO_OPTIONS $AUDIO_OPTIONS $OTHER_OPTIONS "$outputFileName"

    ((file_index++))
  done

}

function converter () {

	generate $1 100000 $3 $4
}


function concatenate () {

  # Comprobar argumentos

  if [ $# -ne 4 ]; then
    echo "Usage:  concatenate  folder  reencode  sound  output_filename"
    return
  fi

  FOLDER=$1
  REENCODE=$2
  KEEP_SOUND=$3
  OUTPUT_FILE=$4
  
  # Seleccionar videos y volcar en una lista:
  find $FOLDER -type f > concat_list.txt

  # Convertir la lista en una lista que ffmpeg entienda (añadir file ' '):
  OUTPUT_LIST="${OUTPUT_FILE}.txt" 
  awk '{print "file '"'"'" $0 "'"'"'";}' concat_list.txt > $OUTPUT_LIST 

  # Opciones de video:
  
  VIDEO_OPTIONS="-c:v copy"
  if [ $REENCODE -eq 1 ]; then
    VIDEO_OPTIONS="-c:v libx264 -r 30.00 -s 1920x1080 -preset slow -crf 22 -reset_timestamps 1 -avoid_negative_ts make_zero -fflags +genpts"
  fi

  # Opciones de audio

  AUDIO_OPTIONS="-an"

  if [ $KEEP_SOUND -eq 1 ]; then
    if [ $REENCODE -eq 1 ]; then AUDIO_OPTIONS="-acodec aac -b:a 128k"
                            else AUDIO_OPTIONS="-c:a copy"
    fi
  fi

  # Concatenar archivos 
  ./ffmpeg/bin/ffmpeg.exe -f concat -safe 0 -i $OUTPUT_LIST $VIDEO_OPTIONS $AUDIO_OPTIONS $OUTPUT_FILE

  # Borrar archivos temporales
  rm concat_list.txt

}


function remix () {

  # Comprobar argumentos

  if [ $# -ne 5 ]; then
    echo "Usage:  remix  folder  number_of_fragments  reencode  sound  output_filename"
    return
  fi

  FOLDER=$1
  NUM_VIDEOS=$2
  REENCODE=$3
  KEEP_SOUND=$4
  OUTPUT_FILE=$5
  
  # Seleccionar videos aleatoriamente y volcar en una lista:
  find $FOLDER -type f | shuf -n $NUM_VIDEOS > concat_list.txt

  # Convertir la lista en una lista que ffmpeg entienda (añadir file ' '):
  OUTPUT_LIST="${OUTPUT_FILE}.txt" 
  awk '{print "file '"'"'" $0 "'"'"'";}' concat_list.txt > $OUTPUT_LIST 

  # Opciones de video:
  
  VIDEO_OPTIONS="-c:v copy"
  if [ $REENCODE -eq 1 ]; then
    VIDEO_OPTIONS="-c:v libx264 -r 25 -preset slow -crf 22 -reset_timestamps 1 -avoid_negative_ts make_zero -fflags +genpts"
  fi

  # Opciones de audio

  AUDIO_OPTIONS="-an"

  if [ $KEEP_SOUND -eq 1 ]; then
    if [ $REENCODE -eq 1 ]; then AUDIO_OPTIONS="-acodec aac -b:a 128k"
                            else AUDIO_OPTIONS="-c:a copy"
    fi
  fi

  # Concatenar archivos 
  ./ffmpeg/bin/ffmpeg.exe -f concat -safe 0 -i $OUTPUT_LIST $VIDEO_OPTIONS $AUDIO_OPTIONS $OUTPUT_FILE

  # Borrar archivos temporales
  rm concat_list.txt

}

