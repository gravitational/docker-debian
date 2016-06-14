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

*60Mb approx.*

## Debian Venti

Image with Go build environment. Batteries included.

*610Mb approx.*

## Usage

```shell
make debian-tall
make debian-grande
make debian-venti
```

Also, if you have caching http-proxy you can use it in build:

```shell
http_proxy=http://proxy.addr.ess:port make debian-tall
```
