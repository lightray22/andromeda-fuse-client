#ifndef FUSEWRAPPER_H_
#define FUSEWRAPPER_H_

#include <string>

#include "Utilities.hpp"
#include "Options.hpp"

class BaseFolder;

/** Static class for FUSE operations */
class FuseWrapper
{
public:

    /** Base Exception for all FUSE issues */
    class Exception : public Utilities::Exception { public:
        Exception(const std::string& message) :
            Utilities::Exception("FUSE Error: "+message) {}; };

    /**
     * Starts FUSE
     * @param root andromeda folder as root
     * @param options command line options
     */
    static void Start(BaseFolder& root, const Options& options);

    /** Print help text to stdout */
    static void ShowHelpText();

    /** Print version text to stdout */
    static void ShowVersionText();

private:

    FuseWrapper() = delete; // static only
};

#endif