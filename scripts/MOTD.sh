#!/bin/bash
#MOTD

# Definir MOTD -> echo "/home/user/scripts/MOTD.sh" >> /etc/profile

ctrl_c_handler() {
    motd
}

trap ctrl_c_handler INT

if [ -z "$SESSION_FIRST_RUN" ]; then
	sleep 1
	source ~/.bashrc
	export SESSION_FIRST_RUN=1
fi

cancelar=1
esc=255
HEIGHT=15
WIDTH=40
CHOICE_HEIGHT=8
BACKTITLE=$(hostnamectl | awk -F ': ' '/Operating System/ {os=$2} /Architecture/ {arch=$2} END {print os, arch}' | awk '{print $1, $3, $4, $5}')
TITLE="Terminal - $HOSTNAME"
MENU="Escolha uma das seguintes opções:"

OPTIONS=(1 "Sessão padrão"
         2 "Sessão destacada"
         3 "Fechar sessão"
	 4 "Configurações"
         5 "Arquivos"
         6 "Energia"
         7 "Processos"
	 8 "Serviços")
		 
criar_dialogo() {
   dialog --title "$1" \
    --no-collapse \
    --ok-label "OK" \
    --msgbox "$comando" 15 50
}

opcoes_selecionadas=()

exibir_opcoes() {
    echo
    for i in "${!opcoes[@]}"; do
        echo "$((i+1))) ${opcoes[$i]}"
    done
	echo "$(( ${#opcoes[@]} + 1 ))) Todas as opções"
    echo
}

exibir_opcoes_selecionadas() {
	echo
    for i in "${!opcoes_selecionadas[@]}"; do
        echo "$((i+1))) ${opcoes_selecionadas[$i]}"
    done
	echo
}

executar_comando() {

    if [[ "${#opcoes_selecionadas[@]}" -eq 0 ]]; then
        echo "Nenhuma opção selecionada."
        return
    fi

	if [ "$contexto" = 'Aplicativos' ]; then
		comando="sudo systemctl $1"
	elif [ "$contexto" = 'Docker' ]; then
		comando="docker $1"
	fi
	
    for opcao in "${opcoes_selecionadas[@]}"; do
        comando+=" $opcao"
		if [ ! -z "$status" ]; then
			status=$(systemctl is-active "$opcao")
			echo "$opcao: $status"
		fi
    done
	
	if [ ! -z "$status" ]; then
		$comando >/dev/null 2>&1
	else
		$comando
	fi
    echo
}

function rodar_opcoes {
	exibir_opcoes
	read -rp "Escolha uma ou mais opções (ex: 1 2 4): " escolhas

	for escolha in $escolhas; do
		index=$((escolha-1))
		if [[ "$index" -ge 0 && "$index" -lt "${#opcoes[@]}" ]]; then
			opcoes_selecionadas+=("${opcoes[$index]}")
		elif [[ "$escolha" -eq $(( ${#opcoes[@]} + 1 )) ]]; then
			opcoes_selecionadas=("${opcoes[@]}")
			break
		fi
	done	
	clear
}

seletor() {
	local subtitulo=$1
	local titulo=$2
	shift
	local opcoes=("$@")

	if [ -z "$titulo" ]; then
		titulo="Título Padrão"
	elif [ -z "$subtitulo" ]; then
		subtitulo="Subtítulo Padrão"
	fi

	dialog \
	--backtitle "$subtitulo" \
	--title "$titulo" \
	--clear \
	--cancel-label "Retornar" \
	--menu "Escolha uma das seguintes opções:" $HEIGHT $WIDTH 4 \
	"${opcoes[@]}" \
	2>&1 1<&3
}
while true; do
	exec 3>&1
	seletor_base=$(DIALOG_ERROR=5 dialog --timeout 8 --clear \
					--backtitle "$BACKTITLE" \
					--title "$TITLE" \
					--clear \
					--cancel-label "Encerrar" \
					--menu "$MENU" \
					$HEIGHT $WIDTH $CHOICE_HEIGHT \
					"${OPTIONS[@]}" \
					3>&1 1>&2 2>&3)
	exit_status=$?
	exec 3>&-
	case $exit_status in
		$cancelar)
			clear 
			exit 1
			;;
		$esc)
			clear
			break
			;;
	esac
	
	clear

	case $seletor_base in
			1)
				exit 0
				;;
			2)
				bash -c 'screen -D -R' && exit 0
				;;
			3)
				kill -HUP $PPID
				;;	
			4)
				bash -c 'sudo orangepi-config' && exit 0
				;;				
			5)
				while true; do
					exec 3>&1
					seletor=$(dialog \
					--backtitle "Gerenciando arquivos" \
					--title "Arquivos" \
					--clear \
					--cancel-label "Retornar" \
					--menu "Escolha uma das seguintes opções:" $HEIGHT $WIDTH 7 \
					"1" "Gerenciador de Arquivos" \
					"2" "Sensor de Armazenamento" \
					"3" "MOCPlayer" \
					"4" "BorgBackup" \
					"5" "Timeshift" \
					"6" "Desfragmentar /home" \
					"7" "Listar partições" \
					2>&1 1<&3)
					exit_status=$?
					exec 3>&-
					case $exit_status in
						$cancelar )
							clear
							break
							;;
						$esc )
							clear
							exit 1
							;;
					esac
					case $seletor in
						1)
							mc
							break
							;;
						2)
							ncdu
							break
							;;
						3)
							mocp
							break
							;;
						4)
							screen -dm bash -c 'sudo $HOME/scripts/backup_borg.sh'
							screen -x
							break
							;;
						5)
							screen -dm bash -c 'sudo timeshift --create --rsync --scripted'
							screen -x
							break
							;;
						6)
							screen -dm bash -c 'sudo e4defrag /home'
							screen -x
							break
							;;
						7)
							comando=$(sudo blkid && lsblk)
							criar_dialogo "Partições disponíveis"
							;;
					esac
				done
				;;		
			6)
				while true; do
					exec 3>&1
					seletor=$(dialog \
					--title "Energia" \
					--clear \
					--cancel-label "Retornar" \
					--menu "" $HEIGHT $WIDTH 2 \
					"1" "Desligar" \
					"2" "Reiniciar" \
					2>&1 1<&3)
					exit_status=$?
					exec 3>&-
					case $exit_status in
						$cancelar )
							clear
							break
							;;
						$esc )
							clear
							exit 1
							;;
					esac
					case $seletor in
						1)
							echo "Desligando o servidor..."
							echo
							echo "[CTRL+C] para cancelar"
							sleep 3 && sudo shutdown -h now
							;;
						2)
							echo "Reiniciando o servidor..."
							echo
							echo "[CTRL+C] para cancelar"
							sleep 3 && sudo shutdown -r now
							;;
					esac
				done
				;;
			7)
				htop && exit 0
				;;
			8)
				while true; do
					exec 3>&1
					seletor=$(dialog \
					--backtitle "Gerenciando serviços" \
					--title "Serviços" \
					--clear \
					--cancel-label "Retornar" \
					--menu "Escolha uma das seguintes opções:" $HEIGHT $WIDTH 4 \
					"1" "Aplicativos" \
					"2" "Docker" \
					"3" "Bluetooth" \
					"4" "FFmpeg" \
					2>&1 1<&3)
					exit_status=$?
					exec 3>&-
					case $exit_status in
						$cancelar )
							clear
							break
							;;
						$esc )
							clear
							exit 1
							;;
					esac
					case $seletor in
						1)
							while true; do
								
								opcoes=("service1" "service2" "service3" "service4" "service5" "service6" "service7" "service8" "service9" "service10" "service11" "service12")
								contexto='Aplicativos'
								
								exec 3>&1
								seletor=$(dialog \
								--backtitle "Gerenciando aplicativos" \
								--title "Aplicativos" \
								--clear \
								--cancel-label "Retornar" \
								--menu "" $HEIGHT $WIDTH 4 \
								"1" "Rodar" \
								"2" "Reiniciar" \
								"3" "Parar" \
								"4" "Status" \
								2>&1 1<&3)
								exit_status=$?
								exec 3>&-
								case $exit_status in
									$cancelar )
										clear
										break
										;;
									$esc )
										clear
										exit 1
										;;
								esac
								
								case $seletor in
									1)
										opcoes_selecionadas=()
										rodar_opcoes
										executar_comando "start"
										break
										;;
									2)
										opcoes_selecionadas=()
										rodar_opcoes
										executar_comando "restart"
										break
										;;
									3)
										opcoes_selecionadas=()
										rodar_opcoes
										executar_comando "stop"
										break
										;;
									4)
										opcoes_selecionadas=()
										rodar_opcoes
										status=1
										comando=$(executar_comando "is-active")
										criar_dialogo "Status dos serviços selecionados"
										unset status
										break
										;;
								esac
							done
							;;
						2)
							while true; do
							
								opcoes=("container1" "container2" "container3" "container4" "container5")
								contexto='Docker'
							
								exec 3>&1
								seletor=$(dialog \
								--backtitle "Gerenciando o Docker" \
								--title "Docker" \
								--clear \
								--cancel-label "Retornar" \
								--menu "" $HEIGHT $WIDTH 5 \
								"1" "Rodar" \
								"2" "Reiniciar" \
								"3" "Parar" \
								"4" "Status" \
								"5" "Listar ativos" \
								2>&1 1<&3)
								exit_status=$?
								exec 3>&-
								case $exit_status in
									$cancelar )
										clear
										break
										;;
									$esc )
										clear
										exit 1
										;;
								esac
								
								case $seletor in
									1)
										opcoes_selecionadas=()
										rodar_opcoes
										executar_comando "start"
										break
										;;
									2)										
										opcoes_selecionadas=()
										rodar_opcoes
										executar_comando "restart"
										break
										;;
									3)
										opcoes_selecionadas=()
										rodar_opcoes
										executar_comando "stop"
										break
										;;
									4)
										opcoes_selecionadas=()
										rodar_opcoes
										executar_comando "stats"
										break
										;;
									5)
										comando=$(docker stats $(docker ps | awk '{print $1}' | tail -n+5 | tr '\n' ' ') --no-stream --format "table {{.Name}}\t{{.CPUPerc}}\t{{.MemUsage}}")
										criar_dialogo "Containers ativos"
										;;
									
								esac
							done
							;;
						3)
							while true; do
								
								exec 3>&1
								seletor=$(dialog \
								--backtitle "Gerenciando opções de Bluetooth" \
								--title "Bluetooth" \
								--clear \
								--cancel-label "Retornar" \
								--menu "" $HEIGHT $WIDTH 5 \
								"1" "Rodar serviços" \
								"2" "Parar serviços" \
								"3" "Status dos serviços" \
								"4" "Conectar à Alexa" \
								"5" "Conectar ao Headset" \
								2>&1 1<&3)
								exit_status=$?
								exec 3>&-
								case $exit_status in
									$cancelar )
										clear
										break
										;;
									$esc )
										clear
										exit 1
										;;
								esac
								
								bluetooth=$(sudo systemctl is-active bluetooth)
								pulseaudio=$(systemctl --user is-active pulseaudio)
								comando=$(echo;echo -e "📶 Bluetooth: ${bluetooth}\n🎵 PulseAudio: ${pulseaudio}")
								
								while true; do
									case $seletor in
										1)
											systemctl --user start pulseaudio
											sudo systemctl start bluetooth
											break
											;;
										2)
											sudo systemctl stop bluetooth >/dev/null 2>&1
											systemctl --user stop pulseaudio >/dev/null 2>&1
											break
											;;
										3)
											criar_dialogo "Status do Bluetooth"										
											break
											;;
										4)
											bash -c 'bluetoothctl connect 00:00:00:00:00:00'
											break
											;;
										5)
											bash -c 'bluetoothctl connect 01:01:01:01:01:01'
											break
											;;
									esac
								done
							done
							;;
						4)
							exec 3>&1
							seletor=$(dialog \
							--title "FFmpeg" \
							--clear \
							--cancel-label "Retornar" \
							--menu "" $HEIGHT $WIDTH 2 \
							"1" "Converter SSA para SRT" \
							"2" "Converter vídeos" \
							2>&1 1<&3)
							exit_status=$?
							exec 3>&-
							case $exit_status in
								$cancelar )
									clear
									break
									;;
								$esc )
									clear
									exit 1
									;;
							esac
							case $seletor in
								1)
									base="$HOME/Media/"
									[ ! -d "$base" ] && base="$HOME/.sym/"
									browser=$(dialog --stdout --title "Escolha um diretório ou vídeo para extrair a legenda SSA" --fselect "$base" $(expr $LINES - 15) $(expr $COLUMNS - 10))
									if [ -d "$browser" ]; then
										savepath=$(browser)
									elif [ -f "$browser" ]; then
										savepath=$(dirname "$browser")
									fi
									screen -dm bash -c "cd \"${savepath}\" && '$HOME/scripts/converter_SSA_SRT.sh' \"${browser}\""
									screen -x
									;;
								2)
									base="$HOME/Media/"
									[ ! -d "$base" ] && base="$HOME/.sym/"
									browser=$(dialog --stdout --title "Escolha um diretório ou vídeo para conversão" --fselect "$base" $(expr $LINES - 15) $(expr $COLUMNS - 10))
									if [ -d "$browser" ]; then
										savepath=$(browser)
									elif [ -f "$browser" ]; then
										savepath=$(dirname "$browser")
									fi
									screen -dm bash -c "cd \"${savepath}\" && '$HOME/scripts/converter_videos.sh' \"${browser}\""
									screen -x
									;;
								*)
									echo "Opção inválida"
									;;
							esac
					esac
				done
	;;
	esac
done

echo
DATE=`date +"%A, %e de %B de %Y"`
HOSTNAME=`hostname`
# Último Login
LAST1=`last -2 -a | awk 'NR==2{print $3}'`    # Dia da semana
LAST2=`last -2 -a | awk 'NR==2{print $5}'`    # Dia
LAST3=`last -2 -a | awk 'NR==2{print $4}'`    # Mês
LAST4=`last -2 -a | awk 'NR==2{print $6}'`    # Tempo
LAST5=`last -2 -a | awk 'NR==2{print $10}'`   # Host remoto
# Tempo de atividade
UP0=`cut -d. -f1 /proc/uptime`
UP1=$(($UP0/86400))     # Dias
UP2=$(($UP0/3600%24))   # Horas
UP3=$(($UP0/60%60))     # Minutos
UP4=$(($UP0%60))        # Segundos
if [ "$UP1" -gt "1" ]; then
	PL1=s
fi
if [ "$UP2" -gt "1" ]; then
	PL2=s
fi
if [ "$UP3" -gt "1" ]; then
	PL3=s
fi
if [ "$UP4" -gt "1" ]; then
	PL4=s
fi
# Carga média
LOAD1=`cat /proc/loadavg | awk '{print $1}'`    # Último Minuto
LOAD2=`cat /proc/loadavg | awk '{print $2}'`    # Últimos 5 Minutos
LOAD3=`cat /proc/loadavg | awk '{print $3}'`    # Últimos 15 Minutos
# Uso de disco HDD
DISK01=`df -h | grep '/dev/mapper/veracrypt1' | awk '{print $2}'`    # Total
DISK02=`df -h | grep '/dev/mapper/veracrypt1' | awk '{print $3}'`    # Usado
DISK03=`df -h | grep '/dev/mapper/veracrypt1' | awk '{print $5}'`    # Usado%
DISK04=`df -h | grep '/dev/mapper/veracrypt1' | awk '{print $4}'`    # Livre
DISK05=`df -h | grep '/dev/mapper/veracrypt2' | awk '{print $2}'`    # Total
DISK06=`df -h | grep '/dev/mapper/veracrypt2' | awk '{print $3}'`    # Usado
DISK07=`df -h | grep '/dev/mapper/veracrypt2' | awk '{print $5}'`    # Usado%
DISK08=`df -h | grep '/dev/mapper/veracrypt2' | awk '{print $4}'`    # Livre
# Memória RAM
RAM1=`free -h --si | grep 'Mem' | awk '{print $2}'`    # Total
RAM2=`free -h --si | grep 'Mem' | awk '{print $3}'`    # Usado
RAM3=`free -h --si | grep 'Mem' | awk '{print $7}'`    # Livre
# Temperatura
TEMP1=`sudo cat "/etc/orangepimonitor/datasources/soctemp" | sed 's/000//'`
TEMP2="ºC"
TEMP3=$TEMP1$TEMP2
echo -e "\033[1;36m"$(echo "$DATE" | sed 's/.*/\u&/')"\033[1;32m

Nome do Host..: \033[1;33m$HOSTNAME\033[1;32m
Tempo ativo...: \033[1;39m$UP1 dia$PL1, $UP2 hora$PL2 e $UP3 minuto$PL3\033[1;32m
Uso...........: \033[1;39m$LOAD1 (1 min) | $LOAD2 (5 min) | $LOAD3 (15 min)\033[1;32m
Armaz. HD1....: \033[1;39mTotal: $DISK01 | Usado: $DISK02($DISK03) | Livre: $DISK04\033[1;32m
Armaz. HD2....: \033[1;39mTotal: $DISK05 | Usado: $DISK06($DISK07) | Livre: $DISK08\033[1;32m
RAM (MB)......: \033[1;39mTotal: $RAM1 | Usado: $RAM2 | Livre: $RAM3 \033[1;32m
End. IP.......: \033[1;39m`ip a | grep glo | awk '{print $2}' | head -1 | cut -f1 -d/` | `wget -q -O - https://api.ipify.org/ | tail`\033[1;32m
Temperatura...: \033[1;39m$TEMP3\033[1;32m
Processos.....: \033[1;39m`ps ax | wc -l | tr -d " "`\033[1;32m
\033[m"
