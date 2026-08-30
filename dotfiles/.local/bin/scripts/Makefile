CC = gcc
CFLAGS = -O2 -Wall -Wextra
TARGET = qb-open

# C 动态链接（调试用）
c-dynamic: qb-open.c
	$(CC) $(CFLAGS) -o $(TARGET) qb-open.c

# C 静态链接
c-static: qb-open.c
	musl-gcc $(CFLAGS) -static -o $(TARGET) qb-open.c

clean:
	rm -f $(TARGET)

.PHONY: c-dynamic c-static clean
