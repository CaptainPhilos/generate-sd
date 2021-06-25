# Linux

## Packer (https://www.packer.io/)

### installation
curl -fsSL https://apt.releases.hashicorp.com/gpg | sudo apt-key add -
sudo apt-add-repository "deb [arch=amd64] https://apt.releases.hashicorp.com $(lsb_release -cs) main"
sudo apt-get update && sudo apt-get install packer

## packer-builder-arm

https://github.com/solo-io/packer-builder-arm-image

### installation
sudo apt install kpartx qemu-user-static
sudo apt install golang-go

### building
git clone https://github.com/solo-io/packer-builder-arm-image
cd packer-builder-arm-image
go mod download
go build
cp packer-builder-arm-image [PROJET]/source/packer-generation/

### Using
sudo packer build xxxxx

# MacOs

## Packer (https://www.packer.io/)

Download : https://www.packer.io/downloads

### installation

    # installation
    brew tap hashicorp/tap
    brew install hashicorp/tap/Packer

    # Update
    brew upgrade hashicorp/tap/packer

## Install packer-builder-arm

instructions :
* https://mkaczanowski.com/arm-images-with-packer/
* https://github.com/solo-io/packer-builder-arm-image

### prerequisite : Go

* Download installation package --> https://golang.org/doc/install
* add the path to Go binairies into /etc/paths
    echo '/usr/local/go/bin' | sudo tee -a /etc/paths


### install packer-builder-arm

Source --> https://linuxhit.com/build-a-raspberry-pi-image-packer-packer-builder-arm/

In a tool folder :
* git clone https://github.com/mkaczanowski/packer-builder-arm
* cd packer-builder-arm
* go mod download
* go build
* mkdir ~/.packer.d/plugins (if not exists)
* cp packer-builder-arm ~/.packer.d/plugins


### Build with Docker

* cd packer-builder-arm
* docker build -t packer-builder-arm -f Dockerfile .
* 