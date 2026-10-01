# Repozytorium WlasnyOS

To jest oficjalne repozytorium pakietów dla dystrybucji WlasnyOS. Repozytorium zawiera indeks pakietów, gotowe pakiety binarne oraz receptury (WPKGBUILD) pozwalające na samodzielne zbudowanie systemu od zera.

Menedżerem pakietów używanym w WlasnyOS jest `wpkg`, a pakiety używają formatu `.wpkg` (archiwa tar.xz).

## Jak dodać repozytorium do wpkg

Aby dodać to repozytorium do menedżera `wpkg`, edytuj plik konfiguracji (zazwyczaj `/etc/wpkg/wpkg.conf`) i dodaj następujący wpis:

```ini
[wlasnyos-core]
url = file:///ścieżka/do/wlasnyos-repo
```
Zastąp `file:///ścieżka/do/wlasnyos-repo` odpowiednim adresem URL, jeśli repozytorium jest hostowane w sieci.

## Dostępne pakiety

W repozytorium dostępne są między innymi następujące pakiety:
- **nano, micro, vis** - edytory tekstu
- **xorg-server, dwm, st, dmenu** - środowisko graficzne i menedżer okien
- **wlasnyos-desktop** - gotowy metapakiet środowiska graficznego
- **wlasnyos-wallpaper** - tapeta systemowa
- Oraz podstawowe biblioteki (mesa, freetype, libdrm, itp.).

Pełna lista pakietów znajduje się w pliku `PACKAGES.db`.

## Jak budować pakiety z receptur

Wszystkie receptury znajdują się w katalogu `recipes/`. Aby zbudować wszystkie pakiety w odpowiedniej kolejności, możesz użyć dołączonego skryptu:

```bash
./build-all.sh
```

Aby zbudować pojedynczy pakiet ręcznie:
1. Wejdź do katalogu z wybraną recepturą, np. `cd recipes/nano`
2. Upewnij się, że masz potrzebne zależności.
3. Wykonaj menedżer budowania (np. `wpkg-makepkg`), który przeczyta plik `WPKGBUILD` i wygeneruje plik `.wpkg`.

## Tworzenie własnych WPKGBUILD

Pliki `WPKGBUILD` mają strukturę przypominającą archowe `PKGBUILD`. Przykład:

```bash
#!/bin/bash
# Receptura pakietu dla wpkg

pkgname=mojpakiet
pkgver=1.0
pkgrel=1
pkgdesc="Opis pakietu"
arch=x86_64
url="https://example.com"
depends=(zaleznosc1)
source="https://example.com/source-${pkgver}.tar.gz"
sha256sum="SKIP"

build() {
    cd "${pkgname}-${pkgver}"
    ./configure --prefix=/usr CC=musl-gcc
    make -j$(nproc)
}

package() {
    cd "${pkgname}-${pkgver}"
    make DESTDIR="${PKGDIR}" install
}
```
Każda receptura używa kompilatora `musl-gcc` do tworzenia lekkich, statycznie linkowanych (lub używających musl libc) binarek odpowiednich dla WlasnyOS.
