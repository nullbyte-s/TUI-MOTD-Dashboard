#!/bin/bash

function converter_video() {
	file="$1"
	#subtitle_index="$2"

	filename=$(basename "$file" .mkv)
	qualidade=$(echo "$filename" | awk -F'-' '{print $NF}')

	if [ "$qualidade" == "480p" ]; then
		echo "Arquivo já convertido para 480p: $file"
		return
	fi

	nome_sem_qualidade=$(echo "$filename" | sed "s/$qualidade//g")
	output_file="${nome_sem_qualidade%.*}480p.mkv"
	
	echo "Parando serviços para reduzir a carga da CPU..."
	cpulimit -e service10-nox -l 50 > /dev/null 2>&1 & disown
	sudo cpulimit -e service7 -l 40 > /dev/null 2>&1 & disown
	docker stop container1 container2 > /dev/null 2>&1
	sudo systemctl stop service11.service service12.service service6.service service1.service

    if [ -z "$subtitle_index" ]; then
        ffmpeg -y -i "$file" -vf "scale=-2:480" -c:v libx264 -b:v 6M -crf 28 -preset ultrafast -c:a aac -b:a 128k -sn "$output_file" & cpulimit -e ffmpeg -l 80
	elif [ "$subtitle_index" -ne -1 ]; then
		ffmpeg -y -i "$file" -vf "scale=-2:480,subtitles='$file':stream_index=$subtitle_index" -c:v libx264 -preset ultrafast -crf 30 -maxrate 1M -bufsize 2M -c:a aac -b:a 128k -sn "$output_file" & cpulimit -e ffmpeg -l 80
    else
		ffmpeg -y -i "$file" -vf "scale=-2:480,subtitles=sub.mkv" -c:v libx264 -preset ultrafast -crf 30 -maxrate 1M -bufsize 2M -c:a aac -b:a 128k -sn "$output_file" & cpulimit -e ffmpeg -l 80
		rm "sub.mkv"
    fi
	
	if [ $? -eq 0 ]; then
		echo "Vídeo convertido com sucesso: $file"
	else
		echo "Erro ao converter o vídeo: $file"
	fi
}

function process_subtitle {

	if [ "$manual_index" == 0 ]; then
		subtitle_index=-1
		ffmpeg -y -i "$1" -map 0:s:m:language:por -c:s mov_text -c copy sub.mkv
	else
		ffprobe -v error -show_entries stream=index:stream_tags=language -select_streams s -of csv=p=0 "$1"

		echo "Informe o índice da legenda [Tecle ENTER para pular]:"
		read subtitle_index
	fi
}

function restoreServices {
	sleep 3 && clear
	echo "Reiniciando os serviços de rotina..."
	sleep 15
	sudo pkill cpulimit
	sudo systemctl start service6.service service1.service
	sleep 45
	sudo systemctl start service11.service service12.service
}

function selectWithDefault() {

	local item i=0 numItems=$# 

	for item; do
		printf '%s\n' "$((++i))) $item"
	done >&2

	while :; do
		printf %s "${PS3-#? }" >&2
		read -r index
		[[ -z $index ]] && break
		(( index >= 1 && index <= numItems )) 2>/dev/null || { echo "Seleção inválida. Por favor, tente novamente." >&2; continue; }
		break
	done

	[[ -n $index ]] && printf %s "${@: index:1}"

}

source="$1"
#subtitle_index="$2"

echo "Gostaria de definir o index da legenda manualmente?"
options=('Sim' 'Não')
opt=$(selectWithDefault "${options[@]}")

case $opt in
	'Sim') manual_index=1;;
	''|'Não') manual_index=0;;
esac

if [ ! -e "$source" ]; then
	echo "O arquivo ou diretório $source não existe."
	return 1
fi

if [ -d "$source" ]; then
	for file in "$source"/*.mkv; do
		if [ -f "$file" ]; then
			process_subtitle "$file"
			converter_video "$file" "$subtitle_index"
		fi
	done
	restoreServices
elif [ -f "$source" ]; then
	process_subtitle "$source"
	converter_video "$source" "$subtitle_index"
	restoreServices
fi

: <<'COMANDOS'

# Exemplo de uso 1: converter todos os vídeos em /caminho/do/diretorio, incorporando a legenda de índice 0
converter_videos "/caminho/do/diretorio" 0

# Exemplo de uso 2: converter um único vídeo, incorporando a legenda de índice 1
converter_videos "/caminho/do/video.mp4" 1

# Ver index de legenda embutida em arquivo de vídeo:
ffprobe -v error -select_streams s -show_entries stream=index:stream_tags=language -of default=noprint_wrappers=1:nokey=1 video.mkv

# Automatizando a consulta de index da legenda
indexes=($(ffprobe -v error -show_entries stream=index:stream_tags=language -select_streams s -of csv=p=0 "$file" | tr ',' ' '))
last_index=${indexes[-2]}
por_index=$(ffprobe -v error -show_entries stream=index:stream_tags=language -select_streams s -of csv=p=0 "$file" | grep ",por$" | cut -d',' -f1)
result=$((last_index - por_index))

COMANDOS
