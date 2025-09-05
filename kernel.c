#include "stdio.h"

void kernel_main(void) {
    vk_puts("helloworld");
}

// void _kernel_main(void){
//     volatile unsigned char* vga = (volatile unsigned char*)0xB8000;
//     vga[0] = 'H';
//     vga[1] = 0x07;  // 白文字・黒背景
//     while(1);        // CPU停止
// }
