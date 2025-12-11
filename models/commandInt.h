/* ----------------------------------------------------------
**   commandInt.h
**
**   Algorithmic level model of Drawing engine
**
**   Command interpreter module (header file)
**
**   version 0.3  09/01/2015
**   contributors: lplana, jpepper, lbrackenbury
**  
---------------------------------------------------------- */
#ifndef CIINC
#define CIINC

#include <cstdlib>
#include <unistd.h>
#include <fcntl.h>
#include <ctype.h>
#include <string.h>
#include <iostream>
#include <fstream>

#include "params.h"
#include "frameStore.h"


enum CommandType {
    Clear,         /* clear the screen             */
    Dump,          /* dump screen contents to file */
    Quit,          /* finish execution             */
    Sleep,         /* sleep for given time (in s)  */
    Line,          /* drawing Line function 	   */
    Circle,
    Unknown        /* unknown command              */
};

class Command {
    public:
        CommandType type;            /* actual command type */
        double        param[MAXPARAM]; /* parameters associated with command */
};

class CommandInt {
    private:
        int readline(char *buf);

    public:
        Command readCmd();

        /* clearScr is provided for verification purposes only */
        void clearScreen(FrameStore& fs);

        /* dump is provided for verification purposes only */
        void dump(uint8_t *mem);
};

#endif
