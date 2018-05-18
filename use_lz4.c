#include <lz4.h>
#include <stdio.h>
int main()
{
    int good = (LZ4_VERSION_MAJOR > 1) ||
        ((LZ4_VERSION_MAJOR == 1) && (LZ4_VERSION_MINOR >= 7));
    printf("%i.%i\n", LZ4_VERSION_MAJOR, LZ4_VERSION_MINOR);

    size_t max_size = LZ4_compressBound(512);
    printf("%i\n", max_size);
}