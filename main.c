#include <stdio.h>
#include "test.h"

int main() {
    Box a = { .n = 4 };
    Box b = { .n = 2 };
    
    long result = add(&a, &b);
    printf("%ld\n", result);
}
