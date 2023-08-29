# (...)

# Welcome Script
alias motd='~/scripts/MOTD.sh'

# List running services
alias running_services='systemctl list-units --type=service --state=running'

alias ctlsp="sudo systemctl stop"
alias ctlst="sudo systemctl start"
alias ctlrt="sudo systemctl restart"
alias ctlss="systemctl status"
alias ctlie="systemctl is-active"

# Archive with compressing (gzip)
targz ()
{
    tar -zcvf "$1.tar.gz" "$2"
}

# Unarchive in folder with archive name
untar ()
{
    tar -xvf "$1"
}

# Unarchive to specified path
untarto ()
{
    tar -xvf "$1" -C "$2"
}

# bash^M: bad interpreter
bad.cleaner ()
{
	sed -i -e 's/\r$//' "$1"
}

# reload bashrc
alias bashrc.reloader=". ~/.bashrc"

# forced close session to destroy current history
alias destroy="kill -9 $$"

# Clears all given entries in history
str.destroy ()
{
	local search="$1"
	echo
	history | grep "$search"
	echo

	echo "Apagar essas entradas?"
	select sn in "Sim" "Não"; do
		case $sn in
			Sim )
				while history -d $(history | grep "$search" | head -n 1 | awk {"print "'$'"1"}); do :;
					history -w
				done
				break
				;;
			Não )
				break
				;;
			* )
				echo "Entrada incorreta!"
				return
				;;
		esac
	done
}

# Identificar index correspondente a cada idioma de uma legenda em arquivo ou em vídeo
getindexsub ()
{
	ffprobe -v error -show_entries stream=index:stream_tags=language -select_streams s -of csv=p=0 "$1"
}

# Script para conversão de vídeos
alias vidconverter='~/bin/scripts/converter_videos.sh'

owner.manager ()
{
	sudo chown -R $1:$2 $3
}

permission.manager ()
{
	sudo chmod -R 775 $1
}

# Consultar IP público
alias ipv4='echo -e "$(wget -qO- https://api.ipify.org/)\n"'
alias ipv6='echo -e "$(wget -qO- https://api64.ipify.org)\n"'

# TCPTrack
alias connections="sudo tcptrack -i eth0"
alias established.connections="sudo netstat -nat | grep 'ESTABELECIDA'"