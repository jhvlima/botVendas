botTOKEN=""

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" &>/dev/null && pwd)"

if [ ! -f "${script_dir}/next_id.txt" ]; then
        touch "${script_dir}/next_id.txt"
        offset="0"
else
        offset=$(cat ${script_dir}/next_id.txt)

        if [ offset == " " ]; then
                offset="0"
        fi
fi

while true; do
        #result.message.chat.text
        updates="$(curl -s "https://api.telegram.org/bot${botTOKEN}/getupdates?offset=${offset}")"

        result="$(echo $updates | jq -r ".result")"
        error="$(echo $updates | jq -r ".description")"

        if [[ "${result}" == "[]" ]]; then
                exit 0
        elif [[ "${error}" != "null" ]]; then
                echo "${error}" && exit 0
        fi

        ## TRECHO DE GERAÇÃO DO JSON UPDATES ##
        echo $updates >>updates_.json
        jq . updates_.json >>updates.json
        rm updates_.json
        ## FIM DO TRECHO ##

        chat_id="$(echo $result | jq -r ".[].message.chat.id")"
        chat_id="$(echo ${chat_id} | cut -d " " -f1)"

        update_id="$(echo "$result" | jq -r ".[].update_id")"
        update_id="$(echo ${update_id} | cut -d " " -f1)"

        next_id="$((update_id + 1))"
        echo $next_id | cat >${script_dir}/next_id.txt
        offset=$next_id

        text="$(echo $result | jq -r ".[].message.text")"
        text="$(echo $text | cut -d " " -f1)"

        if [[ "${text}" == "/venda" ]]; then
                msg="Iniciou a conversa"
                echo "Iniciou a conversa" | cat >>${script_dir}/msg_log.txt
                exit 0
        fi

        if [[ "${text}" == "/produto" ]]; then
                msg="Qual produto foi vendido?"
                echo "Qual produto foi vendido?" | cat >>${script_dir}/msg_log.txt
                exit 0
        fi

        if [[ "${text}" == "/quantidade" ]]; then
                msg="Qual foi a quantidade vendida?"
                echo "Qual foi a quantidade vendida?" | cat >>${script_dir}/msg_log.txt
                exit 0
        fi

        if [[ "${text}" == "/vendedor" ]]; then
                msg="Qual vendedor realizou a venda?"
                echo "Qual vendedor realizou a venda?" | cat >>${script_dir}/msg_log.txt
                exit 0
        fi

        if [[ "${text}" == "/finalizar" ]]; then
                msg="Venda finalizada, bom trabalho"
                echo "Venda finalizada, bom trabalho" | cat >>${script_dir}/msg_log.txt
                exit 0
        fi

        if [[ "${text}" == "/cancelar" ]]; then
                msg="Venda cancelada"
                echo "Venda cancelada" | cat >>${script_dir}/msg_log.txt
                exit 0
        fi

        echo $msg_status | cat >>${script_dir}/msg_log.txt

        document_confirm="$(echo $result | jq -r ".[].message.document")"
        document_confirm="$(echo ${document_confirm} | cut -d " " -f1)"

        photo_confirm="$(echo $result | jq -r ".[].message.photo")"
        photo_confirm="$(echo ${photo_confirm} | cut -d " " -f1)"

        if [[ "${document_confirm}" != "null" ]]; then
                file_id="$(echo ${result} | jq -r ".[].message.document.file_id")"
                file_id="$(echo ${file_id} | cut -d " " -f1)"

                user_id="$(echo ${result} | jq -r ".[].message.chat.id")"
                user_id="$(echo ${user_id} | cut -d " " -f1)"

                file_json=$(curl -s https://api.telegram.org/bot${botTOKEN}/getFile?file_id=${file_id})
                file_path="$(echo ${file_json} | jq -r ".result.file_path")"

                ## TRECHO DE GERAÇÃO DO JSON FILEPATH ##
                echo $file_json >filepath_.json
                jq . filepath_.json >filepath.json
                rm filepath_.json
                ## FIM DO TRECHO ##

                application="$(echo ${file_path} | cut -d "." -f2)"

                if [[ ! -d "${script_dir}/${user_id}" ]]; then
                        mkdir ${script_dir}/$user_id
                fi

                message_flag="document"

                wget -q https://api.telegram.org/file/bot${botTOKEN}/${file_path} -O ${script_dir}/${user_id}/${update_id}.${application}
        elif [[ "${photo_confirm}" != "null" ]]; then
                file_id="$(echo ${result} | jq -r ".[].message.photo[].file_id")"
                file_id="$(echo ${file_id} | cut -d " " -f1)"

                user_id="$(echo ${result} | jq -r ".[].message.chat.id")"
                user_id="$(echo ${user_id} | cut -d " " -f1)"

                file_json=$(curl -s https://api.telegram.org/bot${botTOKEN}/getFile?file_id=${file_id})
                file_path="$(echo ${file_json} | jq -r ".result.file_path")"

                ## TRECHO DE GERAÇÃO DO JSON FILEPATH ##
                echo $file_json >filepath_.json
                jq . filepath_.json >filepath.json
                rm filepath_.json
                ## FIM DO TRECHO ##

                application="$(echo ${file_path} | cut -d "." -f2)"

                if [[ ! -d "${script_dir}/${user_id}" ]]; then
                        mkdir ${script_dir}/$user_id
                fi

                message_flag="photo"

                wget -q https://api.telegram.org/file/bot${botTOKEN}/${file_path} -O ${script_dir}/${user_id}/${update_id}.${application}
        fi

        msg="Mensagem genérica gerada pelo script."
        if [[ "${message_flag}" == "document" ]]; then
                msg="Olá, recebemos seu documento."
        elif [[ "${message_flag}" == "photo" ]]; then
                tesseract ${script_dir}/${user_id}/${update_id}.${application} ${script_dir}/${user_id}/${update_id}
                msg=$(cat ${script_dir}/${user_id}/${update_id}.txt)
        fi

        msg_status=$(curl -s -X POST -H 'Content-Type: application/json' \
                -d '{"chat_id": "'"${chat_id}"'", "text": "'"${msg}"'"}' \
                https://api.telegram.org/bot${botTOKEN}/sendMessage)
done
