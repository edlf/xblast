/*
 * OHCI HCD (Host Controller Driver) for USB.
 *
 * (C) Copyright 1999 Roman Weissgaerber <weissg@vienna.at>
 * (C) Copyright 2000-2002 David Brownell <dbrownell@users.sourceforge.net>
 *
 * [ Initialisation is based on Linus'  ]
 * [ uhci code and gregs ohci fragments ]
 * [ (C) Copyright 1999 Linus Torvalds  ]
 * [ (C) Copyright 1999 Gregory P. Smith]
 *
 * PCI Bus Glue
 *
 * This file is licenced under the GPL.
 */

#include "string.h"

static int __devinit
ohci_pci_start (struct usb_hcd *hcd) {
    struct ohci_hcd *ohci = hcd_to_ohci(hcd);
    int        ret;

    if (hcd->pdev) {
        ohci->hcca = pci_alloc_consistent (hcd->pdev, sizeof *ohci->hcca, &ohci->hcca_dma);
        if (!ohci->hcca) {
            return -ENOMEM;
        }

        /* AMD 756, for most chips (early revs), corrupts register
         * values on read ... so enable the vendor workaround.
         */
        if (hcd->pdev->vendor == PCI_VENDOR_ID_AMD && hcd->pdev->device == 0x740c) {
            ohci->flags = OHCI_QUIRK_AMD756;
            ohci_info (ohci, "AMD756 erratum 4 workaround\n");
        }
    }

    memset (ohci->hcca, 0, sizeof (struct ohci_hcca));
    if ((ret = ohci_mem_init (ohci)) < 0) {
        ohci_stop (hcd);
        return ret;
    }
    ohci->regs = hcd->regs;

    if (hc_reset (ohci) < 0) {
        ohci_stop (hcd);
        return -ENODEV;
    }

    if (hc_start (ohci) < 0) {
        ohci_err (ohci, "can't start\n");
        ohci_stop (hcd);
        return -EBUSY;
    }

#ifdef    DEBUG
    ohci_dump (ohci, 1);
#endif
    return 0;
}

static const struct hc_driver ohci_pci_hc_driver = {
    .description =        hcd_name,

    /*
     * generic hardware linkage
     */
    .irq =            ohci_irq,
    .flags =        HCD_MEMORY | HCD_USB11,

    /*
     * basic lifecycle operations
     */
    .start =        ohci_pci_start,
    .stop =            ohci_stop,

    /*
     * memory lifecycle (except per-request)
     */
    .hcd_alloc =        ohci_hcd_alloc,
    .hcd_free =        ohci_hcd_free,

    /*
     * managing i/o requests and associated device resources
     */
    .urb_enqueue =        ohci_urb_enqueue,
    .urb_dequeue =        ohci_urb_dequeue,
    .endpoint_disable =    ohci_endpoint_disable,

    /*
     * scheduling support
     */
    .get_frame_number =    ohci_get_frame,

    /*
     * root hub support
     */
    .hub_status_data =    ohci_hub_status_data,
    .hub_control =        ohci_hub_control,
};

static const struct pci_device_id __devinitdata pci_ids [] = { {
    /* handle any USB OHCI controller */
    .class =    (PCI_CLASS_SERIAL_USB << 8) | 0x10,
    .class_mask =    ~0,
    .driver_data =    (unsigned long) &ohci_pci_hc_driver,

    /* no matter who makes it */
    .vendor =    PCI_ANY_ID,
    .device =    PCI_ANY_ID,
    .subvendor =    PCI_ANY_ID,
    .subdevice =    PCI_ANY_ID,

    }, { /* end: all zeroes */ }
};
MODULE_DEVICE_TABLE (pci, pci_ids);

static void __exit ohci_hcd_pci_cleanup (void) {
    pci_unregister_driver (&ohci_pci_driver);
}

module_exit (ohci_hcd_pci_cleanup);
