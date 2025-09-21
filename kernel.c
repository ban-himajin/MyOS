#include "stdio.h"

__attribute__((section(".text.start")))

void _kernel_main(void){
    clean_screen();
    vk_puts("C language kernel!\n");
    vk_puts("hello world!\n");
    while(1);
}