#++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
# Linux OS Image (LOI_) modding.
#----------------------------------------------------------------------------

#+
# Download, unpack, mount, modify, and unmount OS image files.
# Provides callable functions to mount and unmount so the images can be
# modified.
# Currently a maximum of two partitions are assumed to be the boot and
# root (not to be confused with /root). Symbolic links are created to
# point to the corresponding directories.
#-

_loi_Dir := $(call this_segment_dir)

# Configuration
LOI_BOARDS_DIR = ${_loi_Dir}/loi_boards
LOI_VARIANTS_DIR = ${_loi_Dir}/loi_variants
LOI_ACCESS_METHODS_DIR = ${_loi_Dir}/loi_access_methods
LOI_INIT_DIR = ${_loi_Dir}/loi_init
LOI_IMAGE_DIR = ${DOWNLOADS_DIR}/os-images
LOI_BUILD_DIR = ${MOD_BUILD_DIR}/os-images
LOI_STAGING_DIR = ${MOD_STAGING_DIR}/os-images
LOI_IMAGE_MNT_DIR = ${LOI_STAGING_DIR}/mnt

$(call require,config.mk, HELPER_FUNCTIONS)

$(call require,\
mod.mk, \
SBC_OS_VARIANT \
SBC_OS_BOARD \
SBC_ADMIN \
SBC_ADMIN_ID \
SBC_ADMIN_GID \
SBC_USER \
SBC_USER_ID \
SBC_USER_GID \
SBC_ACCESS_METHOD \
)

# Ensure using one of the supported access modes.
_AccessMethods = $(call basenames_in,${LOI_ACCESS_METHODS_DIR}/*.mk)
$(call must_be_one_of,SBC_ACCESS_METHOD,${_AccessMethods})

$(call require,${SBC_SOFTWARE}.mk,SBC_INIT_SCRIPT)

# These are a collection of scripts designed to run on the SBC during
# first time initialization. Each make segment can add to this list
# to define dependencies for staging.
LoiInitScripts = ${HELPER_FUNCTIONS}

include ${LOI_BOARDS_DIR}/${SBC_OS_BOARD}.mk
include ${LOI_VARIANTS_DIR}/${SBC_OS_VARIANT}.mk
include ${LOI_ACCESS_METHODS_DIR}/${SBC_ACCESS_METHOD}.mk

$(call require,\
${SBC_OS_VARIANT}.mk, \
${SBC_OS_VARIANT}_TMP_DIR \
)

# To shorten references a bit.
_OsTmpDir = ${${SBC_OS_VARIANT}_TMP_DIR}
_OsImageTmpDir = ${LOI_IMAGE_MNT_DIR}/${${SBC_OS_VARIANT}_LOI_ROOT_DIR}/${_OsTmpDir}

$(call require,\
${SBC_OS_BOARD}.mk,\
SBC_OS_ARCH \
${SBC_OS_VARIANT}_LOI_RELEASE \
${SBC_OS_VARIANT}_LOI_VERSION \
${SBC_OS_VARIANT}_LOI_IMAGE \
${SBC_OS_VARIANT}_LOI_IMAGE_FILE \
${SBC_OS_VARIANT}_LOI_DOWNLOAD \
${SBC_OS_VARIANT}_LOI_UNPACK \
${SBC_OS_VARIANT}_LOI_P1_NAME \
${SBC_OS_VARIANT}_LOI_BOOT_DIR \
${SBC_OS_VARIANT}_LOI_ROOT_DIR \
)

$(call require,\
${SBC_OS_VARIANT}.mk,\
${SBC_OS_VARIANT}_TMP_DIR \
${SBC_OS_VARIANT}_ETC_DIR \
${SBC_OS_VARIANT}_HOME_DIR \
${SBC_OS_VARIANT}_USER_HOME_DIR \
${SBC_OS_VARIANT}_USER_TMP_DIR \
${SBC_OS_VARIANT}_ADMIN_HOME_DIR \
${SBC_OS_VARIANT}_ADMIN_TMP_DIR \
)

ifeq (${${SBC_OS_VARIANT}_LOI_DOWNLOAD},wget)
  $(call require, ${SBC_OS_BOARD}.mk,${SBC_OS_VARIANT}_LOI_IMAGE_URL)
else ifeq (${${SBC_OS_VARIANT}_LOI_DOWNLOAD},google)
  $(call require, ${SBC_OS_BOARD}.mk,${SBC_OS_VARIANT}_LOI_IMAGE_ID)
else
  $(call signal_error,Unsupported download method: ${${SBC_OS_VARIANT}_LOI_DOWNLOAD})
endif

$(info Image download method: ${${SBC_OS_VARIANT}_LOI_DOWNLOAD})
$(info Image unpack method: ${${SBC_OS_VARIANT}_LOI_UNPACK})

# Image download methods.
define download_wget
  wget -O $@ ${${SBC_OS_VARIANT}_LOI_IMAGE_URL}
endef

# Thanks to: https://medium.com/@acpanjan/download-google-drive-files-using-wget-3c2c025a8b99
define download_google
  @echo Downloading from Google.
  wget --load-cookies /tmp/cookies.txt "https://docs.google.com/uc?export=download&confirm=$$(wget --quiet --save-cookies /tmp/cookies.txt --keep-session-cookies --no-check-certificate 'https://docs.google.com/uc?export=download&id=${${SBC_OS_VARIANT}_LOI_IMAGE_ID}' -O- | sed -rn 's/.*confirm=([0-9A-Za-z_]+).*/\1\n/p')&id=${${SBC_OS_VARIANT}_LOI_IMAGE_ID}" -O $@ && rm -rf /tmp/cookies.txt
endef

${DOWNLOADS_DIR}/${${SBC_OS_VARIANT}_LOI_IMAGE_FILE}:
> @echo Downloading $@
> mkdir -p $(@D)
  ifneq (${${SBC_OS_VARIANT}_LOI_DOWNLOAD},)
    ifdef download_${${SBC_OS_VARIANT}_LOI_DOWNLOAD}
>     $(call download_${${SBC_OS_VARIANT}_LOI_DOWNLOAD})
    else
      $(call signal_error,Unsupported download method: ${${SBC_OS_VARIANT}_LOI_DOWNLOAD})
    endif
  else
    $(info Image download method not specified)
  endif

# Image unpack methods.
define _loi_unpack_zip
  unzip $< -d $(@D)
> touch $@
endef

define _loi_unpack_xz
  unxz -c $< > $@
> touch $@
endef

define _loi_unpack_tarz
  tar -xzf $< -C ${LOI_IMAGE_DIR}
> touch $@
endef

${LOI_IMAGE_DIR}/${${SBC_OS_VARIANT}_LOI_IMAGE}: \
  ${DOWNLOADS_DIR}/${${SBC_OS_VARIANT}_LOI_IMAGE_FILE}
> mkdir -p $(@D)
> @echo Extracting $<
> @echo Compressed file type: $(suffix $<)
> @echo Image unpack method: ${${SBC_OS_VARIANT}_LOI_UNPACK}
  ifneq (${${SBC_OS_VARIANT}_LOI_UNPACK},)
    ifdef _loi_unpack_${${SBC_OS_VARIANT}_LOI_UNPACK}
>     $(call _loi_unpack_${${SBC_OS_VARIANT}_LOI_UNPACK})
    else
      $(call signal_error,Unsupported unpack method: ${${SBC_OS_VARIANT}_LOI_UNPACK})
    endif
  else
    $(info Image unpack method not specified)
  endif

${LOI_IMAGE_DIR}/${${SBC_OS_VARIANT}_LOI_IMAGE}-p.json: ${LOI_IMAGE_DIR}/${${SBC_OS_VARIANT}_LOI_IMAGE}
> sfdisk -l --json $< > $@

${LOI_IMAGE_DIR}/${${SBC_OS_VARIANT}_LOI_IMAGE}.mk: \
    ${LOI_IMAGE_DIR}/${${SBC_OS_VARIANT}_LOI_IMAGE}-p.json
> python3 ${HELPER_DIR}/os-image-partitions.py $< > $@

# Get the partition information.
ifneq (${MAKECMDGOALS},help-loi)
  include ${LOI_IMAGE_DIR}/${${SBC_OS_VARIANT}_LOI_IMAGE}.mk
endif

os-image-file: ${DOWNLOADS_DIR}/${${SBC_OS_VARIANT}_LOI_IMAGE_FILE}

os-image: ${LOI_IMAGE_DIR}/${${SBC_OS_VARIANT}_LOI_IMAGE}

define loi_mount_image =
  @if [ ! "${${SBC_OS_VARIANT}_LOI_P1_NAME}" = "" ]; then \
    echo "Mounting: ${${SBC_OS_VARIANT}_LOI_P1_NAME}"; \
    mkdir -p ${LOI_IMAGE_MNT_DIR}/${${SBC_OS_VARIANT}_LOI_P1_NAME}; \
    sudo mount -v -o offset=${SBC_OS_IMAGE_P1_OFFSET},sizelimit=${SBC_OS_IMAGE_P1_SIZE} ${LOI_STAGING_DIR}/${${SBC_OS_VARIANT}_LOI_IMAGE} \
      ${LOI_IMAGE_MNT_DIR}/${${SBC_OS_VARIANT}_LOI_P1_NAME}; \
  fi
  @if [ ! "${${SBC_OS_VARIANT}_LOI_P2_NAME}" = "" ]; then \
    echo "Mounting: ${${SBC_OS_VARIANT}_LOI_P2_NAME}"; \
    mkdir -p ${LOI_IMAGE_MNT_DIR}/${${SBC_OS_VARIANT}_LOI_P2_NAME}; \
    sudo mount -v -o offset=${SBC_OS_IMAGE_P2_OFFSET},sizelimit=${SBC_OS_IMAGE_P2_SIZE} ${LOI_STAGING_DIR}/${${SBC_OS_VARIANT}_LOI_IMAGE} \
      ${LOI_IMAGE_MNT_DIR}/${${SBC_OS_VARIANT}_LOI_P2_NAME}; \
  fi
endef

define loi_unmount_image =
  @if mountpoint -q ${LOI_IMAGE_MNT_DIR}/${${SBC_OS_VARIANT}_LOI_P1_NAME}; then \
    echo "Unmounting: ${${SBC_OS_VARIANT}_LOI_P1_NAME}"; \
    sudo umount ${LOI_IMAGE_MNT_DIR}/${${SBC_OS_VARIANT}_LOI_P1_NAME}; \
    rmdir ${LOI_IMAGE_MNT_DIR}/${${SBC_OS_VARIANT}_LOI_P1_NAME}; \
  fi
  @if mountpoint -q ${LOI_IMAGE_MNT_DIR}/${${SBC_OS_VARIANT}_LOI_P2_NAME}; then \
    echo "Unmounting: ${${SBC_OS_VARIANT}_LOI_P2_NAME}"; \
    sudo umount ${LOI_IMAGE_MNT_DIR}/${${SBC_OS_VARIANT}_LOI_P2_NAME}; \
    rmdir ${LOI_IMAGE_MNT_DIR}/${${SBC_OS_VARIANT}_LOI_P2_NAME}; \
  fi
endef

${LOI_STAGING_DIR}/${${SBC_OS_VARIANT}_LOI_IMAGE}: \
  ${LOI_IMAGE_DIR}/${${SBC_OS_VARIANT}_LOI_IMAGE}
> mkdir -p $(@D)
> cp $< $@

OsDeps = ${LOI_STAGING_DIR}/${${SBC_OS_VARIANT}_LOI_IMAGE}

.PHONY: mount-os-image
mount-os-image: ${LOI_STAGING_DIR}/${${SBC_OS_VARIANT}_LOI_IMAGE}
> $(call loi_mount_image)

.PHONY: unmount-os-image
unmount-os-image:
> -$(call loi_unmount_image)

.PHONY: os-image-partitions
os-image-partitions:
> fdisk -l --bytes ${LOI_IMAGE_DIR}/${${SBC_OS_VARIANT}_LOI_IMAGE}
> -mount | grep ${LOI_IMAGE_MNT_DIR}

.PHONY: os-image-tree
os-image-tree: \
    ${LOI_STAGING_DIR}/${${SBC_OS_VARIANT}_LOI_IMAGE} FORCE
> $(call loi_mount_image)
> cd ${LOI_IMAGE_MNT_DIR}; \
    tree -fi ${${SBC_OS_VARIANT}_LOI_BOOT_DIR} ${${SBC_OS_VARIANT}_LOI_ROOT_DIR} > \
    ${LOI_STAGING_DIR}/${${SBC_OS_VARIANT}_LOI_IMAGE}-tree.txt
> sleep 5 # Allow file system to catch up.
> $(call loi_unmount_image)

.PHONY: list-os-boards
list-os-boards:
> @echo "Available boards:"
> @ls ${LOI_BOARDS_DIR}

# The emulator QEMU is used to run an init script in an OS image environment
# without having to bood the OS on the target board.
/usr/bin/qemu-${SBC_OS_ARCH}:
> sudo apt update
> sudo apt install qemu-user

/usr/bin/proot: | /usr/bin/qemu-${SBC_OS_ARCH}
> sudo apt install proot

ifeq (${MAKECMDGOALS},stage-os-image)
# Start the emulation to aid running the staging scripts.
PROOT = sudo proot -q qemu-${SBC_OS_ARCH} -0 -w /root \
  -r ${LOI_IMAGE_MNT_DIR}/${${SBC_OS_VARIANT}_LOI_ROOT_DIR}

define LoiInitConfig
SBC_OS_ADMIN=${SBC_ADMIN}
SBC_OS_ADMIN_ID=${SBC_ADMIN_ID}
SBC_OS_ADMIN_GID=${SBC_ADMIN_GID}
SBC_OS_USER=${SBC_USER}
SBC_OS_USER_ID=${SBC_USER_ID}
SBC_OS_USER_GID=${SBC_USER_GID}
SBC_INIT=${SBC_INIT_SCRIPT}
endef

export LoiInitConfig
# It is possible the OS image is already mounted.
.PHONY: stage-os-image
stage-os-image: /usr/bin/proot \
    ${LOI_STAGING_DIR}/${${SBC_OS_VARIANT}_LOI_IMAGE} \
    ${LoiInitScripts}
> $(call loi_mount_image)
> printf "%s" "$$LoiInitConfig" > ${_OsImageTmpDir}/options.conf
> cp ${LoiInitScripts} ${_OsImageTmpDir}
> $(call stage_${SBC_OS_VARIANT},${_OsImageTmpDir})
> $(call stage_${SBC_SOFTWARE},${_OsImageTmpDir})
> -${PROOT} ${_OsTmpDir}/stage-${SBC_OS_VARIANT}
> date >${LOI_STAGING_DIR}/${${SBC_OS_VARIANT}_LOI_IMAGE}.staged
> cp ${LOI_STAGING_DIR}/${${SBC_OS_VARIANT}_LOI_IMAGE}.staged ${_OsImageTmpDir}
> $(call loi_unmount_image)

# Use BOOT_DEV to specify the device on the make command line.
ifdef BOOT_DEV
  _Device = --device ${BOOT_DEV}
endif

endif # stage-os-image

${LOI_STAGING_DIR}/${${SBC_OS_VARIANT}_LOI_IMAGE}.staged:
> @echo "Cannot install the OS image. Use stage-os-image first."; exit 1

ifneq (${Platform},Microsoft)
.PHONY: install-os-image
install-os-image: \
  ${LOI_STAGING_DIR}/${${SBC_OS_VARIANT}_LOI_IMAGE}.staged
> cd ${LOI_STAGING_DIR} && \
  ${HELPER_DIR}/makebootable \
    --os-image ${LOI_STAGING_DIR}/${${SBC_OS_VARIANT}_LOI_IMAGE} \
    ${_Device}
else
install-os-image:
> $(call signal_error,USB storage device support is not available in WSL2)
endif

.PHONY: help-makebootable
help-makebootable:
> cd ${LOI_STAGING_DIR} && \
  ${HELPER_DIR}/makebootable --help

.PHONY: os-image-shell
os-image-shell: \
    /usr/bin/proot \
    ${LOI_STAGING_DIR}/${${SBC_OS_VARIANT}_LOI_IMAGE}
> $(call loi_mount_image)
> -${PROOT} /bin/bash
> $(call loi_unmount_image)

.PHONY: clean-os-image
clean-os-image:
> rm ${LOI_STAGING_DIR}/${${SBC_OS_VARIANT}_LOI_IMAGE}

ifeq (${MAKECMDGOALS},help-loi)
define HelpLoiMsg
Using the mount feature other segments can modify the contents of os image
as if it were part of the file system. Typically these modules install a
first time script which runs the first time the OS is booted. The actual
method and contents of these scripts is OS dependent. See the OS segments
for more information (e.g. help-${SBC_OS_VARIANT}).

WARNING: Because of the use of sudo and proot this creates a security risk.
Every effort has been made to avoid corruption of the host OS but use with
caution. Because of this the targets in this make segment must be invoked
explicitly on the make command line and are not invoked from any other make
segment.

Defined in config.mk:
  DOWNLOADS_DIR=${DOWNLOADS_DIR}
    Where to put downladed packaged (e.g. compressed) image files.

Defined in kits.mk:
  MOD_STAGING_DIR = ${MOD_STAGING_DIR}
    Where the mod build output is stored.

Defined in mod.mk:
  SBC_OS_BOARD=${SBC_OS_BOARD}
    Which board to use (show-os-boards for more info).
  SBC_OS_VARIANT=${SBC_OS_VARIANT}
    Which OS variant to use for the selected OS board
    (show-os-variants for more info).

Defined in ${SBC_OS_BOARD}.mk:
  ${SBC_OS_VARIANT}_LOI_IMAGE = ${${SBC_OS_VARIANT}_LOI_IMAGE}
    The OS image (typically .img).
  ${SBC_OS_VARIANT}_LOI_IMAGE_FILE = ${${SBC_OS_VARIANT}_LOI_IMAGE_FILE}
    The OS image package file.
  ${SBC_OS_VARIANT}_LOI_IMAGE_URL = ${${SBC_OS_VARIANT}_LOI_IMAGE_URL}
    Where to download the OS image package file from.
  ${SBC_OS_VARIANT}_LOI_DOWNLOAD = ${${SBC_OS_VARIANT}_LOI_DOWNLOAD}
    The tool to use to download the OS image file.
  ${SBC_OS_VARIANT}_LOI_UNPACK = ${${SBC_OS_VARIANT}_LOI_UNPACK}
    The tool to use to unpack the OS image package.
  ${SBC_OS_VARIANT}_LOI_P1_NAME = ${${SBC_OS_VARIANT}_LOI_P1_NAME}
    The name of the mount point for the first partition.
  ${SBC_OS_VARIANT}_LOI_P2_NAME = ${${SBC_OS_VARIANT}_LOI_P2_NAME}
    The mount point for the second partition if it exists.
    Leave undefined if there is no second partiton.
  ${SBC_OS_VARIANT}_LOI_BOOT_DIR = ${${SBC_OS_VARIANT}_LOI_BOOT_DIR}
    Path to the boot directory.
  ${SBC_OS_VARIANT}_LOI_ROOT_DIR = ${${SBC_OS_VARIANT}_LOI_ROOT_DIR}
    Path to the root directory.

Defines:
  LOI_BOARDS_DIR = ${LOI_BOARDS_DIR}
    Where the board definitions are maintained. Among other things these
    describe the different OS variations that are available for a board.
  LOI_VARIANTS_DIR = ${LOI_VARIANTS_DIR}
    Where the OS variant descriptions are maintained. These describe
    distro specifics for each OS variant.
  LOI_INIT_DIR = ${LOI_INIT_DIR}
    Where variant specific init scripts are maintained. These are designed to
    be run in a QEMU emulation environment. There are two flavors. The first
    is for OS specific initialization and the second for user interface specific
    initialization.
  LOI_IMAGE_DIR = ${LOI_IMAGE_DIR}
    Where OS images are stored. These are copied to the build directory for
    modification.
  LOI_BUILD_DIR = ${LOI_BUILD_DIR}
    Where generated OS related files are stored. These are then copied to the
    OS image when staged.
  LOI_STAGING_DIR = ${LOI_STAGING_DIR}
    Where the modified OS images are stored. Typically this is a subdirectory
    in the mod build directory.
  LOI_IMAGE_MNT_DIR = ${LOI_IMAGE_MNT_DIR}
    Where the OS image partitions are mounted for modification.
  OsDeps = ${OsDeps}
    A list of dependencies needed to mount an OS image.
  loi_mount_image       A callable macro to mount the OS image partitions.
                        Other make segments can call this macro to mount
                        partitions before installing or modifying files in
                        the partitions.
  loi_unmount_image     A callable macro to unmount the OS image partitions.
                        Other make segments can call this macro to unmount
                        partitions.

Command line targets:
  help-loi              Display this help.
  list-os-boards        Display a list of available boards on which an OS
                        can be installed.
  os-image-file         Download the OS image package file.
  os-image              Unpack the OS image package file.
  mount-os-image        Mount the OS image partitions (uses sudo).
  unmount-os-image      Unmount the OS image partitions (uses sudo).
  os-image-partitions   Display the partitions in an OS image and where they
                        are moounted. This can be used to determine offsets
                        and sizes. NOTE: The displayed size is in bytes but
                        the offsets are the number of 512 byte sectors.
  os-image-tree         Generates a text file containing a full list of Files
                        in the OS image. This can be used for locating files
                        in the image without having to mount it.
  stage-os-image        Use QEMU and proot to prepare an OS image for firstrun
                        initialization. Staging scripts are run using
                        the target OS in an emulation environment.
  install-os-image      Install the OS image file onto a USB flash card to
                        make the card bootable on the target device. This
                        uses the helper script makebootable. The makebootable
                        options are saved in ~/.modfw/makebootable. The
                        boot device defaults to a device scan or the previous
                        device. Use BOOT_DEV on the command line to specify
                        which device to install the OS image to.
  help-makebootable     Display the help and current options for the
                        makebootable helper script.
  os-image-shell        Use QEMU and proot to start a shell session using the
                        OS image in an emulation environment.
  clean-os-image        Remove the OS image file from the staging directory.

Command line variables:
  BOOT_DEV=<device>     (optional) This is used by install-os-image to select
                        which device to install the OS onto. This must be a
                        removable USB storage device and defaults to the
                        first removable USB storage found in a downward scan
                        from sdj to sdc.

Uses:
  stage_${SBC_OS_VARIANT} defined in ${SBC_OS_VARIANT}.mk

endef

export HelpLoiMsg
help-loi:
> @echo "$$HelpLoiMsg" | less
endif
