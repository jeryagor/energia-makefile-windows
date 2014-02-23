#_______________________________________________________________________________
#
# Energia makefile for Windows
#_______________________________________________________________________________
#
# Copyright (C) 2014 Jeremy Ozog
# Copyright (C) 2013 Alessandro Pasotti
# Copyright (C) 2011, 1012 Tim Marston <tim@ed.am>.
#
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in
# all copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
# SOFTWARE.
#
#_______________________________________________________________________________
#
# This is a makefile for use with TI's MSP430 Launchpad hardware.
# It can be used as a replacement for the Energia IDE.
#
# This makefile is based on the previous work of Alessandro Pasotti.
# It has been slightly cleaned and modify to run under Windows with MinGW / MSYS. 
#
# The Energia software is required. You need to point to its installation by
# setting an environment variable:
#     set ENERGIADIR=/C/somewhere
# Please note that makefile forbids the usage of colons in filepaths.
# In the example above, MSYS-style paths are used (see readme for installation)
# instructions.
#
# You will also need to set the type of MSP430 board you are using.
# Type `make boards` for a list of acceptable values.
#     set ENERGIABOARD=lpmsp430g2553
#
# In case you use a specific version of the Energia software, you may want to
# indicate it through the following values:
#     ARDUINOCONST => defaults to 101 if not provided
#     ENERGIACONST => defaults to  11 if not provided
#
# This makefile defines the following goals for use on the command line when you
# run make:
#
# all          This is the default if no goal is specified.
#              It builds the target.
#
# target       Build the target.
#
# run          Build, upload and run the target on an attached Launchpad.
#
# clean        Delete files created during the build.
#
# boards       Display a list of available board names, so that you can set the
#              ENERGIABOARD environment variable appropriately.
#
# size         Display size information about the built target.
#_______________________________________________________________________________
#

# Default Arduino and Energia versions
ARDUINOCONST ?= 101
ENERGIACONST ?= 11

# Default Energia software directory, value has to be provided by the user
ifndef ENERGIADIR
$(error ENERGIADIR is not set correctly; Energia software not found)
endif

# Check for .ino files in the working directory
INOFILE := $(wildcard *.ino *.pde)
ifdef INOFILE

ifneq "$(words $(INOFILE))" "1"
$(error There is more than one .pde or .ino file in this directory!)
endif

# Automatically determine sources and targeet
TARGET := $(basename $(INOFILE))
SOURCES := $(INOFILE) \
	$(wildcard *.c *.cc *.cpp) \
	$(wildcard $(addprefix util/, *.c *.cc *.cpp)) \
	$(wildcard $(addprefix utility/, *.c *.cc *.cpp))

# Automatically determine included libraries
LIBRARIES := $(filter $(notdir $(wildcard $(HOME)/energia_sketchbook/libraries/*)), \
    $(shell sed -ne "s/^ *\# *include *[<\"]\(.*\)\.h[>\"]/\1/p" $(SOURCES)))
LIBRARIES += $(filter $(notdir $(wildcard $(ENERGIADIR)/hardware/msp430/libraries/*)), \
	$(shell sed -ne "s/^ *\# *include *[<\"]\(.*\)\.h[>\"]/\1/p" $(SOURCES)))

endif

# Software
CC := msp430-gcc
CXX := msp430-g++
AR := msp430-ar
MSPDEBUG := mspdebug
MSP430SIZE := msp430-size

# Files
TARGET := $(if $(TARGET),$(TARGET),a.out)
OBJECTS := $(addsuffix .o, $(basename $(SOURCES)))
DEPFILES := $(patsubst %, .dep/%.dep, $(SOURCES))
ENERGIACOREDIR := $(ENERGIADIR)/hardware/msp430/cores/msp430
ENERGIALIB := .lib/arduino.a
ENERGIALIBLIBSDIR := $(ENERGIADIR)/hardware/msp430/libraries
ENERGIALIBLIBSPATH := $(foreach lib, $(LIBRARIES), \
	 $(HOME)/energia_sketchbook/libraries/$(lib)/ $(HOME)/energia_sketchbook/libraries/$(lib)/utility/ $(ENERGIADIR)/libraries/$(lib)/ $(ENERGIADIR)/libraries/$(lib)/utility/)
ENERGIALIBOBJS := $(foreach dir, $(ENERGIACOREDIR) $(ENERGIALIBLIBSPATH), \
	$(patsubst %, .lib/%.o, $(wildcard $(addprefix $(dir)/, *.c *.cpp))))

# No board?
ifndef ENERGIABOARD
ifneq "$(MAKECMDGOALS)" "boards"
ifneq "$(MAKECMDGOALS)" "clean"
$(error ENERGIABOARD is unset.  Type 'make boards' to see possible values.)
endif
endif
endif

# Obtain board parameters from the Energia boards.txt file
BOARDS_FILE := $(ENERGIADIR)/hardware/msp430/boards.txt
BOARD_BUILD_MCU := $(shell sed -ne "s/$(ENERGIABOARD).build.mcu=\(.*\)/\1/p" $(BOARDS_FILE))
BOARD_BUILD_FCPU := $(shell sed -ne "s/$(ENERGIABOARD).build.f_cpu=\(.*\)/\1/p" $(BOARDS_FILE))
BOARD_BUILD_VARIANT := $(shell sed -ne "s/$(ENERGIABOARD).build.variant=\(.*\)/\1/p" $(BOARDS_FILE))
BOARD_UPLOAD_SPEED := $(shell sed -ne "s/$(ENERGIABOARD).upload.speed=\(.*\)/\1/p" $(BOARDS_FILE))
BOARD_UPLOAD_PROTOCOL := $(shell sed -ne "s/$(ENERGIABOARD).upload.protocol=\(.*\)/\1/p" $(BOARDS_FILE))

# Invalid board?
ifeq "$(BOARD_BUILD_MCU)" ""
ifneq "$(MAKECMDGOALS)" "boards"
ifneq "$(MAKECMDGOALS)" "clean"
$(error ENERGIABOARD is invalid.  Type 'make boards' to see possible values.)
endif
endif
endif

# Flags
CPPFLAGS := -Os -Wall
CPPFLAGS += -ffunction-sections -fdata-sections
CPPFLAGS += -mmcu=$(BOARD_BUILD_MCU)
CPPFLAGS += -DF_CPU=$(BOARD_BUILD_FCPU) -DARDUINO=$(ARDUINOCONST)  -DENERGIA=$(ENERGIACONST)
CPPFLAGS += -I. -Iutil -Iutility -I$(ENERGIACOREDIR)
CPPFLAGS += -I$(ENERGIADIR)/hardware/msp430/variants/$(BOARD_BUILD_VARIANT)/
CPPFLAGS += -I$(HOME)/energia_sketchbook/hardware/msp430/variants/$(BOARD_BUILD_VARIANT)/
CPPFLAGS += $(addprefix -I$(HOME)/energia_sketchbook/libraries/,  $(LIBRARIES))
CPPFLAGS += $(patsubst %, -I$(HOME)/energia_sketchbook/libraries/%/utility,  $(LIBRARIES))
CPPFLAGS += $(addprefix -I$(ENERGIADIR)/libraries/, $(LIBRARIES))
CPPFLAGS += $(patsubst %, -I$(ENERGIADIR)/libraries/%/utility, $(LIBRARIES))
CPPDEPFLAGS = -MMD -MP -MF .dep/$<.dep
CPPINOFLAGS := -x c++ -include $(ENERGIACOREDIR)/Arduino.h
MSPDEBUGFLAGS :=  tilib --force-reset 'prog $(TARGET).elf'
LINKFLAGS := -mmcu=$(BOARD_BUILD_MCU) -Os -Wl,-gc-sections,-u,main -lm

# Include dependencies
ifneq "$(MAKECMDGOALS)" "clean"
-include $(DEPFILES)
endif

# Default rule
.DEFAULT_GOAL := all

#_______________________________________________________________________________
#                                                                          RULES

all: target

target: $(TARGET).elf

run: $(TARGET).elf
	$(MSPDEBUG) $(MSPDEBUGFLAGS)

clean:
	rm -f $(OBJECTS)
	rm -f $(TARGET).elf $(ENERGIALIB) *~
	rm -rf .lib .dep

boards:
	@echo Available values for BOARD:
	@sed -ne '/^#/d; /^[^.]\+\.name=/p' $(BOARDS_FILE) | \
		sed -e 's/\([^.]\+\)\.name=\(.*\)/\1            \2/' \
			-e 's/\(.\{14\}\) *\(.*\)/\1 \2/'

size: $(TARGET).elf
	echo && $(MSP430SIZE) $(TARGET).elf

# Building the target

$(TARGET).elf: $(ENERGIALIB) $(OBJECTS)
	$(CC) $(LINKFLAGS) $(OBJECTS) $(ENERGIALIB) -o $@

%.o: %.c
	mkdir -p .dep/$(dir $<)
	$(COMPILE.c) $(CPPDEPFLAGS) -o $@ $<

%.o: %.cpp
	mkdir -p .dep/$(dir $<)
	$(COMPILE.cpp) $(CPPDEPFLAGS) -o $@ $<

%.o: %.cc
	mkdir -p .dep/$(dir $<)
	$(COMPILE.cpp) $(CPPDEPFLAGS) -o $@ $<

%.o: %.C
	mkdir -p .dep/$(dir $<)
	$(COMPILE.cpp) $(CPPDEPFLAGS) -o $@ $<

%.o: %.ino
	mkdir -p .dep/$(dir $<)
	$(COMPILE.cpp) $(CPPDEPFLAGS) -o $@ $(CPPINOFLAGS) $<

%.o: %.pde
	mkdir -p .dep/$(dir $<)
	$(COMPILE.cpp) $(CPPDEPFLAGS) -o $@ -x c++ -include $(ENERGIACOREDIR)/Arduino.h $<

# Building the Energia library

$(ENERGIALIB): $(ENERGIALIBOBJS)
	$(AR) rcs $@ $?

.lib/%.c.o: %.c
	mkdir -p $(dir $@)
	$(COMPILE.c) -o $@ $<

.lib/%.cpp.o: %.cpp
	mkdir -p $(dir $@)
	$(COMPILE.cpp) -o $@ $<

.lib/%.cc.o: %.cc
	mkdir -p $(dir $@)
	$(COMPILE.cpp) -o $@ $<

.lib/%.C.o: %.C
	mkdir -p $(dir $@)
	$(COMPILE.cpp) -o $@ $<
