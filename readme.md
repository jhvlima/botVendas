# Bot de Vendas para Telegram 🤖

## Descrição

Este projeto é um bot para Telegram que gerencia e apresenta dados de vendas a partir de uma planilha. Ele permite que os usuários consultem informações sobre vendas de forma rápida e prática através de comandos no Telegram.

## Funcionalidades

- **Consulta de Vendas:** Permite aos usuários consultar informações sobre as vendas.
- **Interação com Planilha:** Lê e processa dados de uma planilha `.csv`.
- **Comunicação via Telegram:** Utiliza a API do Telegram para enviar e receber mensagens.

## Tecnologias Utilizadas

- Python
- Biblioteca `telepot` para interação com a API do Telegram.
- Biblioteca `pandas` para manipulação de dados da planilha.

## Para o usuário

A ideia seria programar um bot no `Telegram` que automatize atualização de uma planilha de vendas.
Quando o bot idenficar que recebeu uma mensagem com o comando `/start` ele adicionara em uma planilha uma venda com:

- produto
- quantidade de produtos vendidos
- preço de cada produto
- vendedor
- data
- foto do comprovante de venda (opcional) ((nao implementado))

No Google Sheets: Planilha de Controle de Gastos – Palha Italiana na Faculdade

## Para o programador

O script deve estar rodando para contar as vendas. Deve criar um arquivo `.env` que tenha as variável de ambiente `TELEGRAM_BOT_TOKEN` e `WEBHOOK_URL`

Comandos para preparar o uso do bot:

```bash
sudo apt install python3.12-venv
python3 -m venv venv
source venv/bin/activate
pip install --upgrade pip
pip install -r requirements.txt
python3 meuScript.py
```
