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

void timespec_add_us(struct timespec* t, long us)
{
    t->tv_nsec += us * 1000;
    if (t->tv_nsec > 1000000000) {
        t->tv_nsec = t->tv_nsec - 1000000000; // + ms*1000000;
        t->tv_sec += 1;
    }
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
 * Substract timespec b from timespec a
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

// increment the timespec period info
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