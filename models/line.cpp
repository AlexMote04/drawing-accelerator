/* ----------------------------------------------------------
**   drawingEngine.cpp
**
**   Algorithmic level model of Drawing engine
**
**   Drawing engine module
**
**   version 0.2  15/10/2007
**   contributors: lplana, jpepper, lbrackenbury
**
---------------------------------------------------------- */
#include <line.h>
#include <stdio.h>
#include <fstream>


void LineModule::drawLine(int x0, int y0, int x1, int y1, uint8_t colour, FrameStore& fs, std::ofstream &outfile) {
    /* This is an implementation of Bresenham's line drawing algorithm */
    unsigned int address;
    int dx, dy, adx, ady;
    int a1, a2, sx, sy;
    int e, c, m, n, p;

    /* write the first point */
    address = x0 + PIXELS*y0;
    fs.write(address, colour); outfile << (address) << " " << (int)colour << std::endl;

    /* compute the pixels along the line */
    dx = x1 - x0;
    dy = y1 - y0;

    if (dx < 0) {
        sx = -1;
    } else {
        sx = 1;
    } 
    if (dy < 0) {
        sy = -PIXELS;
    } else {
        sy = PIXELS;
    }

    adx = abs(dx);
    ady = abs(dy);

    if (adx > ady) {
        a1 = sx;
        c  = adx;
        m  = adx;
        n  = ady;
    } else {
        a1 = sy;
        c  = ady;
        m  = ady;
        n  = adx;
    }

    e  = -m;
    p  = n - m;
    a2 = sx + sy;

    while (c > 0) {
        if ((e + 2*n) <= 0) {
            address = address + a1; e = e + 2*n;
        } else {
            address = address + a2; e = e + 2*p;
        }
        c--;
        fs.write(address, colour); outfile << (address) << " " << (int)colour << std::endl;
    }
}


















