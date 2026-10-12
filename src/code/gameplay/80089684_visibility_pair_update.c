/* RODATA_VRAM 0x800718A0 */
typedef unsigned char u8;
typedef unsigned short u16;

typedef struct {
    void *obj;
    char pad04[0x24];
} Hit;

typedef struct Unit {
    int objectId;
    char pad04[4];
    float x;
    float y;
    char pad10[0x94 - 0x10];
    u8 color;
    char pad95[0xA4 - 0x95];
    int visibilityBit;
    int visible;
    int visibleBy;
    char padB0[0x150 - 0xB0];
    float eye[2];
    char pad158[0x168 - 0x158];
    int mode;
    char pad16C[0x1BC - 0x16C];
    float visibilityRange;
    char pad1C0[0x1D0 - 0x1C0];
    struct {
        char pad00[0x10];
        int team;
    } *owner;
    char pad1D4[0x1E0 - 0x1D4];
    int flags;
    char pad1E4[0x4CC - 0x1E4];
} Unit;

typedef struct {
    u8 first;
    u8 second;
} VisibilityPair;

extern Unit D_801AD128[];
extern u16 D_801ACEF4;
extern VisibilityPair D_801ACEF8[];
extern short D_80397650;

u16 func_800B49E0(float *, float *, int, int, int, int, Hit *);

#define ABS(value) ((value) > 0.0f ? (value) : -(value))
#define MAX(a, b) ((a) > (b) ? (a) : (b))
#define MIN(a, b) ((a) < (b) ? (a) : (b))
#define DIST(dx, dy) (MAX(ABS(dx), ABS(dy)) + MIN(ABS(dx), ABS(dy)) * 3.0f / 8.0f)

static inline u16 visibilityTest(float *from, float *to, int mask, int color,
                                 int radius, int owner, Hit *hit) {
    D_80397650 = 0;
    return func_800B49E0(from, to, mask, color, radius, owner, hit);
}

void func_80089684(void) {
    u16 i;
    int bothAI = 0;
    u16 radius;
    Hit hit;

    i = 0;
    radius = 0;
    for (; i < 69; i++) {
        Unit *a;
        Unit *b;
        int sameTeam;
        float range;
        float aRange;

        if (++D_801ACEF4 >= 276) {
            D_801ACEF4 = 0;
        }
        a = &D_801AD128[D_801ACEF8[D_801ACEF4].first];
        b = &D_801AD128[D_801ACEF8[D_801ACEF4].second];
        if (!(a->flags & 1) || !(b->flags & 1)) {
            a->visibleBy &= ~b->visibilityBit;
            b->visibleBy &= ~a->visibilityBit;
            a->visible &= ~b->visibilityBit;
            b->visible &= ~a->visibilityBit;
            continue;
        }
        if (a->flags & 2) {
            if (b->flags & 2) {
                continue;
            }
        } else if (!(b->flags & 2)) {
            bothAI = 1;
        }
        sameTeam = a->owner->team == b->owner->team;
        if (sameTeam) {
            if (DIST(a->x - b->x, a->y - b->y) > 1000.0f || a->color != b->color) {
                a->visibleBy &= ~b->visibilityBit;
                b->visibleBy &= ~a->visibilityBit;
                continue;
            }
        } else {
            aRange = a->visibilityRange;
            range = b->visibilityRange < aRange ? aRange : b->visibilityRange;
            if (range < 1400.0f) {
                if (a->mode == 7 || b->mode == 7 || a->mode == 8 || b->mode == 8) {
                    range = 3000.0f;
                    if (bothAI) {
                        range = 1400.0f;
                    }
                }
            }
            if (DIST(a->x - b->x, a->y - b->y) > range || a->color != b->color) {
                goto unseen;
            }
        }
        if (sameTeam) {
            a->visibleBy |= b->visibilityBit;
            b->visibleBy |= a->visibilityBit;
            continue;
        }
        if (visibilityTest(a->eye, b->eye, 0x24100B, a->color, radius,
                           a->objectId, &hit) != 0 &&
            hit.obj != (void *)b->objectId) {
            goto unseen;
        }
        if (!(b->flags & 0x80)) {
            a->visible |= b->visibilityBit;
        } else {
            a->visible &= ~b->visibilityBit;
        }
        if (!(a->flags & 0x80)) {
            b->visible |= a->visibilityBit;
        } else {
            b->visible &= ~a->visibilityBit;
        }
        continue;

    unseen:
        a->visible &= ~b->visibilityBit;
        b->visible &= ~a->visibilityBit;
    }
}
