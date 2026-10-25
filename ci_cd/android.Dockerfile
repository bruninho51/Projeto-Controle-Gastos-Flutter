# Imagem usada pelo job `android` do CI.
# Parte da imagem oficial do Flutter e já deixa instalado o que o Gradle
# baixaria a cada build (NDK e Android platform), com as licenças aceitas.
#
# Ao alterar este arquivo, incremente ANDROID_IMAGE_REV no .gitlab-ci.yml.

ARG FLUTTER_VERSION
FROM ghcr.io/cirruslabs/flutter:${FLUTTER_VERSION}

# curl é usado pelo build_android.sh para enviar o APK ao registry
RUN command -v curl > /dev/null 2>&1 || \
    (apt-get update -qq \
     && apt-get install -y --no-install-recommends curl \
     && rm -rf /var/lib/apt/lists/*)

RUN yes | sdkmanager --licenses > /dev/null || true

# Lê do próprio SDK do Flutter as versões de NDK e compileSdk que o
# `flutter.ndkVersion` / `flutter.compileSdkVersion` do projeto vão pedir.
RUN set -e; \
    flutter_root="$(dirname "$(dirname "$(readlink -f "$(command -v flutter)")")")"; \
    gradle_src="$flutter_root/packages/flutter_tools/gradle"; \
    ndk_version="$(grep -rhoE 'ndkVersion[^=]*= *"[0-9.]+"' "$gradle_src" | grep -oE '[0-9][0-9.]+' | head -1)"; \
    compile_sdk="$(grep -rhoE 'compileSdkVersion[^=]*= *[0-9]+' "$gradle_src" | grep -oE '[0-9]+$' | head -1)"; \
    if [ -z "$ndk_version" ] || [ -z "$compile_sdk" ]; then \
        echo "Não foi possível descobrir ndkVersion/compileSdkVersion em $gradle_src"; exit 1; \
    fi; \
    echo "Instalando ndk;$ndk_version e platforms;android-$compile_sdk"; \
    yes | sdkmanager --install "ndk;$ndk_version" "platforms;android-$compile_sdk" > /dev/null
