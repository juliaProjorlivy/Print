#include <stdio.h>
extern "C" int MyPrint(const char *format, ...);

int main()
{
    const char *string = "here we go again!";
    MyPrint("MuMu %s %d %d %o %b %x %% %x", string, 1, 2, 9, 9, 9, 20);
    printf("\n");
    MyPrint("MuMu %x %x", -10, 122);
    return 0;
}

