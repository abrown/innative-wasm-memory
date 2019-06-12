typedef struct Box_ {
    unsigned long n;
} Box;

unsigned long add(Box *a, Box *b);
void add_in_place(Box *a, Box *b);
