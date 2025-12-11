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
#ifndef LINE_INC
#define LINE_INC

#include <fstream>

#include "params.h"
#include "frameStore.h"

class LineModule {
    public:
        void drawLine(int x0, int y0, int x1, int y1, uint8_t colour, FrameStore& fs, std::ofstream &outfile);
};

#endif
