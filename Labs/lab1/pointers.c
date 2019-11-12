#include <stdio.h>
#include <stdlib.h>

void f(void) {
    int a[4];
    int *b = malloc(16);
    int *c;
    int i;

    printf("1: a = %p, b = %p, c = %p\n", a, b, c);

    c = a;
    for (i = 0; i < 4; i++)
        a[i] = 100 + i;
    // a[4]: 100, 101, 102, 103

    c[0] = 200;
    // a[4]: 200, 101, 102, 103
    printf("2: a[0] = %d, a[1] = %d, a[2] = %d, a[3] = %d\n",
           a[0], a[1], a[2], a[3]);

    c[1] = 300;
    // a[4]: 200, 301, 102, 103

    *(c + 2) = 301;
    // a[4]: 200, 301, 301, 103

    3[c] = 302;  // Not 100% sure
    // a[4]: 200, 301, 301, 302

    printf("3: a[0] = %d, a[1] = %d, a[2] = %d, a[3] = %d\n",
           a[0], a[1], a[2], a[3]);

    c = c + 1; // c = (a + 1)
    *c = 400;
    // a[4]: 200, 400, 301, 302

    printf("4: a[0] = %d, a[1] = %d, a[2] = %d, a[3] = %d\n",
           a[0], a[1], a[2], a[3]);

    c = (int *)((char *)c + 1);
    // Each int is 32-bit but each char is 8-bit. c now points to the
    // second word of a[1]
    *c = 500;
    printf("5: a[0] = %d, a[1] = %d, a[2] = %d, a[3] = %d\n",
           a[0], a[1], a[2], a[3]);

    b = (int *)a + 1;
    c = (int *)((char *)a + 1);
    printf("6: a = %p, b = %p, c = %p\n", a, b, c);
}

int main(int ac, char **av) {
    f();
    return 0;
}
