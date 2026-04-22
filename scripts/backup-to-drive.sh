#!/bin/bash

# Script de backup automático para Google Drive
# Este script faz backup do projeto ia-para-todos-blog para Google Drive

set -e

# Configurações
BACKUP_DIR="/mnt/c/Users/RH/Google Drive/IA-para-Todos-Backup"
PROJECT_DIR="$(pwd)"
DATE=$(date +%Y%m%d_%H%M%S)
BACKUP_NAME="ia-para-todos-blog_backup_${DATE}.tar.gz"

# Cria diretório de backup se não existir
mkdir -p "$BACKUP_DIR"

# Faz backup do projeto
echo "Iniciando backup do projeto..."
tar -czf "$BACKUP_DIR/$BACKUP_NAME" -C "$PROJECT_DIR" .

echo "Backup concluído: $BACKUP_NAME"
echo "Tamanho: $(du -h "$BACKUP_DIR/$BACKUP_NAME" | cut -f1)"

# Mantém apenas os últimos 7 backups
cd "$BACKUP_DIR"
echo "Removendo backups antigos (mantendo os últimos 7)..."
ls -t *.tar.gz | tail -n +8 | xargs -r rm

echo "Limpeza concluída."
echo "Backup finalizado com sucesso!"