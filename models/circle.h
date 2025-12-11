/* ----------------------------------------------------------
**   drawingEngine.h
**
**   Algorithmic level model of Drawing engine
**
**   Drawing engine module (header file)
**
**   version 0.2  15/10/2007
**   contributors: lplana, jpepper, lbrackenbury
**
---------------------------------------------------------- */
#ifndef CIRCLE_INC
#define CIRCLE_INC

#include <fstream>

#include "params.h"
#include "frameStore.h"

class CircleModule {
    public:
        void drawCircle(int x0, int y0, int r, uint8_t colour, FrameStore& fs, std::ofstream &outfile);
};

#endif
