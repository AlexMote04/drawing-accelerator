/* ----------------------------------------------------------
**   main.cpp
**
**   Algorithmic level model of Drawing engine
**
**   TOP LEVEL module
**
**   version 0.2  15/10/2007
**   contributors: lplana, jpepper, lbrackenbury
**
---------------------------------------------------------- */
#include <cstdlib>
#include <fstream>

#include "params.h"
#include "commandInt.h"
#include "virtualScreen.h"
#include "frameStore.h"
#include "line.h"
#include "circle.h"

int main () {

    CommandInt    ci;
    VirtualScreen vs;
    FrameStore    fs(vs.shm_addr());
    std::ofstream outfile("pixels.txt");


    /* Drawing modules */
       LineModule line;
       CircleModule circle;

    Command command;
    int     getNewCmd = true;

    do {
        command = ci.readCmd();
        switch (command.type) {
            case Line:
                line.drawLine(command.param[0], /* start point x coord. */
                        command.param[1], /* start point y coord. */
                        command.param[2], /* end point x coord.   */
                        command.param[3], /* end point y coord.   */
                        command.param[4], /* colour               */
                        fs, outfile);
                break;
            case Circle:
                circle.drawCircle(command.param[0], /* centre point x coord. */
                        command.param[1], /* centre point y coord. */
                        command.param[2], /* radius.		   */
                        command.param[3], /* colour                */
                        fs, outfile);
                break;
            case Clear:
                /* clear the screen by drawing BLACK horizontal lines */
                ci.clearScreen(fs);
                break;
            case Dump:
                ci.dump(vs.shm_addr());
                break;
            case Sleep:
                sleep(command.param[0]); /* time to sleep in s  */
                break;
            case Quit:
                getNewCmd = false; /* stop processing commands  */
                break;
            case Unknown:
                break; /* ignore unknown command */
        }
    } while (getNewCmd);
    outfile.close();
}
