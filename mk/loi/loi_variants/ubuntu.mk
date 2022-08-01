#+
# OS Variant definitions for the Ubuntu OS.
#-
$(info Using OS variant: ${SBC_OS_VARIANT})

ifeq (${MAKECMDGOALS},help-ubuntu)
define HelpUbuntuMsg
Make segment: ubuntu.mk

Generalizes access to an Ubuntu based OS image.

Defines:

Command line targets:

Uses:

endef

export HelpUbuntuMsg
help-options:
> @echo "$$HelpUbuntuMsg"

endif
