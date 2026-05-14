/* Tiny module to test USB encapsulation
 * (c) 2003, Georg Acher, georg@acher.org
 */
#include <linux/module.h>
#include <linux/socket.h>
#include <linux/miscdevice.h>
#include <linux/slab.h>
#include <linux/sched.h>
#include <linux/delay.h>
#include <asm/hardirq.h>
#include <linux/pci.h>
/*------------------------------------------------------------------------*/
 void my_wait_ms(unsigned int ms)
{
//        if(!in_interrupt()) {

                current->state = TASK_UNINTERRUPTIBLE;
                schedule_timeout(1 + ms * HZ / 1000);
//        }
//        else
//                mdelay(ms);
}
/*------------------------------------------------------------------------*/
void my_mdelay(int x)
{
    mdelay(x);
}
/*------------------------------------------------------------------------*/
void my_udelay(int x)
{
    udelay(x);
}
/*------------------------------------------------------------------------*/

/*------------------------------------------------------------------------*/
void* zxmalloc(size_t  s)
{
    return kmalloc(s,GFP_DMA);
}
/*------------------------------------------------------------------------*/
void zxfree(void* x)
{
    kfree(x);
}
/*------------------------------------------------------------------------*/
void zxprintf(char* fmt, ...)
{
    va_list ap;
    char buffer[1024];
    va_start(ap, fmt);
    vsnprintf(buffer,1024,fmt,ap);
    usbprintk(buffer);
    va_end(ap);
}
/*------------------------------------------------------------------------*/
int zxsnprintf(char *buffer, size_t s, char* fmt, ...)
{
    va_list ap;
    int x;
    va_start(ap, fmt);
    x=vsnprintf(buffer,s,fmt,ap);
    va_end(ap);
    return x;
}
/*------------------------------------------------------------------------*/
int zxsprintf(char *buffer, char* fmt, ...)
{
    va_list ap;
    int x;
    va_start(ap, fmt);
    x=vsprintf(buffer,fmt,ap);
    va_end(ap);
    return x;
}
