#include "types.h"

typedef struct {
    s32 unk0;
    s32 unk4;
    u16 link[4];
    s16 x;
    s16 z;
    s16 y;
    s16 dx0;
    s16 dx1;
    s16 dz0;
    s16 dz1;
    u16 unk1E;
    u16 unk20;
    s16 radius;
    u16 angle;
    u16 grid;
} GridNode;

typedef struct {
    f32 x;
    f32 y;
} Vec2;

extern GridNode D_803978E0[];

f32 func_8009D4B0(u16 angle);
f32 func_8009D510(u16 angle);
u16 func_800B2DF4(GridNode *a, GridNode *b);
void func_8009E948(Vec2 *vector);

static inline GridNode *grid_node(u16 index)
{
    return &D_803978E0[index];
}

static inline void grid_node_relative(GridNode *a, GridNode *b, GridNode *out)
{
    f32 dx = b->x - a->x;
    f32 dz = b->z - a->z;
    f32 cosine = func_8009D510(a->angle);
    f32 sine = func_8009D4B0(a->angle);

    out->x = cosine * dx + -sine * dz;
    out->z = sine * dx + cosine * dz;
    out->angle = b->angle - a->angle;
    out->dx0 = b->dx0;
    out->dx1 = b->dx1;
    out->dz0 = b->dz0;
    out->dz1 = b->dz1;
}

u16 func_800B3018(u16 first_index, u16 second_index, Vec2 *push, s16 *side)
{
    GridNode *first = grid_node(first_index);
    GridNode *second = grid_node(second_index);
    GridNode relative;
    f32 sine;
    f32 cosine;
    u16 contacts;
    s16 half_x;
    s16 half_z;
    GridNode *saved_first;

    saved_first = first;
    if (func_800B2DF4(first, second)) {
        return 0;
    }
    if (func_800B2DF4(second, first)) {
        return 0;
    }

    grid_node_relative(second, saved_first, &relative);
    sine = func_8009D4B0(second->angle);
    cosine = func_8009D510(second->angle);
    push->x = 0.0f;
    push->y = 0.0f;
    *side = 0;
    contacts = 0;

    if (relative.x < second->dx0) {
        contacts = 1;
        push->x = -cosine;
        push->y = sine;
        *side = 4;
    } else if (second->dx1 < relative.x) {
        contacts = 1;
        push->x = cosine;
        push->y = -sine;
        *side = 3;
    }

    if (relative.z < second->dz0) {
        push->x -= sine;
        push->y -= cosine;
        contacts++;
        *side = 2;
    } else if (second->dz1 < relative.z) {
        push->x += sine;
        push->y += cosine;
        contacts++;
        *side = 1;
    }

    if (push->x == 0.0f && push->y == 0.0f) {
        half_x = (second->dx1 - second->dx0) >> 1;
        half_z = (u32)(second->dz1 - second->dz0) >> 1;

        if (relative.x < half_x) {
            contacts++;
            push->x = -cosine;
            push->y = sine;
            *side = 4;
        } else if (half_x < relative.x) {
            contacts++;
            push->x = cosine;
            push->y = -sine;
            *side = 3;
        }

        if (relative.z < half_z) {
            push->x -= sine;
            push->y -= cosine;
            contacts++;
            *side = 2;
        } else if (half_z < relative.z) {
            push->x += sine;
            push->y += cosine;
            contacts++;
            *side = 1;
        }
    }

    if (contacts >= 2) {
        func_8009E948(push);
    }
    return 1;
}
