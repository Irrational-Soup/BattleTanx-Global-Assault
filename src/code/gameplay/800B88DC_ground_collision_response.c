/* RODATA_VRAM 0x8007317C */
#include "types.h"

typedef struct {
    f32 x;
    f32 y;
} Vec2;

typedef struct {
    u32 kind;
    s32 unk04;
    u16 links[4];
    s16 x;
    s16 z;
    s16 y;
    s16 dx0;
    s16 dx1;
    s16 dz0;
    s16 dz1;
    s16 height0;
    s16 height1;
    s16 radius;
    u16 angle;
    u16 grid;
} GridNode;

typedef struct {
    void *data;
    u16 id;
    u8 pad06[0x24 - 6];
} Contact;

typedef struct {
    u8 pad00[0x24];
    f32 gravity;
    f32 base;
    f32 bounce;
    u8 pad30[0x3C - 0x30];
    u16 pitch;
    u16 roll;
    u8 pad40[0x44 - 0x40];
    f32 corner[4];
    f32 velocity[4];
    u16 flags;
    u8 pad66[2];
    s32 frozen;
} GroundObject;

extern GridNode D_803978E0[];
extern f32 D_80219488;
extern u16 D_80397650;

void func_800B2364(Vec2 *input, u16 angle, Vec2 *output);
u16 func_800B5130(Vec2 *point, s32 mask, u16 grid, Contact *out, u16 single);
u16 func_800B3748(u16 id, s32 mask, Contact *out, u16 grow, u16 single);
void func_800B2BE4(GridNode *node, Vec2 *corners);
u16 func_800B2890(s16 x, s16 y, u16 id);
f32 func_800B83A8(u16 id, Vec2 *point);
u16 func_8009D578(f32 ratio);
f32 sqrtf(f32 value);
s32 abs(s32 value);

static inline f32 sloped_height(u16 id, Vec2 *point) {
    GridNode *node = &D_803978E0[id];
    Vec2 delta;
    Vec2 rotated;

    delta.x = point->x - node->x;
    delta.y = point->y - node->z;
    func_800B2364(&delta, node->angle, &rotated);
    return (node->height0 + node->y) +
        (f32)(node->height1 - node->height0) *
        (rotated.y - node->dz0) / (node->dz1 - node->dz0);
}

static inline f32 flat_height(u16 id) {
    GridNode *node = &D_803978E0[id];

    if (abs(node->height0) > abs(node->height1)) {
        return node->height0 + node->y;
    }
    return node->height1 + node->y;
}

static inline u16 slope_angle(f32 delta, f32 width) {
    f32 magnitude;
    u16 negative;
    u16 angle;
    u16 result;

    magnitude = delta;
    if (delta < 0.0f) {
        negative = 1;
        magnitude = -delta;
    } else {
        negative = 0;
    }
    angle = (u16)func_8009D578(
        magnitude / sqrtf(magnitude * magnitude + width * width)) >> 1;
    result = angle;
    if (negative) {
        result = angle ^ 0xFFFF;
    }
    return result;
}

void func_800B88DC(GroundObject *object, u16 id, f32 *out_height) {
    Vec2 corners[4];
    Vec2 *corner;
    f32 previous[4];
    Contact contacts[32];
    Vec2 delta;
    Vec2 rotated;
    s16 dimensions[2];
    f32 base;
    f32 height;
    f32 difference;
    u16 count;
    u8 corners_loaded;
    u8 moved;
    u16 i;
    u16 j;
    GridNode *node;

    if (object->frozen != 0) {
        object->flags |= 0xF;
        return;
    }

    for (i = 0; i < 4; i++) {
        object->velocity[i] -= object->gravity * D_80219488;
        previous[i] = object->corner[i];
        object->corner[i] += object->velocity[i];
    }

    object->pitch = 0;
    object->roll = 0;
    D_80397650 = 0;
    count = func_800B3748(id, 0xE0, contacts, 0, 0);
    corners_loaded = 0;
    corner = corners;
    moved = 0;
    base = object->base;
    object->flags &= 0xFFF0;

    for (i = 0; i < 4; i++) {
        height = base;
        for (j = 0; j < count; j++) {
            if (!corners_loaded) {
                func_800B2BE4(&D_803978E0[id], corner);
                corners_loaded = 1;
            }
            if (func_800B2890(corner[i].x, corner[i].y, contacts[j].id)) {
                node = &D_803978E0[contacts[j].id];
                switch (node->kind & 0xE0) {
                case 0x40:
                    height = func_800B83A8(contacts[j].id, &corner[i]);
                    break;
                case 0x80:
                    delta.x = corner[i].x - node->x;
                    delta.y = corner[i].y - node->z;
                    func_800B2364(&delta, node->angle, &rotated);
                    height = (node->height0 + node->y) +
                        (f32)(node->height1 - node->height0) *
                        (rotated.y - node->dz0) / (node->dz1 - node->dz0);
                    break;
                case 0x20:
                    height = flat_height(contacts[j].id);
                    break;
                }
                break;
            }
        }

        if (height < base) {
            if (height < 0.0f) {
                height += base;
            } else {
                height = base;
            }
        }
        if (object->corner[i] < height) {
            object->corner[i] = height;
            difference = height - previous[i];
            if (0.0f <= difference) {
                object->velocity[i] = object->bounce * difference / D_80219488;
            } else {
                object->velocity[i] *= -0.5f;
            }
            switch (i) {
            case 0:
                object->flags |= 1;
                break;
            case 1:
                object->flags |= 2;
                break;
            case 2:
                object->flags |= 4;
                break;
            default:
                object->flags |= 8;
                break;
            }
        }
        if (object->corner[i] != object->base) {
            moved = 1;
        }
    }

    if (moved) {
        GridNode *current = &D_803978E0[id];

        dimensions[0] = (current->dx1 - current->dx0 > 0)
            ? current->dx1 - current->dx0
            : current->dx0 - current->dx1;
        dimensions[1] = (current->dz1 - current->dz0 > 0)
            ? current->dz1 - current->dz0
            : current->dz0 - current->dz1;

        difference = object->corner[0] - object->corner[1];
        if (difference != 0.0f) {
            object->pitch = slope_angle(difference, dimensions[1]);
        }
        difference = object->corner[3] - object->corner[2];
        if (difference != 0.0f) {
            object->pitch += slope_angle(difference, dimensions[1]);
        }
        difference = object->corner[3] - object->corner[0];
        if (difference != 0.0f) {
            object->roll = slope_angle(difference, dimensions[0]);
        }
        difference = object->corner[2] - object->corner[1];
        if (difference != 0.0f) {
            object->roll += slope_angle(difference, dimensions[0]);
        }
        *out_height = (object->corner[0] + object->corner[1] +
                       object->corner[2] + object->corner[3]) / 4.0f;
    } else {
        *out_height = object->base;
    }
}
