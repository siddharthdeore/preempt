/**
 * @file ThreadWrapper.h
 * @author Siddharth Deore (siddharth.deore@iit.it)
 * @brief Wrapper class to implement POSIX Thread on C++11
 * @version 0.1
 * @date 2022-04-28
 *
 * @copyright Copyright (c) Istituto Italiano di Tecnologia, Genova, Italy 2022
 *
 */
#ifndef THREADWRAPPER_H
#define THREADWRAPPER_H

#pragma once

#include <pthread.h>
#include <unistd.h>

#include <cstring>
#include <iostream>
#include <mutex>
#include <thread>

class ThreadWrapper : public std::thread {
public:
    // make sure we inherit all constructors
    using thread::thread;
    /**
     * @brief Set thread scheduling policy and priority
     * possible policies :
     *      SCHED_BATCH, SCHED_DEADLINE, SCHED_FIFO, SCHED_IDLE, SCHED_ISO,
     * SCHED_OTHER, SCHED_RESET_ON_FORK, SCHED_RR
     *
     * @param policy
     * @param priority
     */
    void setPriority(int policy, int priority);
    ~ThreadWrapper()
    {
        if (joinable())
            std::terminate();
    }
    /**
     * @brief Pin thread to specific processsor core
     *
     * @param core processsor core number
     */
    void setAffinity(int core);

    /**
     * @brief Get the Max Priority possible
     *
     * @return int maximum priority
     */
    int getMaxPriority();

    /**
     * @brief Get the Min Priority possible
     *
     * @return int minimum priority
     */
    int getMinPriority();

    /**
     * @brief Get number of CPU cores
     *
     * @return int CPU core count
     */
    int nproc();

    // Carefull!! This quick hack to impliment assignement is working for now.
    ThreadWrapper& operator=(ThreadWrapper& __t)
    {
        thread::swap(__t);
        return *this;
    }

private:
    // policy type
    int _policy = SCHED_OTHER;

    // data structure to describe a process' schedulability
    sched_param _sch_params;

    // data structure to describe CPU mask
    cpu_set_t _cpuset;

    // standard mutex
    std::mutex _mtx;
};

#endif