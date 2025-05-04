# Maintainer: SilverX <serainox@gmail.com>
pkgname=pkmax
pkgver=1.0
pkgrel=1
pkgdesc="PackerMax: Compress, split, extract, and upload archives"
arch=('any')
url="https://github.com/Szmelc-INC/PackerMax"
license=('MIT')
depends=('bash' 'coreutils' 'zip' 'tar' 'gzip' 'xz' 'bzip2' 'curl')
makedepends=('git')
source=("git+$url.git#branch=main")
md5sums=('SKIP')

package() {
  cd "$srcdir/PackerMax"
  install -Dm755 packermax.sh "$pkgdir/usr/bin/pkmax"
}
