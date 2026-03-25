#!/bin/sh
# build_container.sh
# Lê a versão gerada pelo semantic-release, faz build e push da imagem Docker.

set -e

# ─────────────────────────────────────────────────────────────
# Versão
# ─────────────────────────────────────────────────────────────
version_file="version.txt"
if [ ! -f "$version_file" ]; then
    echo "❌ Erro: $version_file não encontrado. O stage 'release' rodou antes?"
    exit 1
fi

new_version=$(cat "$version_file")
if [ -z "$new_version" ]; then
    echo "❌ Erro: $version_file está vazio"
    exit 1
fi

echo "🐳 Iniciando build Docker para versão: $new_version"

image_name="registry.gitlab.com/bruninho51/projeto-controle-gastos-flutter"
full_image="$image_name:v$new_version"

# ─────────────────────────────────────────────────────────────
# Login no registry
# ─────────────────────────────────────────────────────────────
echo "🔐 Autenticando no Container Registry..."

if [ -n "$CI_REGISTRY_USER" ] && [ -n "$CI_REGISTRY_PASSWORD" ]; then
    echo "$CI_REGISTRY_PASSWORD" | docker login -u "$CI_REGISTRY_USER" --password-stdin "$CI_REGISTRY"
elif [ -n "$GL_TOKEN" ] && [ -n "$CI_REGISTRY_USER" ]; then
    echo "$GL_TOKEN" | docker login -u "$CI_REGISTRY_USER" --password-stdin registry.gitlab.com
else
    echo "❌ Erro: Variáveis de autenticação não encontradas (CI_REGISTRY_USER / CI_REGISTRY_PASSWORD)"
    exit 1
fi

# ─────────────────────────────────────────────────────────────
# Build e Push
# ─────────────────────────────────────────────────────────────
echo "🔨 Fazendo build da imagem: $full_image"
docker build -t "$full_image" .

echo "📤 Enviando imagem para o registry..."
docker push "$full_image"

# Conclusão
echo ""
echo "🎉 Build e atualização concluídos!"
echo "📦 Nova versão: $new_version"
echo "🐳 Nova imagem: $full_image"
