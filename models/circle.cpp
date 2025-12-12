/* ----------------------------------------------------------
**   drawingEngine.cpp
**
**   Algorithmic level model of Drawing engine
**
**   Drawing engine module: Circle
**
**   version 0.3  11/2/2015
**   contributors: lplana, jpepper, lbrackenbury, jgarside
**
---------------------------------------------------------- */
#include <circle.h>
#include <stdio.h>
#include <math.h>
#include <fstream>

#define SCREEN_WIDTH 640
#define SCREEN_HEIGHT 480

static void plot_clipped(int x, int y, uint8_t colour, FrameStore &fs, std::ofstream &outfile)
{
  if (x >= 0 && x < SCREEN_WIDTH && y >= 0 && y < SCREEN_HEIGHT)
  {
    // Calculate linear address and plot only if it's valid
    unsigned int address = x + PIXELS * y;
    fs.write(address, colour);
    outfile << address << " " << (int)colour << std::endl;
  }
}

void CircleModule::drawCircle(int x0, int y0, int r,
                              uint8_t colour, FrameStore &fs, std::ofstream &outfile)
{
  unsigned int address;
  int x = 0;
  int y = r;
  int p = r;

  while (x <= y)
  { // The write operations will need serialising in an FSM
    plot_clipped(x0 + x, y0 + y, colour, fs, outfile);
    plot_clipped(x0 - x, y0 + y, colour, fs, outfile);
    plot_clipped(x0 + x, y0 - y, colour, fs, outfile);
    plot_clipped(x0 - x, y0 - y, colour, fs, outfile);
    plot_clipped(x0 + y, y0 + x, colour, fs, outfile);
    plot_clipped(x0 - y, y0 + x, colour, fs, outfile);
    plot_clipped(x0 + y, y0 - x, colour, fs, outfile);
    plot_clipped(x0 - y, y0 - x, colour, fs, outfile);

    p = p - 2 * x;
    x = x + 1;
    if (p < 0)
    {
      p = p + 2 * y;
      y = y - 1;
    }
  }
}
