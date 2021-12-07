<<<<<<< Updated upstream
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
=======
# Configuration

## Builder config

'''
	// Lets you prefix all builder commands, such as with ssh for a remote build host. Defaults to "".
	// Copied from other builders :)
	CommandWrapper string `mapstructure:"command_wrapper"`

	// Output directory, where the final image will be stored.
	// Deprecated - Use OutputFile instead
	OutputDir string `mapstructure:"output_directory"`

	// Output filename, where the final image will be stored
	OutputFile string `mapstructure:"output_filename"`

	// Image type. this is used to deduce other settings like image mounts and qemu args.
	// If not provided, we will try to deduce it from the image url. (see autoDetectType())
	// For list of valid values, see: pkg/image/utils/images.go
	ImageType utils.KnownImageType `mapstructure:"image_type"`

	// Where to mounts the image partitions in the chroot.
	// first entry is the mount point of the first partition. etc..
	ImageMounts []string `mapstructure:"image_mounts"`

	// The path where the volume will be mounted. This is where the chroot environment will be.
	// Will be a temporary directory if left unspecified.
	MountPath string `mapstructure:"mount_path"`

	// What directories mount from the host to the chroot.
	// leave it empty for reasonable defaults.
	// array of triplets: [type, device, mntpoint].
	ChrootMounts [][]string `mapstructure:"chroot_mounts"`

	// What directories mount from the host to the chroot, in addition to the default ones.
	// Use this instead of `chroot_mounts` if you want to add to the existing defaults instead of
	// overriding them
	// array of triplets: [type, device, mntpoint].
	// for example: `["bind", "/run/systemd", "/run/systemd"]`
	AdditionalChrootMounts [][]string `mapstructure:"additional_chroot_mounts"`

	// Can be one of: off, copy-host, bind-host, delete. Defaults to off
	ResolvConf ResolvConfBehavior `mapstructure:"resolv-conf"`

	// Should the last partition be extended? this only works for the last partition in the
	// dos partition table, and ext filesystem
	LastPartitionExtraSize uint64 `mapstructure:"last_partition_extra_size"`
	// The target size of the final image. The last partiation will be extended to
	// fill up this much room. I.e. if the generated image is 256MB and TargetImageSize
	// is set to 384MB the last partition will be extended with an additional 128MB.
	TargetImageSize uint64 `mapstructure:"target_image_size"`

	// Qemu binary to use. default is qemu-arm-static
	QemuBinary string `mapstructure:"qemu_binary"`
	// Arguments to qemu binary. default depends on the image type. see init() function above.
	QemuArgs []string `mapstructure:"qemu_args"`
	// contains filtered or unexported fields
'''
>>>>>>> Stashed changes
