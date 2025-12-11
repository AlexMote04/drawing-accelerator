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

void CircleModule::drawCircle(int x0, int y0, int r,
                              uint8_t colour, FrameStore& fs, std::ofstream &outfile)
 {


  
  unsigned int address;
  int x = 0;
  int y = r;
  int p = r;

  while (x <= y)
    {	// The write operations will need serialising in an FSM
    address = x0+x+PIXELS*(y0+y); fs.write(address, colour); outfile << (address) << " " << (int)colour << std::endl;
    address = x0+y+PIXELS*(y0+x); fs.write(address, colour); outfile << (address) << " " << (int)colour << std::endl;
    address = x0+y+PIXELS*(y0-x); fs.write(address, colour); outfile << (address) << " " << (int)colour << std::endl;
    address = x0+x+PIXELS*(y0-y); fs.write(address, colour); outfile << (address) << " " << (int)colour << std::endl;
    address = x0-x+PIXELS*(y0-y); fs.write(address, colour); outfile << (address) << " " << (int)colour << std::endl;
    address = x0-y+PIXELS*(y0-x); fs.write(address, colour); outfile << (address) << " " << (int)colour << std::endl;
    address = x0-y+PIXELS*(y0+x); fs.write(address, colour); outfile << (address) << " " << (int)colour << std::endl;
    address = x0-x+PIXELS*(y0+y); fs.write(address, colour); outfile << (address) << " " << (int)colour << std::endl;

    p = p - 2*x;	// Consider the 'ordering' of
    x = x + 1;		//  these pairs of assignments
    if (p < 0)
      {
      p = p + 2*y;	// Maybe try swapping them?
      y = y - 1;	// Refer to the manual.
      }
   }
}
