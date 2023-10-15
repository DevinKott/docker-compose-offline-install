# Docker compose offline install utility

This script helps perform offline installations of images for multi-container (Docker compose) applications.

**Use Case**: You have an offline-only system that needs Docker images, but cannot connect to the internet to pull down those images.
You _do_ have physical access to the system.

## Usage

```
./script.sh [save | load] <compose file | tarball>
```

## Instructions

Clone the repository onto your system and ensure `script.sh` has execution permissions.
```
$ git clone https://github.com/DevinKott/docker-compose-offline-install
$ cd docker-compose-offline-install
$ chmod +x ./script.sh
```

If you want to save images from a compose file, use the following command (must be internet-connected):
```
$ ./script.sh save /home/user/compose.yml
```

The script will find all images in the `compose.yml`, download them onto the system, and package them up into `release.tar.gz`.

To load a tarball (for example, `release.tar.gz`), use the following command (do not need internet-connected!):
```
$ ./script.sh load release.tar.gz
```

The script will unpack the tarball and run `docker load` on each image, loading the image onto the system and into Docker.
