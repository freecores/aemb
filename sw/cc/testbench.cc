
//#include <iostream>
#include <cstdio>
#include <cstdlib>
#include "aemb/core.hh"

volatile int *STDO = (int *) 0xFFFFFF00;

#define FIFO_SIZE 4
int fifo[FIFO_SIZE];
int ridx = 0;
int widx = 0;

// Push numbers into the FIFO (if it is not full)
void fifoProduce()
{
  for (int i=0; i<100; ++i)
    {      
      int wnxt = widx + 1;     
      while (wnxt == ridx); // block if full
      fifo[widx] = i;
      widx = (widx + 1) % FIFO_SIZE;  
    }
}

// Pull stuff from the FIFO (if there is any)
void fifoConsume()
{
  for (int i=0; i<100; ++i)
    {
      int rnxt = ridx + 1;
      while (rnxt == widx); // block if empty
      *STDO = fifo[ridx];
      ridx = (ridx + 1) % FIFO_SIZE;      
    }
}

aemb::Semaphore amutex(0), bmutex(0);

int count = 0;

int thread0() // runs for Thread 0
{
  *STDO = ++count;
  amutex.signal();
  bmutex.wait();
  *STDO = ++count;
}


int thread1() // main for Thread 1
{
  std::printf("HELLO WORLD\n");
  bmutex.signal();
  amutex.wait();
  *STDO = ++count;
}

int nothreads() // for single threaded case
{
  return EXIT_SUCCESS;
}


void outbyte(char c) {
  char *LCDO = (char *)0xFFFFFF10;
  *LCDO = c;
}

char inbyte() {
  return 0;
}



// run tests
int main() 
{ 
  if (aemb::isThread0()) return thread0(); else // split thread1
    if (aemb::isThread1()) return thread1(); else // split thread0
      return (nothreads()); // run both threads    
}
