#include "test.h"

unsigned long add(Box *a, Box *b) {
    return a->n + b->n;
}

void add_in_place(Box *a, Box *b) {
    b->n = a->n + b->n;
}
