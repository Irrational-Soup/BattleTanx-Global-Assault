#include "types.h"

/* RODATA_VRAM 0x80072B90 */

typedef struct {
    f32 x;
    f32 y;
    f32 z;
} Vec3f;

typedef struct {
    u8 pad0[0x30];
    Vec3f eye;
    u8 pad3C[0x90 - 0x3C];
    f32 shake;
} CameraState;

typedef struct {
    u8 pad0[0x78];
    CameraState camera;
    u8 pad10C[0x250 - 0x10C];
} PlayerUnit;

typedef struct {
    f32 x;
    f32 y;
} Vec2f;

typedef struct {
    void *world;
    s32 track;
    u32 mode;
    u8 human_player_count;
    u8 player_count;
} GameState;

extern GameState D_80219498;
extern PlayerUnit D_80235F00[];

static inline PlayerUnit *get_player_unit(s32 player) {
    if (player == 127) {
        return 0;
    }
    return &D_80235F00[player];
}

#define ABS(value) ((value) > 0.0f ? (value) : -(value))
#define MAX(a, b) ((a) > (b) ? (a) : (b))
#define MIN(a, b) ((a) < (b) ? (a) : (b))
#define DIST(dx, dy) \
    (MAX(ABS(dx), ABS(dy)) + MIN(ABS(dx), ABS(dy)) * 3.0f / 8.0f)

void func_800A7090(Vec2f *position, s32 unused, f32 amplitude,
                   f32 near_distance, f32 far_distance) {
    s32 i;

    (void)unused;
    for (i = 0; i < D_80219498.player_count; i++) {
        CameraState *camera = &get_player_unit(i)->camera;
        f32 distance = DIST(camera->eye.x - position->x,
                            camera->eye.y - position->y);

        if (far_distance < distance) {
            return;
        }
        if (distance < near_distance) {
            if (camera->shake < amplitude) {
                camera->shake = amplitude;
            }
        } else {
            f32 shake = amplitude - amplitude *
                ((distance - near_distance) / (far_distance - near_distance));

            if (camera->shake < shake) {
                camera->shake = shake;
            }
        }
    }
}
