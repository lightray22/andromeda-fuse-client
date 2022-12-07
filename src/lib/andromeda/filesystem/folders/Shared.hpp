
#ifndef LIBA2_SHARED_H_
#define LIBA2_SHARED_H_

#include "PlainFolder.hpp"

namespace Andromeda {
namespace Filesystem {
namespace Folders {

/** A special folder showing the user's shared items */
class Shared : public PlainFolder
{
public:
    
    virtual ~Shared(){};
};

} // namespace Andromeda
} // namespace Filesystem
} // namespace Folders

#endif