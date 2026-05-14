#ifndef ETHERBOOT_OSDEP_H
#define ETHERBOOT_OSDEP_H

#define __unused  __attribute__((unused))
#define __aligned __attribute__((aligned(16)))

/* Optimization barrier */
/* The "volatile" is due to gcc bugs */
#define barrier() __asm__ __volatile__("" : : : "memory")

#include "byteswap.h"
#include "endian.h"
#include "io.h"
#include "latch.h"
#include "limits.h"
#include "setjmp.h"
#include "string.h"
#include <stdint.h>

typedef unsigned long Address;

/* ANSI prototyping macro */
#ifdef __STDC__
#define P(x) x
#else
#define P(x) ()
#endif

#endif
