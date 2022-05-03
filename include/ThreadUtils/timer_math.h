#ifndef TIMER_UTILS_H
#define TIMER_UTILS_H

#pragma once

#include <errno.h>
#include <sched.h>
#include <string.h>
#include <time.h>

#include <iostream>
extern "C" {

/**
 * periodic information
 */
struct period_info {
    struct timespec next_deadline;
    long period_ns;
};
// struct timespec holds time in seconds and nanoseconds
void timespec_add_us(struct timespec* t, long us);
int timespec_cmp(struct timespec* a, struct timespec* b);
int timespec_sub(struct timespec* diff, struct timespec* a, struct timespec* b);
static void increment_period(struct period_info* pinfo);
static void periodic_task_init(struct period_info* pinfo, long period_ns);
static void wait_rest_of_period(struct period_info* pinfo);
static void set_policy(const long policy);

/**
 * @brief addd microseconds to timespec
 *
 * @param t
 * @param us
 */
void timespec_add_us(struct timespec* t, long us)
{
    t->tv_nsec += us * 1000;
    if (t->tv_nsec > 1000000000) {
        t->tv_nsec = t->tv_nsec - 1000000000; // + ms*1000000;
        t->tv_sec += 1;
    }
}

/**
 * @brief Wait thread to start before clock monotonic timer reaches next millisecond
 *
 */
void sync_to_milisec()
{ // Try to syncronize
    timespec sync_t;
    clock_gettime(CLOCK_MONOTONIC, &(sync_t));
    // wait for remaining nanoseconds
    // sync_t.tv_nsec = __syscall_slong_t(1000000000) - sync_t.tv_nsec;
    // sync time till next millisecond
    sync_t.tv_nsec = (sync_t.tv_nsec / 1000000) * 1000000 + 1000000;

    while (sync_t.tv_nsec >= 1000000000) {
        /* timespec nsec overflow */
        sync_t.tv_sec++;
        sync_t.tv_nsec -= 1000000000;
    }

    clock_nanosleep(CLOCK_MONOTONIC, TIMER_ABSTIME, &sync_t, NULL);
}

/**
 * @brief Wait thread to start before clock monotonic timer reaches next second
 *
 */
void sync_to_sec()
{
    // Try to syncronize
    timespec sync_t;
    clock_gettime(CLOCK_MONOTONIC, &(sync_t));
    // wait for remaining nanoseconds
    sync_t.tv_nsec = __syscall_slong_t(1000000000) - sync_t.tv_nsec;
    // sync time till next millisecond
    sync_t.tv_sec += 1;

    clock_nanosleep(CLOCK_MONOTONIC, TIMER_ABSTIME, &sync_t, NULL);
}

int timespec_cmp(struct timespec* a, struct timespec* b)
{
    if (a->tv_sec > b->tv_sec) {
        return 1;
    } else if (a->tv_sec < b->tv_sec) {
        return -1;
    } else //(a->tv_sec == b->tv_sec)
    {
        if (a->tv_nsec > b->tv_nsec) {
            return 1;
        } else if (a->tv_nsec == b->tv_nsec) {
            return 0;
        } else {
            return -1;
        }
    }
}

/**
 * @brief Substract timespec b from timespec a
 *
 * @param diff
 * @param a
 * @param b
 * @return int
 */
int timespec_sub(struct timespec* diff, struct timespec* a,
    struct timespec* b)
{
    diff->tv_nsec = a->tv_nsec - b->tv_nsec;
    diff->tv_sec = a->tv_sec - b->tv_sec;
    if (a->tv_nsec < b->tv_nsec) {
        diff->tv_nsec += 1000000000;
        diff->tv_sec -= 1;
    }
    return 1;
}

/**
 * @brief increment the timespec period info
 *
 * @param pinfo
 */
static void increment_period(struct period_info* pinfo)
{
    pinfo->next_deadline.tv_nsec += pinfo->period_ns;

    while (pinfo->next_deadline.tv_nsec >= 1000000000) {
        /* timespec nsec overflow */
        pinfo->next_deadline.tv_sec++;
        pinfo->next_deadline.tv_nsec -= 1000000000;
    }
}
/**
 * @brief Initialize periodic information
 *
 * @param pinfo
 * @param period_ns
 */
static void periodic_timer_init(struct period_info* pinfo,
    const long period_ns)
{
    /* for simplicity, hardcoding a 1ms period */
    pinfo->period_ns = period_ns;

    clock_gettime(CLOCK_MONOTONIC, &(pinfo->next_deadline));
}

/**
 * @brief sleep until clock reaches next deadline
 *
 * @param pinfo
 */
static void wait_rest_of_period(struct period_info* pinfo)
{
    // increment deadline
    increment_period(pinfo);

    /* for simplicity, ignoring possibilities of signal wakes */
    clock_nanosleep(CLOCK_MONOTONIC, TIMER_ABSTIME, &pinfo->next_deadline, NULL);
}
}

#endif