#shellcheck shell=bash
# Maintainer: shadichy <shadichy@blisslabs.org>

pkgbase=grub-secureboot-scripts
pkgname=$pkgbase
pkgver=0.0.2
pkgrel=6
pkgdesc='GRUB SecureBoot scripts to setup SecureBoot using sbctl with automatic signing of GRUB files and kernel images'
arch=('any')
march=''
url='https://github.com/shadichy/grub-sbctl'
license=('GPLv3')
depends=('grub' 'sbctl' 'bash')
source=('gsb.conf' 'grub-sbctl-sign' 'setup.sh' '91-sign-grub.hook' 'grub-sbctl-setup-completion')
sha512sums=(
	'40e0388f1e2de0eb5f5f67c3eb0853c51463c946c6aecd75bc91649f51610992a4fc3cadf76f852bf40d80f06e735a56a174d19eeb3cf449c6cc19b7dc1fc84c'
	'bcf77f5daab5deda84447fd72ac871d295174a3989a87eb06cf5ce15910033e2d8d69ff6c06981019a78748448d87b1ca0788def8d9532abf8a1cd396ccca5ca'
	'dd9e64862e6f29df9c42425f25af8f7aa5def25edf29f29a59322c97f8c466895f2bce73659a54d887fdf00fc5b591ea8a9c48334c174d2826f776beceb33851'
	'b3611b9c6fd99f89612c17468b011aa52716bd61dcf23e547516d633d0f1ce499b272007fa2f04813baf82dc08f4653a99907a59d906ff1c1937418181ccf2a2'
	'f2eb1166e65d5e1809949be154e80a1240f0f9e043600e212ccaf40c7aee1dfc23afffe18ea192e3d62dbb229dbd0995261563ea79cf886eed32351b69565d37'
)

pkgver() {
	cat $srcdir/../VERSION
}

package() {
	mkdir -p $pkgdir/{etc,usr/{bin,share/{grub/sbctl,libalpm/hooks,bash-completion/completions,zsh/site-functions}}}

	local -a \
		dir644=(etc usr/{bin,share/libalpm/hooks}) \
		dir755=(usr/{bin,share/{grub/sbctl,bash-completion/completions,zsh/site-functions}})

	for d in "${dir644[@]}"; do
		install -dm644 "$pkgdir/$d"
	done

	for d in "${dir755[@]}"; do
		install -dm755 "$pkgdir/$d"
	done

	install -m755 'grub-sbctl-setup-completion' $pkgdir/usr/share/bash-completion/completions/setup.sh
	install -m755 'grub-sbctl-setup-completion' $pkgdir/usr/share/zsh/site-functions/_setup.sh
	install -m644 'gsb.conf' $pkgdir/etc
	install -m644 '91-sign-grub.hook' $pkgdir/usr/share/libalpm/hooks
	install -m755 'grub-sbctl-sign' $pkgdir/usr/bin
	install -m755 'setup.sh' $pkgdir/usr/share/grub/sbctl
}
