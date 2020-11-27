CC=gcc
#CPPFLAGS=-I/usr/include
CFLAGS=-Wall -Werror -Wextra -pedantic
#CFLAGS+=-std=c99
#LDFLAGS=-nodefaultlibs -L/usr/lib
TARGET=myprog
BUILD_DIR=./build

#         | Input from system           | Makefile variables        | Preprocessor #defines
#         | $OS           uname         | KERNEL      ENV           |  MINGW   CYGWIN  LINUX    OSX
# ========|=============================|===========================|==============================
# mingw   | Windows_NT    MINGW32_NT-*  | Windows     MINGW32_NT    |  1
# cygwin  | Windows_NT    CYGWIN_NT-*   | Windows     CYGWIN_NT     |          1
# WSL     | (undefined)   Linux         | Linux       Linux         |                  1
# Mac     | (undefined)   Darwin        | Darwin      Darwin        |                           1

UNAME := $(shell uname | grep -oE "MINGW32_NT|CYGWIN_NT|Linux|Darwin")

ifeq ($(OS),Windows_NT)
	KERNEL := Windows
else
	KERNEL := $(UNAME)
endif
ENV := $(UNAME)

ifneq ($(ENV), MINGW32_NT)
	LDLIBS += -lpthread
endif

ifeq ($(KERNEL),Windows)
	ifeq ($(ENV), CYGWIN_NT)
		CPPFLAGS += -D CYGWIN
	endif
	ifeq ($(ENV), MINGW32_NT)
		CPPFLAGS += -D MINGW -D _WIN32_WINNT=_WIN32_WINNT_WIN7
	endif
	TARGET := $(TARGET).exe
endif
ifeq ($(KERNEL),Linux)
	CPPFLAGS += -D LINUX
endif
ifeq ($(KERNEL),Darwin)
	CPPFLAGS += -D OSX
endif

SRC = main.c
OBJ = $(SRC:%.c=$(BUILD_DIR)/%.o)
DEP = $(OBJ:%.o=%.d)

.PHONY: all clean

all: $(BUILD_DIR)/$(TARGET)

$(BUILD_DIR)/$(TARGET): $(OBJ)
	mkdir -p $(@D)
	$(CC) $(LDFLAGS) $^ -o $@ $(LDLIBS)
	ln -sf $(BUILD_DIR)/$(TARGET)

$(BUILD_DIR)/%.o: %.c
	mkdir -p $(@D)
	$(CC) $(CPPFLAGS) $(CFLAGS) -MMD -c $< -o $@

-include $(DEP)

clean:
	rm -rf $(BUILD_DIR) $(TARGET)
