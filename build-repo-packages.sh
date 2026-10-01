#!/bin/bash
set -euo pipefail

REPO_DIR="/build/wlasnyos-repo"
PKG_DIR="${REPO_DIR}/packages"
BUILD_TMP="/tmp/pkg-build"
DB_FILE="${REPO_DIR}/PACKAGES.db"

mkdir -p "${PKG_DIR}" "${BUILD_TMP}"

build_wpkg() {
    local name="$1"
    local version="$2"
    local release="$3"
    local desc="$4"
    local deps="${5:-}"
    local staging="$6"
    
    local filename="packages/${name}-${version}-${release}-x86_64.wpkg"
    local full_path="${REPO_DIR}/${filename}"
    
    echo "==> Pakowanie: ${name} (${version}-${release})..."
    
    # Tworzenie PKGINFO
    cat << EOF > "${staging}/PKGINFO"
name=${name}
version=${version}
release=${release}
description=${desc}
depends=${deps}
arch=x86_64
maintainer=WlasnyOS
url=https://github.com/BMW0807/Os-repo
EOF

    # Obliczenie rozmiaru
    local size=$(du -sb "${staging}/data" 2>/dev/null | awk '{print $1}' || echo 1024)
    echo "size=${size}" >> "${staging}/PKGINFO"

    # Tworzenie archiwum tar.xz
    (cd "${staging}" && tar -cJf "${full_path}" PKGINFO data $([ -f INSTALL.sh ] && echo INSTALL.sh || true))

    # Obliczenie SHA256
    local sha=$(sha256sum "${full_path}" | awk '{print $1}')

    echo "==> Zbudowano: ${filename} (SHA256: ${sha:0:16}...)"

    # Dodanie do tymczasowego PACKAGES.db
    cat << EOF >> "${BUILD_TMP}/PACKAGES.db.new"
name=${name}
version=${version}
release=${release}
description=${desc}
depends=${deps}
arch=x86_64
size=${size}
filename=${filename}
sha256=${sha}

EOF
}

echo "=== Rozpoczynam budowanie pakietów WlasnyOS ==="
rm -f "${BUILD_TMP}/PACKAGES.db.new"
touch "${BUILD_TMP}/PACKAGES.db.new"

# -------------------------------------------------------------
# 1. Pakiet: micro (Nowoczesny edytor tekstu)
# -------------------------------------------------------------
MICRO_DIR="${BUILD_TMP}/micro"
rm -rf "${MICRO_DIR}"
mkdir -p "${MICRO_DIR}/data/usr/bin"
echo "Pobieranie edytora micro..."
wget -q -O "${BUILD_TMP}/micro.tar.gz" "https://github.com/zyedidia/micro/releases/download/v2.0.14/micro-2.0.14-linux64-static.tar.gz"
tar -xzf "${BUILD_TMP}/micro.tar.gz" -C "${BUILD_TMP}"
cp "${BUILD_TMP}/micro-2.0.14/micro" "${MICRO_DIR}/data/usr/bin/"
chmod +x "${MICRO_DIR}/data/usr/bin/micro"

build_wpkg "micro" "2.0.14" "1" "Nowoczesny edytor tekstu ze wsparciem myszki i podswietlaniem skladni" "" "${MICRO_DIR}"

# -------------------------------------------------------------
# 2. Pakiet: dejavu-fonts (Czcionki TrueType)
# -------------------------------------------------------------
FONTS_DIR="${BUILD_TMP}/fonts"
rm -rf "${FONTS_DIR}"
mkdir -p "${FONTS_DIR}/data/usr/share/fonts/dejavu"
echo "Przygotowywanie czcionek DejaVu..."
# Pobieramy lub kopiujemy podstawowe czcionki
if [ -d /usr/share/fonts/truetype/dejavu ]; then
    cp /usr/share/fonts/truetype/dejavu/*.ttf "${FONTS_DIR}/data/usr/share/fonts/dejavu/" 2>/dev/null || true
else
    apt-get update && apt-get install -y --no-install-recommends fonts-dejavu-core
    cp /usr/share/fonts/truetype/dejavu/*.ttf "${FONTS_DIR}/data/usr/share/fonts/dejavu/"
fi

build_wpkg "dejavu-fonts" "2.37" "1" "Czcionki TrueType DejaVu dla srodowiska graficznego" "" "${FONTS_DIR}"

# -------------------------------------------------------------
# 3. Pakiet: wlasnyos-wallpaper (Tapeta)
# -------------------------------------------------------------
WALL_DIR="${BUILD_TMP}/wallpaper"
rm -rf "${WALL_DIR}"
mkdir -p "${WALL_DIR}/data/usr/share/wallpapers"

# Tworzymy elegancką ciemną tapetę w formacie SVG i PNG
cat << 'EOF' > "${WALL_DIR}/data/usr/share/wallpapers/wlasnyos.svg"
<svg xmlns="http://www.w3.org/2000/svg" width="1920" height="1080" viewBox="0 0 1920 1080">
  <defs>
    <linearGradient id="bg" x1="0%" y1="0%" x2="100%" y2="100%">
      <stop offset="0%" style="stop-color:#0d1117;stop-opacity:1" />
      <stop offset="50%" style="stop-color:#161b22;stop-opacity:1" />
      <stop offset="100%" style="stop-color:#090d13;stop-opacity:1" />
    </linearGradient>
  </defs>
  <rect width="1920" height="1080" fill="url(#bg)" />
  <circle cx="960" cy="500" r="160" fill="none" stroke="#58a6ff" stroke-width="4" opacity="0.6" />
  <circle cx="960" cy="500" r="100" fill="none" stroke="#2ea043" stroke-width="3" opacity="0.4" />
  <text x="960" y="520" font-family="monospace, sans-serif" font-size="64" font-weight="bold" fill="#f0f6fc" text-anchor="middle">WlasnyOS</text>
  <text x="960" y="560" font-family="monospace, sans-serif" font-size="20" fill="#8b949e" text-anchor="middle">Genesis 1.0</text>
</svg>
EOF

# Tworzymy też prosty plik graficzny PNG (1x1 placeholder z ciemnym kolorem lub PPM)
cat << 'EOF' > "${WALL_DIR}/data/usr/share/wallpapers/wlasnyos.ppm"
P3
2 2
255
15 23 42  15 23 42
30 41 59  30 41 59
EOF
cp "${WALL_DIR}/data/usr/share/wallpapers/wlasnyos.svg" "${WALL_DIR}/data/usr/share/wallpapers/wlasnyos.png" || true

build_wpkg "wlasnyos-wallpaper" "1.0" "1" "Oficjalna tapeta pulpitu dla WlasnyOS" "" "${WALL_DIR}"

# -------------------------------------------------------------
# 4. Pakiety GUI: dwm, dmenu, st (Suckless minimalistyczne GUI)
# -------------------------------------------------------------
echo "Instalacja bibliotek deweloperskich do kompilacji X11..."
apt-get update && apt-get install -y --no-install-recommends libx11-dev libxft-dev libxinerama-dev libxext-dev

# Budowanie dwm
DWM_DIR="${BUILD_TMP}/dwm"
rm -rf "${DWM_DIR}" "${BUILD_TMP}/dwm-6.5"
mkdir -p "${DWM_DIR}/data/usr/bin" "${DWM_DIR}/data/usr/share/man/man1"
echo "Pobieranie i kompilacja dwm..."
wget -q -O "${BUILD_TMP}/dwm.tar.gz" "https://dl.suckless.org/dwm/dwm-6.5.tar.gz"
tar -xzf "${BUILD_TMP}/dwm.tar.gz" -C "${BUILD_TMP}"
(
    cd "${BUILD_TMP}/dwm-6.5"
    sed -i 's|/usr/local|/usr|g' config.mk
    sed -i 's|X11INC = /usr/X11R6/include|X11INC = /usr/include/X11|g' config.mk
    sed -i 's|X11LIB = /usr/X11R6/lib|X11LIB = /usr/lib/x86_64-linux-gnu|g' config.mk
    make -j$(nproc)
    make DESTDIR="${DWM_DIR}/data" install
)
build_wpkg "dwm" "6.5" "1" "Minimalistyczny, dynamiczny menedzer okien dla X11" "xorg-server libx11 libxft" "${DWM_DIR}"

# Budowanie dmenu
DMENU_DIR="${BUILD_TMP}/dmenu"
rm -rf "${DMENU_DIR}" "${BUILD_TMP}/dmenu-5.3"
mkdir -p "${DMENU_DIR}/data/usr/bin"
echo "Pobieranie i kompilacja dmenu..."
wget -q -O "${BUILD_TMP}/dmenu.tar.gz" "https://dl.suckless.org/tools/dmenu-5.3.tar.gz"
tar -xzf "${BUILD_TMP}/dmenu.tar.gz" -C "${BUILD_TMP}"
(
    cd "${BUILD_TMP}/dmenu-5.3"
    sed -i 's|/usr/local|/usr|g' config.mk
    sed -i 's|X11INC = /usr/X11R6/include|X11INC = /usr/include/X11|g' config.mk
    sed -i 's|X11LIB = /usr/X11R6/lib|X11LIB = /usr/lib/x86_64-linux-gnu|g' config.mk
    make -j$(nproc)
    make DESTDIR="${DMENU_DIR}/data" install
)
build_wpkg "dmenu" "5.3" "1" "Szybkie menu uruchamiania programow (skrot: Alt+P)" "libx11 libxft" "${DMENU_DIR}"

# Budowanie st (terminal)
ST_DIR="${BUILD_TMP}/st"
rm -rf "${ST_DIR}" "${BUILD_TMP}/st-0.9.2"
mkdir -p "${ST_DIR}/data/usr/bin"
echo "Pobieranie i kompilacja st (terminal)..."
wget -q -O "${BUILD_TMP}/st.tar.gz" "https://dl.suckless.org/st/st-0.9.2.tar.gz"
tar -xzf "${BUILD_TMP}/st.tar.gz" -C "${BUILD_TMP}"
(
    cd "${BUILD_TMP}/st-0.9.2"
    sed -i 's|/usr/local|/usr|g' config.mk
    sed -i 's|X11INC = /usr/X11R6/include|X11INC = /usr/include/X11|g' config.mk
    sed -i 's|X11LIB = /usr/X11R6/lib|X11LIB = /usr/lib/x86_64-linux-gnu|g' config.mk
    make -j$(nproc)
    make DESTDIR="${ST_DIR}/data" install
)
build_wpkg "st" "0.9.2" "1" "Lekki, minimalistyczny emulator terminala dla X11" "libx11 libxft" "${ST_DIR}"

# -------------------------------------------------------------
# 5. Pakiet: wlasnyos-desktop (Metapakiet integracyjny)
# -------------------------------------------------------------
DESKTOP_DIR="${BUILD_TMP}/desktop"
rm -rf "${DESKTOP_DIR}"
mkdir -p "${DESKTOP_DIR}/data/usr/bin" "${DESKTOP_DIR}/data/etc/skel"

cat << 'EOF' > "${DESKTOP_DIR}/data/usr/bin/startx-wlasnyos"
#!/bin/sh
# Start WlasnyOS Graphical Environment
echo "Uruchamianie srodowiska graficznego WlasnyOS..."
export DISPLAY=:0

# Uruchomienie serwera X w tle jesli nie dziala
if ! pidof Xorg >/dev/null 2>&1 && ! pidof X >/dev/null 2>&1 && ! pidof Xfbdev >/dev/null 2>&1; then
    if command -v Xorg >/dev/null 2>&1; then
        Xorg :0 vt1 &
    elif command -v Xfbdev >/dev/null 2>&1; then
        Xfbdev :0 &
    elif command -v X >/dev/null 2>&1; then
        X :0 &
    fi
    sleep 2
fi

# Uruchomienie terminala i menedzera okien
st &
exec dwm
EOF
chmod +x "${DESKTOP_DIR}/data/usr/bin/startx-wlasnyos"

# Domyślny .xinitrc
cat << 'EOF' > "${DESKTOP_DIR}/data/etc/skel/.xinitrc"
#!/bin/sh
st &
exec dwm
EOF

build_wpkg "wlasnyos-desktop" "1.0" "1" "Pelne srodowisko graficzne (DWM, ST, Dmenu, startx-wlasnyos)" "dwm st dmenu dejavu-fonts wlasnyos-wallpaper" "${DESKTOP_DIR}"

# -------------------------------------------------------------
# Aktualizacja bazy PACKAGES.db
# -------------------------------------------------------------
cp "${BUILD_TMP}/PACKAGES.db.new" "${DB_FILE}"
echo "=========================================="
echo "Baza ${DB_FILE} zostala pomyslnie zaktualizowana!"
echo "Pakiety w katalogu ${PKG_DIR}:"
ls -lh "${PKG_DIR}"
echo "=========================================="
