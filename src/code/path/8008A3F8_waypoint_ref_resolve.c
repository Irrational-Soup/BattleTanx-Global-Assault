#include "types.h"

typedef struct WaypointObject WaypointObject;
typedef struct WaypointRef WaypointRef;
typedef struct WaypointRefList WaypointRefList;
typedef struct WaypointHolder WaypointHolder;

struct WaypointObject {
    s32 serial;
    s32 type;
    u8 pad8[4];
    s32 alive;
    u8 pad10[0x240];
};

struct WaypointRef {
    WaypointObject *object;
    s32 serial;
};

struct WaypointRefList {
    s32 pad0;
    WaypointRef refs[128];
};

struct WaypointHolder {
    u8 pad0[0xC];
    WaypointObject **object;
};

extern WaypointObject D_80235F00[];
extern WaypointHolder **func_800A9928(WaypointObject *, s32, s32, s32, s32);

static inline s32 waypoint_ref_valid(WaypointRef *ref)
{
    WaypointObject *object = ref->object;

    if (object == 0 || object->serial != ref->serial) {
        return 0;
    }

    switch (object->type) {
        case 0x43:
            return 1;
        case 4:
            return object->alive != 0;
    }

    return 0;
}

static inline WaypointObject *waypoint_from_u16(u16 index)
{
    if (index == 127) {
        return 0;
    }
    return &D_80235F00[index];
}

static inline WaypointObject *waypoint_from_int(s32 index)
{
    if (index == 127) {
        return 0;
    }
    return &D_80235F00[index];
}

WaypointRef *func_8008A3F8(WaypointRefList *list, u16 index)
{
    WaypointRef *ref = &list->refs[index];
    WaypointObject *object;
    WaypointObject *fallback;
    WaypointHolder **found;

    if (!waypoint_ref_valid(ref)) {
        fallback = waypoint_from_int(index);
    } else {
        object = waypoint_from_u16(index);
        switch (ref->object->type) {
            case 0x43:
                found = func_800A9928(object, 0, 1, 0, 0);
                if (found == 0) {
                    fallback = waypoint_from_int(index);
                } else {
                    ref->object = (WaypointObject *)*found;
                    ref->serial = ref->object->serial;
                    return ref;
                }
                break;

            case 4: {
                s32 alive = ref->object->alive;

                found = func_800A9928(object, alive, 1, 2, 0);
                if (found == 0) {
                    fallback = waypoint_from_u16(index);
                } else {
                    ref->object = *(*found)->object;
                    ref->serial = ref->object->serial;
                    return ref;
                }
                break;
            }

            default:
                fallback = waypoint_from_u16(index);
                break;
        }
    }

    {
        WaypointRef *result = &list->refs[index];

        result->object = fallback;
        result->serial = fallback->serial;
        return result;
    }
}
