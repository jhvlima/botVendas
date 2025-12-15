from dotenv import load_dotenv
import os

import requests
from telegram import Update, ReplyKeyboardMarkup, ReplyKeyboardRemove
from telegram.ext import (
    ApplicationBuilder,
    CommandHandler,
    MessageHandler,
    ContextTypes,
    ConversationHandler,
    filters
)
from datetime import datetime

load_dotenv()  # Carrega variáveis de ambiente do arquivo .env
WEBHOOK_URL = os.getenv("WEBHOOK_URL")
TOKEN = os.getenv("TELEGRAM_BOT_TOKEN")

# Etapas da conversa
PRODUTO, QUANTIDADE, PRECO, FORMA_PAGAMENTO, DATA = range(5)

# Opções fixas
produtos_disponiveis = ["Tradicional", "Café", "Oreo"]
quantidades_disponiveis = [str(i) for i in range(1, 11)]
preco_disponiveis = [str(i) for i in range(1, 11)]
formas_pagamento_disponiveis = ["Dinheiro", "Pix", "Outros"]

# Início
async def start(update: Update, context: ContextTypes.DEFAULT_TYPE):
    teclado = ReplyKeyboardMarkup([produtos_disponiveis], resize_keyboard=True, one_time_keyboard=True)
    await update.message.reply_text("📦 Qual produto foi vendido?", reply_markup=teclado)
    return PRODUTO

# Produto
async def receber_produto(update: Update, context: ContextTypes.DEFAULT_TYPE):
    context.user_data["produto"] = update.message.text
    teclado = ReplyKeyboardMarkup([quantidades_disponiveis], resize_keyboard=True, one_time_keyboard=True)
    await update.message.reply_text("🔢 Qual foi a quantidade vendida?", reply_markup=teclado)
    return QUANTIDADE

# Quantidade
async def receber_quantidade(update: Update, context: ContextTypes.DEFAULT_TYPE):
    context.user_data["quantidade"] = update.message.text
    teclado = ReplyKeyboardMarkup([preco_disponiveis], resize_keyboard=True, one_time_keyboard=True)
    await update.message.reply_text("💰 Qual foi o preço por unidade?", reply_markup=teclado)
    return PRECO

# Preço
async def receber_preco(update: Update, context: ContextTypes.DEFAULT_TYPE):
    context.user_data["preco"] = update.message.text
    teclado = ReplyKeyboardMarkup([formas_pagamento_disponiveis], resize_keyboard=True, one_time_keyboard=True)
    await update.message.reply_text("💳 Qual foi a forma de pagamento?", reply_markup=teclado)
    return FORMA_PAGAMENTO

# Forma de Pagamento
async def receber_forma_pagamento(update: Update, context: ContextTypes.DEFAULT_TYPE):
    context.user_data["forma_pagamento"] = update.message.text

    # Obtem data e hora atual
    data_hora_atual = datetime.now().strftime("%Y-%m-%d %H:%M:%S")
    context.user_data["data"] = data_hora_atual

    resumo = (
        f"✅ Venda registrada:\n\n"
        f"📦 Produto: {context.user_data['produto']}\n"
        f"🔢 Quantidade: {context.user_data['quantidade']}\n"
        f"💰 Preço unitário: R$ {context.user_data['preco']}\n"
        f"💳 Forma de pagamento: {context.user_data['forma_pagamento']}\n"
        f"🗓️ Data: {context.user_data['data']}"
    )
    await update.message.reply_text(resumo, reply_markup=ReplyKeyboardRemove())

    # Salva no CSV localmente
    with open("vendas.csv", "a") as f:
        f.write(f"{context.user_data['data']},{context.user_data['forma_pagamento']},{context.user_data['produto']},{context.user_data['quantidade']},{context.user_data['preco']}\n")

    # Envia para o Google Sheets
    payload = {
        "data": context.user_data['data'],
        "produto": context.user_data['produto'],
        "quantidade": context.user_data['quantidade'],
        "preco": context.user_data['preco'],
        "forma_pagamento": context.user_data['forma_pagamento']
    }
    try:
        requests.post(WEBHOOK_URL, json=payload)
    except Exception as e:
        print("Erro ao enviar para planilha:", e)

    return ConversationHandler.END

# Cancelamento
async def cancelar(update: Update, context: ContextTypes.DEFAULT_TYPE):
    await update.message.reply_text("❌ Operação cancelada. Você pode recomeçar a qualquer momento com /start.", reply_markup=ReplyKeyboardRemove())
    return ConversationHandler.END

# Bot Telegram
app = ApplicationBuilder().token(TOKEN).build()

conv_handler = ConversationHandler(
    entry_points=[CommandHandler("start", start)],
    states={
        PRODUTO: [MessageHandler(filters.TEXT, receber_produto), CommandHandler("cancelar", cancelar)],
        QUANTIDADE: [MessageHandler(filters.TEXT, receber_quantidade), CommandHandler("cancelar", cancelar)],
        PRECO: [MessageHandler(filters.TEXT, receber_preco), CommandHandler("cancelar", cancelar)],
        FORMA_PAGAMENTO: [MessageHandler(filters.TEXT, receber_forma_pagamento), CommandHandler("cancelar", cancelar)],
    },
    fallbacks=[CommandHandler("cancelar", cancelar)],
)

app.add_handler(conv_handler)

print("🤖 Bot rodando... Pressione Ctrl+C para parar.")
app.run_polling()
