#ifndef __CPU_CPU_H__
#define __CPU_CPU_H__

#define rdtsc(low, high) \
    __asm__ __volatile__("rdtsc" : "=a"(low), "=d"(high))

#define rdtscl(low) \
    __asm__ __volatile__("rdtsc" : "=a"(low) : : "edx")

#define rdtscll(val) \
    __asm__ __volatile__("rdtsc" : "=A"(val))

#define rdpmc(counter, low, high)                \
    __asm__ __volatile__("rdpmc"                 \
                         : "=a"(low), "=d"(high) \
                         : "c"(counter))

extern void          intel_interrupts_on(void);
extern void          cache_disable(void);
extern void          cache_enable(void);
extern void          cpuid(int op, unsigned int *eax, unsigned int *ebx, unsigned int *ecx, unsigned int *edx);
extern unsigned long getCPUFreq(void);
void                 display_cpuid_update_microcode(void);
void                 setup_ioapic(void);

#endif
