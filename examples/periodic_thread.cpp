#include <ThreadUtils/ThreadWrapper.h>
#include <ThreadUtils/TimeStampLogger.h>
#include <ThreadUtils/timer_math.h>
#include <math.h>

void* non_real_time_function(void* arg);
void* real_time_function(void* arg);

#include <atomic>
#include <signal.h>

static std::atomic<bool> done(false); // signal flag

int main(int argc, char const* argv[])
{
    // Ctrl + C signal handler with lambda
    signal(SIGINT, [](int sig_num) { done = true; });

    period_info info_rt;
    int rate = 1000; // 1 kHz
    periodic_timer_init(&info_rt, 1e9 / (rate));

    ThreadWrapper rt_thread1k(real_time_function, &info_rt);
    rt_thread1k.setPriority(SCHED_FIFO, 99);
    rt_thread1k.setAffinity(0); // pin to core 0

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
    period_info* _p_info = (period_info*)arg;
    double x = 1.5;
    timespec sync_t;
    // get current time
    clock_gettime(CLOCK_MONOTONIC, &(sync_t));

    // wait for remaining nanoseconds
    // sync_t.tv_nsec = __syscall_slong_t(1000000000) - sync_t.tv_nsec;
    // sync time till next millisecond
    sync_t.tv_nsec = (sync_t.tv_nsec / 10000000) * 10000000 + 10000000;

    while (sync_t.tv_nsec >= 1000000000) {
        /* timespec nsec overflow */
        sync_t.tv_sec++;
        sync_t.tv_nsec -= 1000000000;
    }

    clock_nanosleep(CLOCK_MONOTONIC, TIMER_ABSTIME, &sync_t, NULL);
    // initalize time stamp looger file
    TimeStampLogger t_stamp_log("logs/rt1k.txt");

    while (!done) {
        /* Code to be called periodicaly */
        // std::cout << "RT Thread " << x++ << "\n";
        for (size_t i = 0; i < 100; i++) {
            x *= sin(x) / atan(x) * tanh(x) * sqrt(x);
        }
        // give other threads some cpu time
        wait_rest_of_period(_p_info);
        t_stamp_log.stamp();
    }
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
    period_info* _p_info = (period_info*)arg;
    double x = 1.5;

    timespec sync_t;
    clock_gettime(CLOCK_MONOTONIC, &(sync_t));
    // wait for remaining nanoseconds
    // sync_t.tv_nsec = __syscall_slong_t(1000000000) - sync_t.tv_nsec;
    // sync time till next millisecond
    sync_t.tv_nsec = (sync_t.tv_nsec / 10000000) * 10000000 + 10000000;

    while (sync_t.tv_nsec >= 1000000000) {
        /* timespec nsec overflow */
        sync_t.tv_sec++;
        sync_t.tv_nsec -= 1000000000;
    }

    clock_nanosleep(CLOCK_MONOTONIC, TIMER_ABSTIME, &sync_t, NULL);
    TimeStampLogger t_stamp_log("logs/rt5k.txt");

    while (!done) {
        /* Code to be called periodicaly */
        // std::cout << "NRT Thread " << x++ << "\n";
        x *= sin(x) / atan(x) * tanh(x) * sqrt(x);

        // give other threads some cpu time
        wait_rest_of_period(_p_info);
        t_stamp_log.stamp();
    }
    return 0;
}
