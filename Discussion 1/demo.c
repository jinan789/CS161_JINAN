#include<stdio.h>

void write(char buff[]) {
    for (int i = 0; i < 16; i += 1) 
        buff[i] = (char) i;
}
int main()
{
   char buff [16];
   
   write(buff);

   return 0;
}