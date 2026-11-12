#include <stdio.h>
int n;
int fib[101][22];
const int max_len = 21;
void calc(int n) {
  if (fib[n][0] != 0) return;  // 已计算，则直接返回
  calc(n - 2);
  calc(n - 1);
  for (int i = 1; i <= max_len; ++i) {
    fib[n][i] += fib[n - 1][i] + fib[n - 2][i];  // 使用+=是因为会有进位
    if (fib[n][i] >= 10) {
      fib[n][i] %= 10;
      fib[n][i + 1] = 1;  // 发生一次进位
    }
  }
  fib[n][0] = 1;
}
int main() {
  printf("please enter a decimal number between 0 and 100\n");
  fib[0][0] = 1;  // 标记为已计算
  fib[1][0] = 1;  // 标记为已计算
  fib[1][1] = 1;  // 赋初值
  scanf("%d", &n);
  printf("The value of that term in the Fibonacci sequence is :\n");
  calc(n);
  int first = max_len;
  for (; first > 1; --first) {
    if (fib[n][first] != 0) break;  // 去除前导零
  }
  for (; first >= 1; --first) {
    printf("%d", fib[n][first]);
  }
  return 0;
}