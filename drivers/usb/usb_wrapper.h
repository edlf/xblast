#include "linux_wrapper.h"
#define __KERNEL__
#undef CONFIG_PCI
#define CONFIG_PCI

#include "cromwell.h"
#include "linux/usb.h"
