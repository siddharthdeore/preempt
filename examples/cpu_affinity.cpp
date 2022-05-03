#include <ThreadUtils/ThreadWrapper.h>
#include <math.h>
// some cpu intensive callable function
void* callback_function()
{
    float x = 1.5f;

    while (1) {
        x *= sin(x) / atan(x) * tanh(x) * sqrt(x);
        usleep(1);
    }
}
int main(int argc, char const* argv[])
{
    ThreadWrapper th1(callback_function);

    // pin thread to CPU core 0
    th1.setAffinity(0);

    ThreadWrapper th2(callback_function);

    // pin thread to CPU core 1
    th2.setAffinity(1);

    // wait for threads to finish
    th1.join();
    th2.join();

    return 0;
}
