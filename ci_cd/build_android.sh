#!/bin/sh
# build_android.sh
# Lê a versão gerada pelo semantic-release, assina e compila o APK release
# e faz upload para o GitLab Generic Package Registry + Release Asset.

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

echo "📱 Iniciando build Android para versão: $new_version"

# ─────────────────────────────────────────────────────────────
# Java home — fixo para ghcr.io/cirruslabs/flutter (Ubuntu + JDK 21)
# ─────────────────────────────────────────────────────────────
export JAVA_HOME=$(readlink -f /usr/bin/java | sed 's|/bin/java||')
echo "☕ JAVA_HOME: $JAVA_HOME"

# ─────────────────────────────────────────────────────────────
# Keystore — decodifica o base64 e gera o key.properties
# ─────────────────────────────────────────────────────────────
echo "🔑 Configurando keystore para assinatura..."

if [ -z "$KEYSTORE_BASE64" ]; then
    echo "❌ Erro: variável KEYSTORE_BASE64 não definida"
    exit 1
fi
if [ -z "$KEYSTORE_PASSWORD" ]; then
    echo "❌ Erro: variável KEYSTORE_PASSWORD não definida"
    exit 1
fi
if [ -z "$KEYSTORE_ALIAS" ]; then
    echo "❌ Erro: variável KEYSTORE_ALIAS não definida"
    exit 1
fi
if [ -z "$KEYSTORE_ALIAS_PASSWORD" ]; then
    echo "❌ Erro: variável KEYSTORE_ALIAS_PASSWORD não definida"
    exit 1
fi

keystore_path="$(pwd)/android/release.keystore"

echo "$KEYSTORE_BASE64" | base64 -d > "$keystore_path"
echo "✅ Keystore decodificada em: $keystore_path"

cat > android/key.properties << PROPS
storeFile=$keystore_path
storePassword=$KEYSTORE_PASSWORD
keyAlias=$KEYSTORE_ALIAS
keyPassword=$KEYSTORE_ALIAS_PASSWORD
PROPS

echo "✅ key.properties gerado"

# ─────────────────────────────────────────────────────────────
# Flutter build
# ─────────────────────────────────────────────────────────────
if ! command -v flutter >/dev/null 2>&1; then
    echo "❌ Erro: Flutter não encontrado no PATH"
    exit 1
fi

echo "📦 Instalando dependências..."
flutter pub get

echo "🔨 Compilando APK release (assinado)..."
flutter build apk --release

apk_source="build/app/outputs/flutter-apk/app-release.apk"
if [ ! -f "$apk_source" ]; then
    echo "❌ Erro: APK não encontrado em $apk_source"
    exit 1
fi

apk_name="app-release-v${new_version}.apk"
cp "$apk_source" "$apk_name"
echo "✅ APK gerado: $apk_name"

# ─────────────────────────────────────────────────────────────
# Validação das variáveis de CI
# ─────────────────────────────────────────────────────────────
if [ -z "$CI_API_V4_URL" ] || [ -z "$CI_PROJECT_ID" ]; then
    echo "❌ Erro: CI_API_V4_URL ou CI_PROJECT_ID não definidos"
    exit 1
fi

if [ -n "$CI_JOB_TOKEN" ]; then
    auth_header="JOB-TOKEN: $CI_JOB_TOKEN"
else
    echo "❌ Erro: CI_JOB_TOKEN não disponível"
    exit 1
fi

package_registry_url="${CI_API_V4_URL}/projects/${CI_PROJECT_ID}/packages/generic/android-apk/${new_version}/${apk_name}"

# ─────────────────────────────────────────────────────────────
# Upload para o Generic Package Registry
# ─────────────────────────────────────────────────────────────
echo "📤 Enviando APK para o Package Registry..."

curl --fail \
     --header "$auth_header" \
     --upload-file "$apk_name" \
     "$package_registry_url"

echo "✅ APK enviado: $package_registry_url"

# ─────────────────────────────────────────────────────────────
# Anexar como Release Asset
# ─────────────────────────────────────────────────────────────
release_tag="v${new_version}"
echo "🏷️  Anexando APK como asset da release $release_tag..."

http_status=$(curl --silent --output /dev/null --write-out "%{http_code}" \
    --request POST \
    --header "$auth_header" \
    --header "Content-Type: application/json" \
    --data "{
        \"name\": \"${apk_name}\",
        \"url\": \"${package_registry_url}\",
        \"link_type\": \"package\"
    }" \
    "${CI_API_V4_URL}/projects/${CI_PROJECT_ID}/releases/${release_tag}/assets/links")

if [ "$http_status" = "200" ] || [ "$http_status" = "201" ]; then
    echo "✅ Asset adicionado à release $release_tag!"
else
    echo "⚠️  Não foi possível adicionar asset link (HTTP $http_status)."
    echo "   O APK ainda está disponível no Package Registry."
fi

# ─────────────────────────────────────────────────────────────
# Limpeza — remove arquivos sensíveis do workspace
# ─────────────────────────────────────────────────────────────
rm -f "$keystore_path" android/key.properties
echo "🧹 Arquivos sensíveis removidos do workspace"

echo ""
echo "✅ Android concluído!"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "📱 APK:     $apk_name"
echo "🔗 URL:     $package_registry_url"
echo "🏷️  Release: $release_tag"