# Customized Docker Debian images

## Debian Tall [![Docker Repository on Quay](https://quay.io/repository/gravitational/debian-tall/status "Docker Repository on Quay")](https://quay.io/repository/gravitational/debian-tall)

Contains:

* libc
* ca-certificates
* busybox

Main purpose of this image is to run Go or static-linked binaries. No package
manager is present.

*11Mb approx.*

## Debian Grande [![Docker Repository on Quay](https://quay.io/repository/gravitational/debian-grande/status "Docker Repository on Quay")](https://quay.io/repository/gravitational/debian-grande)

Contains cut debootstrapped system (`minbase` variant). `dpkg` works here.

*60Mb approx.*

## Debian Venti [![Docker Repository on Quay](https://quay.io/repository/gravitational/debian-venti/status "Docker Repository on Quay")](https://quay.io/repository/gravitational/debian-venti)

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
