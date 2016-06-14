# Customized Docker Debian images

## Debian Tall

Contains:

* libc
* ca-certificates
* busybox

Main purpose of this image is to run Go or static-linked binaries. No package
manager is present.

*11Mb approx.*

## Debian Grande

Contains cut debootstrapped system (`minbase` variant). `dpkg` works here.

*57Mb approx.*

## Debian Venti

Image with Go build environment. Batteries included.

*600Mb approx.*

