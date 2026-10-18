#include <stdio.h>

int main() {
  char c = 'a';
  for (int i = 2; i; --i) {
    for (int j = 1; j <= 13; ++j) {
      printf("%c ", c);
      ++c;
    }
    printf("\n");
  }
  return 0;
}