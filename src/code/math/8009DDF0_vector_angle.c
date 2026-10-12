/* RODATA_VRAM 0x800725FC */

#include "types.h"

typedef struct {
    f32 x;
    f32 y;
} Vec2;

#define ABS(value) ((value) > 0.0f ? (value) : -(value))

extern s32 func_8009D5B4(f32 value);

static inline f32 abs_compare(f32 value) {
    if (value > 0.0f) {
        return value;
    }
    return -value;
}

u16 func_8009DDF0(const Vec2 *v) {
    f32 abs_x;
    f32 distance;

    if (v->x > 0.0f) {
        abs_x = v->x;
    } else {
        abs_x = -v->x;
    }

    distance = ((abs_x > ABS(v->y)) ? ABS(v->x) : ABS(v->y)) +
               ((abs_compare(v->x) < ABS(v->y)) ? ABS(v->x) : ABS(v->y)) *
                   3.0f / 8.0f;

    if (distance > 0.0f) {
        if (v->x < 0.0f) {
            return -func_8009D5B4(v->y / distance);
        }
        return func_8009D5B4(v->y / distance);
    }
    return 0;
}
