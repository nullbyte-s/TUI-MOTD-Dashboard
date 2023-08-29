#!/bin/bash

export BORG_PASSPHRASE="$(cat $HOME/.borg)"

backup_repo="$HOME/Backups/Borg"
num_backups=$(borg list "$backup_repo" | wc -l)
max_backups=8

if ((num_backups > max_backups)); then
    oldest_backup=$(borg list --short "$backup_repo" | head -n 1)
    echo "Removendo backup antigo: $oldest_backup"
    borg delete "$backup_repo::$oldest_backup"
fi

borg create --progress --one-file-system --compression zstd,9 "$backup_repo"::"{hostname}-{now:%Y-%m-%d}" "$HOME"

echo "Backups disponíveis:"
borg list "$backup_repo"


: <<'COMANDOS'

# Criar um repositório
borg init --encryption=repokey $HOME/Backups/Borg

# Testar a integridade do backup
borg check $HOME/Backups/Borg

# Exportar a chave do repositório de backup
borg key export $HOME/Backups/Borg chave-repositorio.txt

# Restaurar o arquivo de segunda-feira extraindo os arquivos relativos ao diretório atual
borg extract $HOME/Backups/Borg::Monday

# Excluir o arquivo de segunda-feira (observe que isso não libera espaço em disco do repositório)
borg delete $HOME/Backups/Borg::Monday

# Recuperar espaço em disco compactando os arquivos de segmento no repositório
borg compact $HOME/Backups/Borg

# Verificar a integridade do backup
borg check "$backup_repo"

# Restaurar o backup
borg extract "$backup_repo"::"{hostname}-{data.do.backup:YYYY-MM-DD}" /caminho/de/destino

COMANDOS