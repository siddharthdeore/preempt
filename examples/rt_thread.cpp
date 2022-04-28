#include <ThreadUtils/ThreadWrapper.h>
#include <ThreadUtils/timer_math.h>

void* non_real_time_function(void* arg);
void* real_time_function(void* arg);

int main(int argc, char const* argv[])
{
    period_info info_rt;
    int rate = 1; // 1 Hz
    periodic_timer_init(&info_rt, 1e9 / (rate));

    ThreadWrapper rt_thread(real_time_function, &info_rt);
    rt_thread.setPriority(SCHED_FIFO, 99);
    rt_thread.setAffinity(0); // pin to core 0

    period_info info_nrt;
    rate = 10; // 10 Hz
    periodic_timer_init(&info_nrt, 1e9 / (rate));

    ThreadWrapper nrt_thread(non_real_time_function, &info_nrt);
    rt_thread.setPriority(SCHED_FIFO, 20);
    rt_thread.setAffinity(0); // pin to core 1

    rt_thread.join();
    /* code */
    return 0;
}

/**
 * @brief Real Time callback function handle
 *
 * @param arg
 * @return void*
 */
void* real_time_function(void* arg)
{
    period_info* _p_info = (period_info*)arg;
    double x = 1;

    while (1) {
        /* Code to be called periodicaly */
        std::cout << "RT Thread " << x++ << "\n";

        // give other threads some cpu time
        wait_rest_of_period(_p_info);
    }
}

/**
 * @brief Non real time function
 *
 * @param arg
 * @return void*
 */
void* non_real_time_function(void* arg)
{
    period_info* _p_info = (period_info*)arg;
    double x = 1;

    while (1) {
        /* Code to be called periodicaly */
        std::cout << "NRT Thread " << x++ << "\n";

        // give other threads some cpu time
        wait_rest_of_period(_p_info);
    }
}
