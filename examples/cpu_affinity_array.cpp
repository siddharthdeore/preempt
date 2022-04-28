#include <ThreadUtils/ThreadWrapper.h>
#include <math.h>
// some cpu intensive callable function
void* callback_function()
{
    float x = 1.5f;

    while (1) {
        x *= sin(x) / atan(x) * tanh(x) * sqrt(x);
    }
}
int main(int argc, char const* argv[])
{
    int count = 1;
    if(argc>1){
        count = atoi(argv[1]);
    }
    ThreadWrapper th[count];
    for (size_t i = 0; i < count; i++)
    {
        ThreadWrapper temp(callback_function);
        th[i] = temp;
        // pin thread to CPU core i
        th[i].setAffinity(i);

    }

    // wait for threads to finish
    for (size_t i = 0; i < count; i++)
    {
        th[i].join();
    }
    return 0;
}
