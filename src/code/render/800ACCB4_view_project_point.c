/* RODATA_VRAM 0x80072E8C */

typedef unsigned char u8;
typedef short s16;

typedef struct {
    float x, y;
    float axis0_x;
    float axis0_y;
    float axis1_x;
    float axis1_y;
    float offset_y;
    float offset_x;
    u8 pad20[4];
    u8 active;
    u8 kind;
    u8 pad26[2];
} View;

typedef struct {
    void *world;
    int track;
    unsigned int mode;
    u8 nHuman;
    u8 nPlayers;
    u8 nTanks;
    u8 nSlots;
    u8 teams[5];
    char pad13[3];
    int time;
    View views[4];
} GameState;

typedef struct {
    s16 sx, sy, pad4[2], ox, oy;
} Viewport;

typedef struct {
    u8 pad00[0xC0];
    float eye[0x17];
    Viewport *viewport;
    u8 pad120[4];
    float at[0x4B];
} Player;

extern GameState D_80219498;
extern Player D_80235F00[];
void func_8009F4B4(void *eye, void *at, float *m);
void func_8009F334(float *m, float *in, float *out);

static inline int view_contains(float x, float y, u8 kind, View *region) {
    float distance;
    float extent;
    float ry;
    float rx;

    if (region->kind != kind) {
        return 0;
    }
    if (region->active != 0) {
        return 1;
    }
    ry = y + region->offset_x;
    rx = x + region->offset_y;
    distance = region->axis0_x * ry + region->axis0_y * rx;
    if (distance <= 0.0f) {
        return 0;
    }
    extent = region->axis1_x * rx - region->axis1_y * ry;
    if (extent > 0.0f) {
        if (distance <= extent) {
            return 0;
        }
    } else if (distance <= -extent) {
        return 0;
    }
    return 1;
}

int func_800ACCB4(float *in, float *out, u8 kind, int view) {
    Player *pl;
    float m[16];
    Viewport *vp;

    if (view == 127) {
        pl = 0;
    } else {
        pl = &D_80235F00[view];
    }
    if (pl->viewport == 0) {
        return 0;
    }
    if (!view_contains(in[0], in[1], kind, &D_80219498.views[view])) {
        return 0;
    }
    func_8009F4B4(pl->eye, pl->at, m);
    func_8009F334(m, in, out);
    vp = pl->viewport;
    out[0] = (out[0] * vp->sx + vp->ox) / 4.0f;
    vp = pl->viewport;
    out[2] = (out[2] * -vp->sy + vp->oy) / 4.0f;
    return 1;
}
