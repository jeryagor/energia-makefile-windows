energia-makefile-windows
========================

An Energia makefile to be used under Windows with MinGW / MSYS.

This makefile is intended to work on MSP430 launchpads using the Energia libraries.

It is based on the previous work of elpaso (see the [energia-makefile repository](https://github.com/elpaso/energia-makefile)).

Prerequisites
--------------------


### Energia

In order to build an Energia sketch with this makefile, you will first need to install the Energia software on your computer.

In order to do so, please go on the [Energia download page](http://energia.nu/download/), get the Windows archive and unzip it wherever you want. 

### MSYS

You will also need the make tool as well as some Unix-like commandline utilities.

The easiest way I found is to [install MinGW](http://sourceforge.net/projects/mingw/files/) with the msys-base package.

At the end of MinGW installation, the MinGW GUI should start: you can then choose to install msys-base by checking it in the list and going to Installation > Apply changes.

By default, msys executables are installed in C:\MinGW\msys\1.0\bin

For convenience, just add this directory to your Path variable.

Usage instructions
--------------------

The Energia makefile needs two variables to be defined by the user: ENERGIADIR and ENERGIABOARD.

You can either set these variables in the commandline or write them directly in the makefile itself.

### ENERGIADIR

ENERGIADIR should point to your Energia installation.

Please note that makefile forbids the usage of colons in filepaths: if you installed MSYS, a by-pass is to replace a path like C:\some\where by /C/some/where.

For example, this is a valid way to set the variable:

    ENERGIADIR=/D/Programmes/energia-0101E0011

### ENERGIABOARD

ENERGIABOARD indicates the type of the launchpad you want to work on.

To get a list of possible values, type the following:

    make boards

For example, this is a valid way to set the variable:

    ENERGIABOARD=lpmsp430g2553

### Makefile targets

Severals targets are provided in the makefile:

* *all* => This is the default if no goal is specified. It builds the target.
* *target* => Build the target.
* *run* => Build, upload and run the target on an attached Launchpad.
* *clean* => Delete files created during the build.
* *boards* => Display a list of available board names, so that you can set the ENERGIABOARD environment variable appropriately.
* *size* => Display size information about the built target.
