#!/bin/bash

# Sistema de administração de conteúdo para o blog
# Este script permite gerenciar posts, configurações e estatísticas do blog

set -e

# Configurações
BLOG_DIR="$(pwd)"
POSTS_DIR="$BLOG_DIR/_posts"
ASSETS_DIR="$BLOG_DIR/assets"
LOG_DIR="$BLOG_DIR/scripts/logs"

# Cria diretório de logs se não existir
mkdir -p "$LOG_DIR"

# Função para mostrar menu
echo "=== Sistema de Administração do Blog IA para Todos ==="
echo "1. Listar posts recentes"
echo "2. Criar novo post"
echo "3. Editar post existente"
echo "4. Excluir post"
echo "5. Ver estatísticas do blog"
echo "6. Configurar blog"
echo "7. Sair"
echo ""

# Lê opção do usuário
read -p "Escolha uma opção [1-7]: " option

case $option in
    1)
        # Listar posts recentes
        echo ""
        echo "=== Posts Recentes ==="
        echo ""
        ls -lt "$POSTS_DIR"/*.md 2>/dev/null | head -10 | awk '{print NR". " $9}'
        echo ""
        echo "Total de posts: $(find "$POSTS_DIR" -name "*.md" -type f | wc -l)"
        ;;
    2)
        # Criar novo post
        echo ""
        echo "=== Criar Novo Post ==="
        echo ""
        read -p "Título do post: " title
        read -p "Categoria (separadas por vírgula): " categories
        read -p "Conteúdo do post: " -d "\u001a" content
        
        # Formata data
        date_formatted=$(date "+%Y-%m-%d %H:%M:%S %z")
        
        # Cria arquivo do post
        post_filename="$POSTS_DIR/$(date +%Y-%m-%d)-$(echo "$title" | tr '[:upper:]' '[:lower:]' | tr ' ' '-' | sed 's/[^a-zA-Z0-9-]//g').md"
        
        cat > "$post_filename" << EOF
---
layout: post
title: "$title"
date: $date_formatted
categories: $categories
---

$content
EOF
        
        echo "Post criado com sucesso: $post_filename"
        ;;
    3)
        # Editar post existente
        echo ""
        echo "=== Editar Post ==="
        echo ""
        ls -lt "$POSTS_DIR"/*.md 2>/dev/null | awk '{print NR". " $9}'
        echo ""
        read -p "Número do post a editar: " post_num
        
        # Obtém arquivo do post
        post_file=$(ls -lt "$POSTS_DIR"/*.md 2>/dev/null | awk -v n=$post_num 'NR==n {print $9}')
        
        if [[ -n "$post_file" && -f "$post_file" ]]; then
            echo "Editando: $post_file"
            nano "$post_file"
            echo "Post salvo com sucesso!"
        else
            echo "Post não encontrado!"
        fi
        ;;
    4)
        # Excluir post
        echo ""
        echo "=== Excluir Post ==="
        echo ""
        ls -lt "$POSTS_DIR"/*.md 2>/dev/null | awk '{print NR". " $9}'
        echo ""
        read -p "Número do post a excluir: " post_num
        
        # Obtém arquivo do post
        post_file=$(ls -lt "$POSTS_DIR"/*.md 2>/dev/null | awk -v n=$post_num 'NR==n {print $9}')
        
        if [[ -n "$post_file" && -f "$post_file" ]]; then
            read -p "Tem certeza que deseja excluir $post_file? (s/n): " confirm
            if [[ "$confirm" == "s" || "$confirm" == "S" ]]; then
                rm "$post_file"
                echo "Post excluído com sucesso!"
            else
                echo "Exclusão cancelada."
            fi
        else
            echo "Post não encontrado!"
        fi
        ;;
    5)
        # Ver estatísticas
        echo ""
        echo "=== Estatísticas do Blog ==="
        echo ""
        echo "Total de posts: $(find "$POSTS_DIR" -name "*.md" -type f | wc -l)"
        echo "Total de categorias: $(find "$POSTS_DIR" -name "*.md" -type f | xargs grep -h "^categories:" | tr ',' '\n' | sort | uniq | wc -l)"
        echo "Espaço usado: $(du -sh "$BLOG_DIR" | cut -f1)"
        echo ""
        echo "Posts por categoria:"
        find "$POSTS_DIR" -name "*.md" -type f | xargs grep -h "^categories:" | tr ',' '\n' | sort | uniq -c | sort -nr
        ;;
    6)
        # Configurar blog
        echo ""
        echo "=== Configurar Blog ==="
        echo ""
        echo "Configurações atuais:"
        cat "$BLOG_DIR/_config.yml" | grep -E "^(title|description|baseurl|url)" | sed 's/^/  /'
        echo ""
        echo "Para editar configurações, use: nano _config.yml"
        ;;
    7)
        echo "Saindo..."
        exit 0
        ;;
    *)
        echo "Opção inválida!"
        ;;
esac

echo ""
echo "=== Sistema de Administração ==="
echo "Para usar novamente: ./scripts/admin-blog.sh"
echo "Para ver logs: tail -f scripts/logs/*.log"
echo ""