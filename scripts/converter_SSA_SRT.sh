!/bin/bash

Verifica se o número de argumentos é igual a 1
if [ $# -ne 1 ]; then
  echo "Uso: $0 <diretório ou arquivo>"
  exit 1
fi

input="$1"

Função para processar um arquivo
process_file() {
  source="$1"
  ssa_file="${source%.mkv}.ass"
  srt_file="${source%.mkv}.srt"
  
  Verifica se o arquivo SRT já existe
  if [ -f "$srt_file" ]; then
    echo "O arquivo SRT já existe para $source, pulando a extração e conversão."
  else
    Extrai a legenda SSA do arquivo de vídeo
    if [ -z "$subtitle_index" ]; then
        ffmpeg -i "$source" -vn -an -codec:s ass "$ssa_file"
	elif [ "$subtitle_index" -ne -1 ]; then
		ffmpeg -i "$source" -vn -an -map 0:s:"$subtitle_index" -codec:s ass "$ssa_file"
	fi
    
    Converte a legenda ASS para SRT e define o idioma
    ffmpeg -i "$ssa_file" -c:s srt -metadata:s:s:0 language=por "$srt_file"
    
    Apaga a legenda ASS correspondente
    rm "$ssa_file"
    
    echo "Legenda extraída e convertida para $srt_file"
  fi
}

function process_subtitle {
  source="$1"
  ssa_file="${source%.mkv}.ass"
	if [ "$manual_index" == 0 ]; then
		Automatizando a consulta do index da legenda
		subtitle_index=-1
		ffmpeg -y -i "$1" -map 0:s:m:language:por -c:s ass "$ssa_file"
	else
		Apresenta os idiomas e seus respectivos índices de legenda
		ffprobe -v error -show_entries stream=index:stream_tags=language -select_streams s -of csv=p=0 "$1"

		Armazena a entrada do usuário no índice da legenda
		echo "Informe o índice da legenda [Tecle ENTER para pular]:"
		read subtitle_index
	fi
}

function selectWithDefault() {

	local item i=0 numItems=$# 

	Print numbered menu items, based on the arguments passed.
	for item; do
		printf '%s\n' "$((++i))) $item"
	done >&2

	Prompt the user for the index of the desired item.
	while :; do
		printf %s "${PS3-#? }" >&2
		read -r index
		Make sure that the input is either empty or that a valid index was entered.
		[[ -z $index ]] && break
		(( index >= 1 && index <= numItems )) 2>/dev/null || { echo "Seleção inválida. Por favor, tente novamente." >&2; continue; }
		break
	done

	Output the selected item, if any.
	[[ -n $index ]] && printf %s "${@: index:1}"

}

Imprime a mensagem de prompt e chama a função de seleção personalizada.
echo "Gostaria de definir o index da legenda manualmente?"
options=('Sim' 'Não')
opt=$(selectWithDefault "${options[@]}")

Processa o item selecionado.
case $opt in
	'Sim') manual_index=1;;
	''|'Não') manual_index=0;;
esac

Verifica se o argumento é um diretório ou um arquivo
if [ -d "$input" ]; then
  Se for um diretório, pergunte ao usuário o que deseja fazer
  echo "Deseja apagar todas as legendas SRT no diretório (S) ou realizar a extração e conversão (E)?"
  read choice
  
  case "$choice" in
    S|s)
      Apagar todas as legendas SRT no diretório
      rm "$input"/*.srt
      echo "Legendas SRT apagadas no diretório."
      ;;
    E|e)
      Processa todos os arquivos no diretório
      for file in "$input"/*.mkv; do
        if [ -f "$file" ]; then
          process_subtitle "$file"
		  process_file "$file" "$subtitle_index"
        fi
      done
      ;;
    *)
      echo "Escolha inválida. Saindo."
      exit 1
      ;;
  esac
elif [ -f "$input" ]; then
  Se for um arquivo, processa o arquivo individualmente
  process_file "$input" "$subtitle_index"
else
  echo "O arquivo ou diretório especificado não existe."
  exit 1
fi
