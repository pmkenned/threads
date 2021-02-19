CC = gcc
CPPFLAGS =
CFLAGS = -Wall -Wextra -pedantic -std=c99 -O2
LDFLAGS = 
LDLIBS = 

TARGET = myprog
BUILD_DIR = ./build
SRC = main.c
OBJ = $(SRC:%.c=$(BUILD_DIR)/%.o)
DEP = $(OBJ:%.o=%.d)

include os.mk

ifeq ($(KERNEL),Windows)
	ifeq ($(ENV), CYGWIN_NT)
		LDLIBS += -lpthread
	endif
	ifeq ($(ENV), MINGW32_NT)
		CPPFLAGS += -Ic:/MinGW/include/ncursesw/
		LDFLAGS += -Lc:/MinGW/lib/
	endif
	TARGET := $(TARGET).exe
endif
ifeq ($(KERNEL),Linux)
	LDLIBS += -lpthread
endif
ifeq ($(KERNEL),Darwin)
	LDLIBS += -lpthread
endif

.PHONY: all run clean

all: $(BUILD_DIR)/$(TARGET)
ifeq ($(ENV), MINGW32_NT)
ifeq (,$(wildcard $(BUILD_DIR)/*.dll))
	cp c:/MinGW/bin/libgcc_s_dw2-1.dll $(BUILD_DIR)/
endif
endif

run: $(BUILD_DIR)/$(TARGET)
	$(BUILD_DIR)/$(TARGET)

$(BUILD_DIR)/$(TARGET): $(OBJ)
	mkdir -p $(@D)
	$(CC) $(LDFLAGS) $^ -o $@ $(LDLIBS)

$(BUILD_DIR)/%.o: %.c
	mkdir -p $(@D)
	$(CC) $(CPPFLAGS) $(CFLAGS) -MMD -c $< -o $@

-include $(DEP)

clean:
	rm -rf $(BUILD_DIR)
