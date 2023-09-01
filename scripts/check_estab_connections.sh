#!/bin/bash

while true
do
	# O condicional abaixo serve para verificar a carga de trabalho do processador. Se estiver acima de 10.5, ele executa o comando para parar os serviços. No entanto, não está completo, porque, se o processamento elevado for por motivo alheio à transcodificação, dentro de 100 segundos, os serviços serão reiniciados, gerando uma espécie de loop indesejado.
	#if (( $(echo "$(cat /proc/loadavg | awk '{print $1}') > 10.5" | bc -l) )) || [...]
    if [ -n "$(ss -n -o state established '( sport = :8096 or sport = :8920 or sport = :8200 )' | awk '$3 >= "10000" && $4 ~ "8096" || $3 >= "10000" && $4 ~ "8920" || $3 >= "10000" && $4 ~ "8200"')" ] && [ -n "$(pgrep -u user -x 'service1|service2|service3|service4|service5|service6' | tr -d '\n')" ]; then
        docker stop container1 container2 container3 container4
        sudo systemctl stop service1.service service2.service service3.service service4.service service5.service service6.service
	curl -s -X POST https://api.telegram.org/bot[XXXX]:[XXXX]/sendMessage -d chat_id=[XXXX] -d text="⛔️ Otimização contextual realizada"
        elif [ -z "$(ss -n -o state established '( sport = :8096 or sport = :8920 or sport = :8200 )' | awk '$4 ~ "8096" || $4 ~ "8920" || $3 >= "1000" && $4 ~ "8200"')" ] && [ -z "$(pgrep -u user -x 'service1|service2|service3|service4|service5|service6' | tr -d '\n')" ]; then
        docker start container1 container2 container3 container4
	bash -c 'sudo systemctl start service1.service service2.service service3.service service4.service service5.service service6.service' &
	curl -s -X POST https://api.telegram.org/bot[XXXX]:[XXXX]/sendMessage -d chat_id=[XXXX] -d text="✅ Serviços restaurados"
    fi
    sleep 100
done

: <<'CRIAR_SERVICO'
#1 Criando o arquivo de configurações do systemd
cat << EOF | sudo tee /etc/systemd/system/check_connections.service > /dev/null

[Unit]
Description=It checks if there are established connections and activates or deactivates applications accordingly, optimizing resources and providing stability
After=network.target

[Service]
ExecStart=/bin/bash /home/user/scripts/check_estab_connections.sh
Type=simple
User=user
Group=user
Restart=always
RuntimeMaxSec=481m
MemoryLimit=12M

[Install]
WantedBy=multi-user.target
EOF

#2 Recarregando o systemd
sudo systemctl -q daemon-reload

# Habilitando o serviço "check_connections"
sudo systemctl enable --now -q check_connections

CRIAR_SERVICO
