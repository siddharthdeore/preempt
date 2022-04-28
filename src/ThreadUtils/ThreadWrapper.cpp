#include <ThreadUtils/ThreadWrapper.h>

void ThreadWrapper::setPriority(int policy = SCHED_RR, int priority = 20)
{
    _policy = policy;
    _sch_params.sched_priority = priority;

    if (pthread_setschedparam(this->native_handle(), policy, &_sch_params)) {
        std::lock_guard<std::mutex> lock(_mtx); // unlocks when lock destroyed
        std::cerr << "Failed to set thread scheduling, try with sudo : "
                  << std::strerror(errno) << std::endl;
    } else {
        std::lock_guard<std::mutex> lock(_mtx);
        std::cout << "Thread priority scheduling set to " << priority << std::endl;
    }
}

void ThreadWrapper::setAffinity(int core)
{
    int nproc = sysconf(_SC_NPROCESSORS_ONLN);

    if (nproc < core) {
        core = nproc;
    }

    CPU_ZERO(&_cpuset);
    CPU_SET(core, &_cpuset);

    int ret = pthread_setaffinity_np(this->native_handle(), sizeof(cpu_set_t),
        &_cpuset);
    if (ret != 0) {
        std::lock_guard<std::mutex> lock(_mtx);
        std::cerr << "Failed to set Thread Affinity : " << std::strerror(errno)
                  << std::endl;
    } else {
        std::lock_guard<std::mutex> lock(_mtx);
        std::cout << "Thread Affinity set to CPU " << core << std::endl;
    }
}

int ThreadWrapper::getMaxPriority() { return sched_get_priority_max(_policy); }

int ThreadWrapper::getMinPriority() { return sched_get_priority_min(_policy); }
