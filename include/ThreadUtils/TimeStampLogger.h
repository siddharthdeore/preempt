#include <fstream>
#include <iomanip>
#include <iostream>
#include <vector>
#define timespec_to_second(tsp) (double)tsp.tv_sec + (double)tsp.tv_nsec / 1000000000
class TimeStampLogger {
private:
    timespec _time_stamp;
    double init_time_in_sec;
    std::vector<timespec> _vec;
    std::string _filename;
    std::ofstream _logfile;

public:
    TimeStampLogger(std::string name)
    {
        _vec.reserve(1000000);
        _filename = name;
        std::cout << "Stamp File :" << _filename << std::endl;
        clock_gettime(CLOCK_MONOTONIC, &_time_stamp);
        init_time_in_sec = timespec_to_second(_time_stamp);
    }
    void stamp()
    {
        clock_gettime(CLOCK_MONOTONIC, &_time_stamp);
        _vec.push_back(_time_stamp);
    }
    ~TimeStampLogger()
    {
        std::cout << "Writing Logger file :" << _filename << std::endl;
        _logfile.open(_filename);
        for (const auto& value : _vec) {
            _logfile << std::setprecision(std::numeric_limits<long double>::digits10)
                     << timespec_to_second(value) << "\n";
            //<< timespec_to_second(value) - init_time_in_sec << "\n";
        }
        _logfile.close();
    }
    // void flush(); // to do : save to file and clear ram;
};
