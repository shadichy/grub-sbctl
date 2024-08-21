# Maintainer: shadichy <shadichy.dev@gmail.com>
pkgbase=grub-secureboot-scripts
pkgname=$pkgbase
pkgver=0.0.1
pkgrel=1
pkgdesc='Grub SecureBoot scripts to setup and enable SecureBoot using sbctl fully automatic'
arch=(any)
march=""
url='https://github.com/shadichy/grub-sbctl'
license=('GPL')
depends=('grub' 'sbctl' 'bash')
source=('gsb.conf' 'grub-sbctl-sign' 'setup.sh' '91-sign-grub.hook')
sha512sums=('e3709a442783e7d5a93f46b055b2b0db7cdd724e159a3354bc4403b975d7c2d57f174f778ffe10b9fcfea9a3e837c269874cf751b619b5b20d21697f12374a5a' 
'2f61539475c65eff8b39e2813f8c932738f1ed5c4c8e4837c180f249522f690780b13957b2b02998c7e35751a4a48bcec4dfebdffbb4f3b7a6186d6de4e92f9d' 
'65b093f48f6691933c4b5001462c21b8f746829abc6737634d3dbe75de778e06e049de6fc81c984b09713ddbc4847e1e3abf0b5d742494fc2b89f35c0dd054b6' 
'27bf0637e6c58bee0fadaa5a31074dac0b9aa830ae2bf369174c17388363947ba6936af71dea0d05eeab004419cf1cdb0870ac3c141a7bcd360cd687e610b977')

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
