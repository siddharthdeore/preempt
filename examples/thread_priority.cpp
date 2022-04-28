#include <ThreadUtils/ThreadWrapper.h>
#include <math.h>

#include <time.h>

void *callback_function_hp()
{
    struct timespec time_requested,time_remaining;
    time_requested.tv_sec = 0;
    time_requested.tv_nsec = 10000; // 10 milissec

    float x = 1.5f;
    
    while (1)
    {
        x *= sin(x) / atan(x) * tanh(x) * sqrt(x);
        // need to sleep so lower priority threads get some cpu time
        nanosleep(&time_requested,&time_remaining);
    }
}
int main(int argc, char const *argv[])
{
    ThreadWrapper th1(callback_function_hp);

    // set scheduling policy FIFO, priority 20
    th1.setPriority(SCHED_FIFO, 20);

    ThreadWrapper th2(callback_function_hp);

    // set scheduling policy Round-Robin, priority 50
    th2.setPriority(SCHED_RR, 50);


    // wait for threads to finish
    th1.join();
    th2.join();

    return 0;
}
