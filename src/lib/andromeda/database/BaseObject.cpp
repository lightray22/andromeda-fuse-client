
#include <algorithm>

#include "BaseObject.hpp"
#include "MixedValue.hpp"
#include "ObjectDatabase.hpp"

namespace Andromeda {
namespace Database {

/*****************************************************/
BaseObject::BaseObject(ObjectDatabase& database, const MixedParams& data) :
    mDatabase(database), mIdField("id", *this)
{
    RegisterFields({&mIdField});

    for (const MixedParams::value_type& pair : data)
    {
        mFields.at(pair.first).InitDBValue(pair.second);
    }
}

/*****************************************************/
void BaseObject::RegisterFields(const FieldList& list)
{
    for (FieldTypes::BaseField* field : list)
        mFields.emplace(field->GetName(), *field);
}

/*****************************************************/
void BaseObject::InitializeID(size_t len)
{
    mIdField.SetValue(Utilities::Random(len));
}

/*****************************************************/
const std::string& BaseObject::ID() const
{
    return mIdField.GetValue();
}

/*****************************************************/
BaseObject::operator std::string() const
{
    return ID()+":"+GetClassName();
}

/*****************************************************/
bool BaseObject::isModified() const
{
    return std::any_of(mFields.cbegin(), mFields.cend(), 
        [&](const decltype(mFields)::value_type& pair){ 
            return pair.second.isModified(); });
}

/*****************************************************/
void BaseObject::Save()
{
    FieldList fields;
    for (const FieldMap::value_type& pair : mFields)
    {
        if (pair.second.isModified())
            fields.emplace_back(&pair.second);
    }

    mDatabase.SaveObject(*this, fields);
}

} // namespace Database
} // namespace Andromeda