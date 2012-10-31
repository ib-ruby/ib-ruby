#ifndef tagvalue_def
#define tagvalue_def

#include "shared_ptr.h"
#include "IBString.h"

#include <vector>

struct TagValue
{
	TagValue() {}
	TagValue(const IBString& p_tag, const IBString& p_value)
		: tag(p_tag), value(p_value)
	{}

	IBString tag;
	IBString value;
};

typedef shared_ptr<TagValue> TagValueSPtr;
typedef std::vector<TagValueSPtr> TagValueList;
typedef shared_ptr<TagValueList> TagValueListSPtr;

#endif

