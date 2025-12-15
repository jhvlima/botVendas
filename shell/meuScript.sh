#!/bin/bash

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" &>/dev/null && pwd)"
botTOKEN=""

# Valida se o token está configurado
if [[ -z "${botTOKEN}" ]]; then
    echo "Erro: botTOKEN não configurado." >&2
    exit 1
fi

if [[ ! -f "${script_dir}/next_id.txt" ]]; then
    echo "0" >"${script_dir}/next_id.txt"
fi
 
offset=$(<"${script_dir}/next_id.txt")

while true; do
    updates="$(curl -s "https://api.telegram.org/bot${botTOKEN}/getUpdates?offset=${offset}")"
    if ! echo "$updates" | jq . >/dev/null 2>&1; then
        echo "Resposta inválida da API Telegram:" >&2
        echo "$updates" >&2
        sleep 2
        continue
    fi
    result="$(echo "$updates" | jq -c ".result")"

    if [[ "$result" == "[]" ]]; then
        sleep 1
        continue
    fi

    echo "$result" | jq -c '.[]' | while read -r update; do
        chat_id=$(echo "$update" | jq -r ".message.chat.id // empty")
        text=$(echo "$update" | jq -r ".message.text // empty")
        update_id=$(echo "$update" | jq -r ".update_id // empty")
        if [[ -z "$chat_id" || -z "$update_id" ]]; then
            continue
        fi
        offset=$((update_id + 1))
        echo "$offset" >"${script_dir}/next_id.txt"

        # Atualiza a planilha (adiciona uma linha com data, chat_id e texto)
        echo "$(date '+%Y-%m-%d %H:%M:%S'),$chat_id,\"$text\"" >> "${script_dir}/planilha.csv"

        case "$text" in
            "/venda")
                msg="Iniciando nova venda."
                ;;
            "/produto")
                msg="Qual produto foi vendido?"
                ;;
            "/quantidade")
                msg="Qual foi a quantidade vendida?"
                ;;
            "/finalizar")
                msg="Venda finalizada, bom trabalho."
                ;;
            *)
                msg="Comando não reconhecido."
                ;;
        esac

        curl -s -X POST -H 'Content-Type: application/json' \
            -d "{\"chat_id\": \"$chat_id\", \"text\": \"$msg\"}" \
            "https://api.telegram.org/bot${botTOKEN}/sendMessage" >/dev/null
    done
done
