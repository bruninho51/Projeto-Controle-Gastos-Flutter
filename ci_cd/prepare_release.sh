#!/bin/sh
# prepare_release.sh
# Atualiza os arquivos versionados e salva version.txt.
# Chamado pelo @semantic-release/exec no prepareCmd.

set -e

new_version="$1"
if [ -z "$new_version" ]; then
    echo "❌ Erro: Versão é obrigatória"
    echo "Uso: $0 \"1.2.3\""
    exit 1
fi

echo "🔖 Preparando release: $new_version"

# ─────────────────────────────────────────────────────────────
# pubspec.yaml
# ─────────────────────────────────────────────────────────────
pubspec_file="pubspec.yaml"
echo "📝 Atualizando $pubspec_file..."

if [ ! -f "$pubspec_file" ]; then
    echo "❌ Erro: $pubspec_file não encontrado"
    exit 1
fi

sed -i "s/^version: [0-9]\+\.[0-9]\+\.[0-9]\+\(.*\)$/version: $new_version\1/" "$pubspec_file"

if grep -q "version: $new_version" "$pubspec_file"; then
    echo "✅ $pubspec_file atualizado!"
else
    echo "❌ Erro: Falha ao atualizar $pubspec_file"
    exit 1
fi

# ─────────────────────────────────────────────────────────────
# k8s/app/deployment.yml
# ─────────────────────────────────────────────────────────────
deployment_file="k8s/app/deployment.yml"
image_name="registry.gitlab.com/bruninho51/projeto-controle-gastos-flutter"
full_image="$image_name:v$new_version"

echo "📝 Atualizando $deployment_file..."

if [ ! -f "$deployment_file" ]; then
    echo "❌ Erro: $deployment_file não encontrado"
    exit 1
fi

sed -i "s|image: $image_name:.*|image: $full_image|" "$deployment_file"

if grep -q "$full_image" "$deployment_file"; then
    echo "✅ $deployment_file atualizado!"
else
    echo "❌ Erro: Falha ao atualizar $deployment_file"
    exit 1
fi

# ─────────────────────────────────────────────────────────────
# version.txt — artifact para os stages container e android
# ─────────────────────────────────────────────────────────────
echo "$new_version" > version.txt
echo "✅ version.txt salvo: $new_version"

echo ""
echo "🎉 Arquivos preparados para o release $new_version"