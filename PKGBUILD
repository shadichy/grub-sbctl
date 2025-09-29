#shellcheck shell=bash
# Maintainer: shadichy <shadichy@blisslabs.org>

pkgbase=grub-secureboot-scripts
pkgname=$pkgbase
pkgver=0.0.2
pkgrel=1
pkgdesc='GRUB SecureBoot scripts to setup SecureBoot using sbctl with automatic signing of GRUB files and kernel images'
arch=('any')
march=''
url='https://github.com/shadichy/grub-sbctl'
license=('GPLv3')
depends=('grub' 'sbctl' 'bash')
source=('gsb.conf' 'grub-sbctl-sign' 'setup.sh' '91-sign-grub.hook')
sha512sums=(
	'40e0388f1e2de0eb5f5f67c3eb0853c51463c946c6aecd75bc91649f51610992a4fc3cadf76f852bf40d80f06e735a56a174d19eeb3cf449c6cc19b7dc1fc84c'
	'41c89c777e50ede4b48296dd2c553cc6b1ec31ab4e66a1dc849fa6fb9655fbd814b664dac425a2ab3ec7fb2e83977a80a1de5ac42d620f1ebf061449b3d6796d'
	'326aa207da395da46e4fabdb6e3c3848cf81bef3c9998db75d721b9dd56ca7f2961b93e73ae3cecbd4e5c55fa9da72275c4a2601772adbaceec2f44d61da1753'
	'27bf0637e6c58bee0fadaa5a31074dac0b9aa830ae2bf369174c17388363947ba6936af71dea0d05eeab004419cf1cdb0870ac3c141a7bcd360cd687e610b977'
)

pkgver() {
	cat $srcdir/../VERSION
}

package() {
	mkdir -p $pkgdir/etc $pkgdir/usr/bin $pkgdir/usr/share/grub/sbctl $pkgdir/usr/share/libalpm/hooks
	install -dm644 $pkgdir/etc
	install -dm755 $pkgdir/usr/bin
	install -dm644 $pkgdir/usr/share/grub/sbctl
	install -dm644 $pkgdir/usr/share/libalpm/hooks
	install -m644 'gsb.conf' $pkgdir/etc
	install -m644 '91-sign-grub.hook' $pkgdir/usr/share/libalpm/hooks
	install -m755 'grub-sbctl-sign' $pkgdir/usr/bin
	install -m755 'setup.sh' $pkgdir/usr/share/grub/sbctl
}
