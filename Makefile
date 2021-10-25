# Based on https://matansilver.com/2017/08/29/universal-makefile/
# Modified by MaxXing

# Flags
CFLAGS := -Wall -std=c11
CXXFLAGS := -Wall -Wno-register -std=c++17
FFLAGS :=
BFLAGS := -d
LDFLAGS :=

# Debug flags
DEBUG ?= 0
ifeq ($(DEBUG), 0)
CFLAGS += -g -O0
CXXFLAGS += -g -O0
else
CFLAGS += -O2
CXXFLAGS += -O2
endif

# Compilers
CC := gcc
CXX := g++
FLEX := flex
BISON := bison

# Directories
TOP_DIR := $(shell pwd)
TARGET_EXEC := compiler
BUILD_DIR ?= $(TOP_DIR)/build
SRC_DIR := $(TOP_DIR)/src

# Source files & target files
FB_SRCS := $(patsubst $(SRC_DIR)/%.l, $(BUILD_DIR)/%.lex.cpp, $(shell find $(SRC_DIR) -name *.l))
FB_SRCS += $(patsubst $(SRC_DIR)/%.y, $(BUILD_DIR)/%.tab.cpp, $(shell find $(SRC_DIR) -name *.y))
SRCS := $(FB_SRCS) $(shell find $(SRC_DIR) -name *.c -or -name *.cpp -or -name *.cc)
OBJS := $(patsubst $(BUILD_DIR)/%.c, $(BUILD_DIR)/%.c.o, $(SRCS))
OBJS := $(patsubst $(BUILD_DIR)/%.cpp, $(BUILD_DIR)/%.cpp.o, $(OBJS))
OBJS := $(patsubst $(BUILD_DIR)/%.cc, $(BUILD_DIR)/%.cc.o, $(OBJS))
OBJS := $(patsubst $(SRC_DIR)/%.c, $(BUILD_DIR)/%.c.o, $(OBJS))
OBJS := $(patsubst $(SRC_DIR)/%.cpp, $(BUILD_DIR)/%.cpp.o, $(OBJS))
OBJS := $(patsubst $(SRC_DIR)/%.cc, $(BUILD_DIR)/%.cc.o, $(OBJS))

# Header directories & dependencies
INC_DIRS := $(shell find $(SRC_DIR) -type d)
INC_DIRS += $(INC_DIRS:$(SRC_DIR)%=$(BUILD_DIR)%)
INC_FLAGS := $(addprefix -I, $(INC_DIRS))
DEPS := $(OBJS:.o=.d)
CPPFLAGS = $(INC_FLAGS) -MMD -MP


# Main target
$(BUILD_DIR)/$(TARGET_EXEC): $(FB_SRCS) $(OBJS)
	$(CXX) $(LDFLAGS) $(OBJS) -o $@

# C source
$(BUILD_DIR)/%.c.o: $(SRC_DIR)/%.c
	mkdir -p $(dir $@)
	$(CC) $(CPPFLAGS) $(CFLAGS) -c $< -o $@

# C++ source
define cxx_recipe
	mkdir -p $(dir $@)
	$(CXX) $(CPPFLAGS) $(CXXFLAGS) -c $< -o $@
endef
$(BUILD_DIR)/%.cpp.o: $(SRC_DIR)/%.cpp; $(cxx_recipe)
$(BUILD_DIR)/%.cpp.o: $(BUILD_DIR)/%.cpp; $(cxx_recipe)
$(BUILD_DIR)/%.cc.o: $(SRC_DIR)/%.cc; $(cxx_recipe)

# Flex
$(BUILD_DIR)/%.lex.cpp: $(SRC_DIR)/%.l
	mkdir -p $(dir $@)
	$(FLEX) $(FFLAGS) -o $@ $<

# Bison
$(BUILD_DIR)/%.tab.cpp: $(SRC_DIR)/%.y
	mkdir -p $(dir $@)
	$(BISON) $(BFLAGS) -o $@ $<


.PHONY: clean

clean:
	-rm -rf $(BUILD_DIR)

-include $(DEPS)
