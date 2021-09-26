#include <iostream>
#include <thread>
#include <chrono>
#include <termios.h>

#include "Utilities.hpp"

using namespace std::chrono;

/*****************************************************/
Utilities::StringList Utilities::explode(
    std::string str, const std::string& delim, 
    const int max, const size_t skip)
{
    StringList retval;
    
    if (str.empty()) return retval;

    size_t skipped = 0, start = 0, end;
    while ((end = str.find(delim, start)) != std::string::npos
            && (max < 0 || retval.size()+1 < (size_t)max))
    {
        if (skipped >= skip)
        {
            start = 0;
            retval.push_back(str.substr(0, end));
            str.erase(0, end + delim.length());
        }
        else 
        {
            skipped++;
            start = (end + delim.length());
        }
    }

    retval.push_back(str);
    return retval;
}

/*****************************************************/
Utilities::StringPair Utilities::split(
    const std::string& str, const std::string& delim, const bool last)
{
    StringPair retval;

    size_t pos = last ? str.rfind(delim) : str.find(delim);

    if (pos == std::string::npos)
    {
        if (last) 
             retval.second = str;
        else retval.first = str;
    }
    else
    {
        retval.first = str.substr(0, pos);
        retval.second = str.substr(pos + delim.length());
    }

    return retval;
}

/*****************************************************/
void Utilities::SilentReadConsole(std::string& retval)
{
    struct termios oflags, nflags;
    
    tcgetattr(fileno(stdin), &oflags);

    nflags = oflags;
    nflags.c_lflag &= ~ECHO;
    nflags.c_lflag |= ECHONL;

    tcsetattr(fileno(stdin), TCSANOW, &nflags);

    std::getline(std::cin, retval);

    tcsetattr(fileno(stdin), TCSANOW, &oflags);
}

std::mutex Debug::mutex;
Debug::Level Debug::level = Debug::Level::NONE;
high_resolution_clock::time_point Debug::start = high_resolution_clock::now();

/*****************************************************/
void Debug::Details(const std::string& str)
{
    if (level >= Level::DETAILS) Error(str);

    if (str.empty()) this->buffer.str(std::string());
}

/*****************************************************/
void Debug::Info(const std::string& str)
{
    if (level >= Level::CALLS) Error(str);

    if (str.empty()) this->buffer.str(std::string());
}

/*****************************************************/
void Debug::Error(const std::string& str)
{
    if (level < Level::ERRORS) return;

    const std::lock_guard<std::mutex> lock(mutex);

    if (level >= Level::DETAILS)
    {
        duration<double> time = high_resolution_clock::now() - start;
        std::cout << "time:" << time.count() << " ";

        std::cout << "tid:" << std::this_thread::get_id() << " ";

        if (this->addr != nullptr) std::cout << "obj:" << this->addr << " ";
    }

    std::cout << this->prefix << ": ";

    if (str.empty())
    {
        std::cout << this->buffer.str() << std::endl; 
        
        this->buffer.str(std::string()); // reset buffer
    }
    else std::cout << str << std::endl;
}

/*****************************************************/
Debug& Debug::operator<<(const std::string& str)
{ 
    this->buffer << str; return *this; 
}
