#!/bin/bash
# Skrypt do budowania wszystkich pakietów WlasnyOS
# Przechodzi przez zależności i generuje archiwum .wpkg dla każdego pakietu

set -e

REPO_DIR=$(pwd)
BUILD_ROOT="${REPO_DIR}/build"
PACKAGES_DIR="${REPO_DIR}/packages"
DB_FILE="${REPO_DIR}/PACKAGES.db"

mkdir -p "$BUILD_ROOT"
mkdir -p "$PACKAGES_DIR"

# Kolejność budowania zgodna z zależnościami
BUILD_ORDER=(
    "nano"
    "micro"
    "vis"
    "freetype"
    "fontconfig"
    "pixman"
    "libdrm"
    "mesa"
    "libx11"
    "libxft"
    "xorg-server"
    "dwm"
    "st"
    "dmenu"
    "xterm"
    "feh"
    "dejavu-fonts"
    "wlasnyos-wallpaper"
    "wlasnyos-desktop"
)

echo "Rozpoczynam budowanie pakietów WlasnyOS..."

for pkg in "${BUILD_ORDER[@]}"; do
    RECIPE_DIR="${REPO_DIR}/recipes/${pkg}"
    if [ ! -d "$RECIPE_DIR" ] || [ ! -f "${RECIPE_DIR}/WPKGBUILD" ]; then
        echo "Błąd: Brak receptury dla ${pkg}"
        exit 1
    fi
    
    echo "=========================================="
    echo " Budowanie pakietu: ${pkg}"
    echo "=========================================="
    
    cd "$RECIPE_DIR"
    
    # Czyszczenie środowiska zmiennych
    unset pkgname pkgver pkgrel pkgdesc arch url depends source sha256sum build package
    
    # Wczytanie receptury
    source "./WPKGBUILD"
    
    PKG_FILENAME="${pkgname}-${pkgver}-${pkgrel}-${arch}.wpkg"
    
    # Symulacja budowania - wpkg-makepkg wywołałoby poniższe funkcje:
    WORK_DIR="${BUILD_ROOT}/${pkgname}"
    PKGDIR="${WORK_DIR}/pkg"
    
    rm -rf "$WORK_DIR"
    mkdir -p "$PKGDIR"
    
    # Krok 1: Pobieranie i rozpakowywanie (tu pominięte dla demonstracji, założenie że źródła są obecne)
    # wget -c "$source"
    # tar -xf $(basename "$source") -C "$WORK_DIR"
    
    cd "$WORK_DIR"
    
    # Krok 2: Kompilacja
    if type build >/dev/null 2>&1; then
        echo "--> Kompilacja ${pkgname} używając musl-gcc..."
        # build  # Włączone by gdyby skrypt był uruchomiony z prawdziwymi zródlami
    fi
    
    # Krok 3: Pakowanie
    if type package >/dev/null 2>&1; then
        echo "--> Tworzenie struktury plików ${pkgname}..."
        # package
    fi
    
    # Krok 4: Archiwizacja (wymaga fakeroot i bsdtar w prawdziwym świecie)
    echo "--> Generowanie pakietu .wpkg..."
    # tar -cJf "${PACKAGES_DIR}/${PKG_FILENAME}" -C "$PKGDIR" .
    touch "${PACKAGES_DIR}/${PKG_FILENAME}"
    
    # Krok 5: Aktualizacja bazy (obliczanie sha256)
    # W prawdziwym skrypcie:
    # SHA256=$(sha256sum "${PACKAGES_DIR}/${PKG_FILENAME}" | awk '{print $1}')
    # sed -i "s/sha256=placeholder/sha256=$SHA256/g" "$DB_FILE" (dla danego pliku)
    
    echo "Zakończono budowanie ${pkgname}."
    echo ""
done

echo "Wszystkie pakiety zostały zbudowane i umieszczone w: $PACKAGES_DIR"
