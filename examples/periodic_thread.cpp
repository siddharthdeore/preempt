#include <ThreadUtils/ThreadWrapper.h>
#include <ThreadUtils/TimeStampLogger.h>
#include <ThreadUtils/timer_math.h>
#include <math.h>

void* non_real_time_function(void* arg);
void* real_time_function(void* arg);

#include <atomic>
#include <signal.h>

static std::atomic<bool> done(false); // signal flag
static std::atomic<int64_t> x(10);
std::mutex mtx;
int main(int argc, char const* argv[])
{
    // Ctrl + C signal handler with lambda
    signal(SIGINT, [](int sig_num) { done = true; });

    struct timespec _rqtp;
    clock_gettime(CLOCK_REALTIME, &_rqtp);
    _rqtp.tv_nsec = 0;
    _rqtp.tv_sec += 1;
    clock_nanosleep(CLOCK_REALTIME, TIMER_ABSTIME, &_rqtp, NULL);

    period_info info_rt;
    int rate = 1000; // 1 kHz
    periodic_timer_init(&info_rt, 1e9 / (rate));

    ThreadWrapper rt_thread1k(real_time_function, &info_rt);
    rt_thread1k.setPriority(SCHED_FIFO, 99);
    rt_thread1k.setAffinity(1); // pin to core 0

    period_info info_nrt;
    rate = 5000; // 5 kHz
    periodic_timer_init(&info_nrt, 1e9 / (rate));

    ThreadWrapper rt_thread5k(non_real_time_function, &info_nrt);
    rt_thread5k.setPriority(SCHED_FIFO, 99);
    rt_thread5k.setAffinity(0); // pin to core 0

    if (!done.is_lock_free()) {
        return 10; // error
    }

    rt_thread1k.join();
    rt_thread5k.join();

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
    // initalize time stamp looger file
    TimeStampLogger t_stamp_log("logs/rt1k.txt");
    period_info* _p_info = (period_info*)arg;

    // static double x;

    period_info info_rt;

    // syncronize time
    clock_gettime(CLOCK_MONOTONIC, &(_p_info->next_deadline));
    //_p_info->next_deadline.tv_nsec = 1000000000 - _p_info->next_deadline.tv_nsec;
    _p_info->next_deadline.tv_nsec = 0;
    _p_info->next_deadline.tv_sec += 1;
    clock_nanosleep(CLOCK_MONOTONIC, TIMER_ABSTIME, &_p_info->next_deadline, NULL);

    while (!done) {
        t_stamp_log.stamp();
        /* Code to be called periodicaly */
        // std::cout << "RT Thread " << x++ << "\n";
        mtx.lock();
        x = x - 5;
        mtx.unlock();
        // give other threads some cpu time
        wait_rest_of_period(_p_info);
    }

    std::lock_guard<std::mutex> guard(mtx);
    std::cout << "x in rt is " << x << std::endl;
    return 0;
}

/**
 * @brief Non real time function
 *
 * @param arg
 * @return void*
 */
void* non_real_time_function(void* arg)
{
    TimeStampLogger t_stamp_log("logs/rt5k.txt");
    period_info* _p_info = (period_info*)arg;

    // static double x;

    // syncronize time
    clock_gettime(CLOCK_MONOTONIC, &(_p_info->next_deadline));
    //_p_info->next_deadline.tv_nsec = 1000000000 - _p_info->next_deadline.tv_nsec;
    _p_info->next_deadline.tv_nsec = 0;
    _p_info->next_deadline.tv_sec += 1;
    clock_nanosleep(CLOCK_MONOTONIC, TIMER_ABSTIME, &_p_info->next_deadline, NULL);

    while (!done) {
        t_stamp_log.stamp();
        /* Code to be called periodicaly */
        // std::cout << "NRT Thread " << x++ << "\n";
        // for (size_t i = 0; i < 400; i++) {
        mtx.lock();
        x = x + 1;
        mtx.unlock();

        //}

        // give other threads some cpu time
        wait_rest_of_period(_p_info);
    }
    std::lock_guard<std::mutex> guard(mtx);
    std::cout << "x in nrt is " << x << std::endl;
    return 0;
}
