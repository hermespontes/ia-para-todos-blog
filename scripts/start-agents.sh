#!/bin/bash

# Script para iniciar agentes autonomamente
# Este script inicia os agentes de criação e divulgação automaticamente

set -e

# Configurações
BLOG_DIR="$(pwd)"
AGENTS_DIR="$BLOG_DIR/agents"
LOG_DIR="$AGENTS_DIR/out"

# Cria diretório de logs se não existir
mkdir -p "$LOG_DIR"

# Função para iniciar agente de criação
echo "Iniciando agente de criação..."
$BLOG_DIR/scripts/publish-news.sh > "$LOG_DIR/creation_$(date +%Y%m%d_%H%M%S).log" 2&&

echo "Agente de criação iniciado com sucesso!"

# Função para iniciar agente de divulgação
echo "Iniciando agente de divulgação..."
# Aqui você pode adicionar scripts de divulgação nas redes sociais, etc.
echo "Divulgando as novas notícias..."

# Exemplo de divulgação (você pode personalizar)
echo "Divulgação automática em redes sociais..."
echo "- Postando no Twitter"
echo "- Enviando para Telegram"
echo "- Compartilhando no LinkedIn"

echo "Agente de divulgação iniciado com sucesso!"

# Verificação
echo "Verificando status dos agentes..."
echo "Agente de criação: $(ps aux | grep publish-news | grep -v grep | wc -l) processos ativos"
echo "Agente de divulgação: $(ps aux | grep social | grep -v grep | wc -l) processos ativos"

echo "Todos os agentes foram iniciados com sucesso!"