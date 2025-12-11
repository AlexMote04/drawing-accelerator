/* ----------------------------------------------------------
**   commandInt.cpp
**
**   Algorithmic level model of Drawing engine
**
**   Command interpreter module
**
**   version 0.2  15/10/2007
**   contributors: lplana, jpepper, lbrackenbury
**
---------------------------------------------------------- */
#include "commandInt.h"

using namespace std;

Command CommandInt::readCmd() {
    Command cmd;
    char    cmdline[CMDBUF+1]; /* room for NULL terminator */
    char*   command;
    char*   param;
    int     paramCnt;

    /* get input line */
    readline(cmdline);
    if (VERBOSE) cout << "commandInt: new command line: " << cmdline;

    /* ---------- parse command line ----------- */
    /* use white space to separate tokens        */
    /* get command type (first token in command) */
    if((command = strtok(cmdline, " \t\n\r")) != NULL) {
        /* get value and count of parameters */
        for (paramCnt=0; paramCnt<MAXPARAM; paramCnt++) {
            if ((param = strtok(NULL," \t\n\r")) != NULL)
                cmd.param[paramCnt] = atof(param);
            else
                /* no more parameters left */
                break;
        }
    }

    /* check that the number of parameters is correct */
    /* and return appropiate command type and params  */
    if (command == NULL) {
        /* an empty command line */
        cmd.type = Unknown;
        cerr << "commandInt: WARNING - ignoring empty command line." << endl;
    }
    else if (!strcmp(command, "line")){
       if (paramCnt >= 5)
        cmd.type = Line;
       else {
        cmd.type = Unknown;
        cerr << "commandInt: WARNING - ignoring 'line' command with < 5 parameters." << endl;
       }
    }
    else if (!strcmp(command, "circle")){
       if (paramCnt >= 4)
        cmd.type = Circle;
       else {
        cmd.type = Unknown;
        cerr << "commandInt: WARNING - ignoring 'circle' command with < 4 parameters." << endl;
       }
    }
    else if (!strcmp(command, "clear")){
            cmd.type = Clear;
    }
    else if (!strcmp(command, "dump")){
        cmd.type = Dump;
    }
    else if (!strcmp(command, "sleep")){
        if (paramCnt >= 1)
            cmd.type = Sleep;
        else {
            cmd.type = Unknown;
            cerr << "commandInt: WARNING - ignoring 'sleep' command with < 1 parameter." << endl;
        }
    }
    else if (!strcmp(command, "quit")){
        cmd.type = Quit;
    }
    else {
        cmd.type = Unknown;
        cerr << "commandInt: WARNING - ignoring unknown command " << command << endl;
    }

    return(cmd);
}

int CommandInt::readline(char *buf) {
    char    c;
    int     charCnt = 0;

    do {
        /* read a new character and check for problems */
        cin.get(c);
        if (cin.eof()) {
            /* ran out of characters to read    */
            /* simply try again with same count */
            charCnt--;
        }
        else {
            buf[charCnt] = tolower(c); /* commands are lower case */
            if (charCnt == CMDBUF-1) {
                /* line too long for buffer => read */
                /* and ignore the rest of the line  */
                do {
                    c = getchar();
                } while (c != '\n');
                /* fix the last chars of the buffer */
                buf[CMDBUF]   = '\n';
                buf[CMDBUF+1] = 0;
                charCnt = CMDBUF;
                cerr << "commandInt: WARNING - line too long: " << buf;
            }
        }
    }  while (buf[charCnt++] != '\n');
    buf[charCnt] = 0;  /* NULL-terminate the string */
    return(charCnt-1);
}

/* clearScr is provided for verification purposes only */
void CommandInt::clearScreen(FrameStore& fs) {
    int     line;
    int     pixel;

    /* write ALL pixels with colour BLACK */
    /* using full-screen horizontal lines */
    for (line=0; line<LINES; line++)
     for (pixel=0; pixel<PIXELS; pixel++)
      fs.write(line*PIXELS+pixel, 0);
}

/* dump is provided for verification purposes only */
void CommandInt::dump(uint8_t *mem) {
    ofstream dumpF("vsDump.txt", ios::out);
    int   x, y;
    uint8_t colour;

    if (!dumpF)
        cerr << "commandInt: WARNING - could not open dump file 'fsDump.txt'." << endl;
    else {
        /* write non-BLACK pixels to dump file */
        /* pixels are "dumped" screen line by  */
        /* screen line as they are "scanned"   */
        for (y=0; y<LINES; y++) {
            for (x=0; x<PIXELS; x++) {
                if ((colour = mem[PIXELS*y+x]) != BLACK) {
                    dumpF.fill('0');
                    dumpF.width(3);
                    dumpF << x << ' ';
                    dumpF.width(3);
                    dumpF << y << ' ';
                    dumpF.width(3);
                    dumpF << (int) colour << '\n';
                }
            }
        }
    }
}
