#!/bin/bash

if [ $# -ne 1 ]; then
  echo "Uso: $0 <diretório ou arquivo>"
  exit 1
fi
input="$1"

process_file() {
  inputfile="$1"
  ssa_file="${inputfile%.mkv}.ass"
  srt_file="${inputfile%.mkv}.srt"
  
  if [ -f "$srt_file" ]; then
    echo "O arquivo SRT já existe para $inputfile, pulando a extração e conversão."
  else
    ffmpeg -i "$inputfile" -vn -an -codec:s ass "$ssa_file"
    ffmpeg -i "$ssa_file" -c:s srt "$srt_file"
    rm "$ssa_file"
    echo "Legenda extraída e convertida para $srt_file"
  fi
}

if [ -d "$input" ]; then
  echo "Deseja apagar todas as legendas SRT no diretório (S) ou realizar a extração e conversão (E)?"
  read choice
  
  case "$choice" in
    S|s)
      rm "$input"/*.srt
      echo "Legendas SRT apagadas no diretório."
      ;;
    E|e)
      for file in "$input"/*.mkv; do
        if [ -f "$file" ]; then
          process_file "$file"
        fi
      done
      ;;
    *)
      echo "Escolha inválida. Saindo."
      exit 1
      ;;
  esac
elif [ -f "$input" ]; then
  process_file "$input"
else
  echo "O arquivo ou diretório especificado não existe."
  exit 1
fi