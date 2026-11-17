#include <stdio.h>

#define YEAR_MIN 1900
#define YEAR_MAX 2099

static const char* const month_names[12] = {
    "January", "February", "March",     "April",   "May",      "June",
    "July",    "August",   "September", "October", "November", "December"};

static const int month_days[12] = {31, 28, 31, 30, 31, 30,
                                   31, 31, 30, 31, 30, 31};

static int is_leap_year(int year) {
  if (year % 4 != 0) return 0;
  if (year % 400 == 0) return 1;
  if (year % 100 == 0) return 0;
  return 1;
}

static int days_in_month(int year, int month) {
  int days = month_days[month - 1];

  if (month == 2 && is_leap_year(year)) ++days;

  return days;
}

/*
 * Sakamoto 算法：返回某年某月 1 号是星期几，0=周日，1=周一，...，6=周六
 * 公式：(y + y/4 - y/100 + y/400 + t[m-1] + d) % 7，d=1
 * 其中 1、2 月要把年份减 1，避免闰日提前计入
 */
static int day_of_week(int year, int month) {
  static const int shift[12] = {0, 3, 2, 5, 0, 3, 5, 1, 4, 6, 2, 4};
  int y = year;

  if (month < 3) --y;

  return (y + y / 4 - y / 100 + y / 400 + shift[month - 1] + 1) % 7;
}

/*
 * 读入一个整数，范围 [min, max]，不合法则重新提示
 */
static int read_number(const char* prompt, int min, int max) {
  int value;
  int ch;

  for (;;) {
    printf("%s", prompt);

    if (scanf("%d", &value) == 1 && value >= min && value <= max) return value;

    while ((ch = getchar()) != '\n' && ch != EOF);
  }
}

/* 输出月份名：通过字符指针取字符串*/
static void print_month_name(int month) {
  const char* name = month_names[month - 1];

  printf("%s", name);
}

/* 输出一个日期数字 */
static void print_day(int day) { printf("%2d ", day); }

static void print_week_header(void) { printf("Su Mo Tu We Th Fr Sa\n"); }

/* 输出整月日历 */
static void print_calendar(int year, int month) {
  int first;  // 1 号是星期几
  int days;   // 本月天数
  int i;

  first = day_of_week(year, month);
  days = days_in_month(year, month);

  /* 先空一行，再输出“年份 月份” */
  printf("\n%4d ", year);
  print_month_name(month);
  printf("\n");

  print_week_header();

  /* 1 号之前的空位，每个空位 3 个空格*/
  for (i = 0; i < first; ++i) printf("   ");

  /* 逐日输出，每逢周六之后换行 */
  for (i = 1; i <= days; ++i) {
    print_day(i);

    /* 最后一天不在这里换行，统一由下面补一个换行 */
    if ((first + i) % 7 == 0 && i != days) printf("\n");
  }

  printf("\n");
}

int main(void) {
  int year;
  int month;

  year = read_number("PLEASE INPUT YEAR (1900-2099): ", YEAR_MIN, YEAR_MAX);
  month = read_number("PLEASE INPUT MONTH (1-12): ", 1, 12);

  print_calendar(year, month);

  return 0;
}
