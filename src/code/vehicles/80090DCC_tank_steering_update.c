/* func_80090DCC: per-kind steering response (tilt, turn, sidestep, pitch).
 * Owns .rodata 0x80071E58..0x80071EE0 (6-entry jump table + 28 constants).
 * The corner table D_80071DD4 is emitted by func_800904C8's source unit (same original TU);
 * this unit copies it from the extern symbol. */
/* RODATA_VRAM 0x80071E58 */
/* SPAN 0x80091768 */
typedef unsigned short u16;
typedef short s16;
typedef int s32;
typedef unsigned int u32;
typedef float f32;

typedef struct { f32 x, y; } Vec2;
typedef struct { Vec2 v[4]; } Corners;
typedef struct { char p[0x38]; } Mover;

typedef struct {
    char p000[8];
    f32 x;              /* 0x008 */
    f32 y;              /* 0x00C */
    char p010[0x10];
    u16 ang;            /* 0x020 */
    char p022[4];
    u16 pitch;          /* 0x026 */
    Mover mv;           /* 0x028 */
    char p060[0x6A - 0x60];
    u16 roll;           /* 0x06A */
    char p06c[0x8C - 0x6C];
    u16 f8C;            /* 0x08C */
    char p08e[0x98 - 0x8E];
    s32 kind;           /* 0x098 */
    char p09c[0x1F4 - 0x9C];
    u16 index;          /* 0x1F4 */
    char p1f6[0x272 - 0x1F6];
    u16 tiltAng;        /* 0x272 */
    f32 f274;           /* 0x274 */
    f32 f278;           /* 0x278 */
    s32 tiltState;      /* 0x27C */
} Tank;

#define MV_SPEED(t)    (*(f32 *)((char *)&(t)->mv + 0x8))   /* 0x030 */
#define MV_MAXSPEED(t) (*(f32 *)((char *)&(t)->mv + 0xC))   /* 0x034 */

#define MIN(a, b) ((a) < (b) ? (a) : (b))

extern Corners D_80071DD4;
extern f32 D_80219488;

void func_80095B90(Tank *t, s32 sfx);
f32 func_8009D4B0(u16 a);
f32 func_8009D510(u16 a);
void func_800B129C(u16 id, s16 x, s16 z);
void func_800B5DA8(Mover *mv, f32 speed, u16 ang);

/* Same body as func_800904C8 (inlined in the original translation unit). */
static inline f32 tiltExtent(s32 ang, f32 *out) {
    Corners c = D_80071DD4;
    f32 maxX, maxY, s, cs, v;
    s32 i;

    maxX = 0.0f;
    maxY = 0.0f;
    s = func_8009D4B0(ang);
    cs = func_8009D510(ang);
    for (i = 0; i < 4; i++) {
        v = cs * c.v[i].y - s * c.v[i].x;
        if (!(v > 0.0f)) {
            v = -v;
        }
        if (maxX < v) {
            maxX = v;
        }
        v = s * c.v[i].y + cs * c.v[i].x;
        if (!(v > 0.0f)) {
            v = -v;
        }
        if (maxY < v) {
            maxY = v;
        }
    }
    *out = maxY / 37.25f;
    return maxX;
}
static inline unsigned int narrow16(s16 value) { return (u16)value; }
static inline unsigned int narrowu16(u16 value) { return value; }

void func_80090DCC(Tank *t, s16 dir) {
    switch (t->kind) {
    case 3:
        if (dir < 0) {
            func_80095B90(t, 0x33);
            t->tiltState = 1;
            t->tiltAng--;
        } else if (dir > 0) {
            func_80095B90(t, 0x33);
            t->tiltState = 2;
        }
        switch (t->tiltState) {
        case 2: {
            u16 step;
            u16 nt;

            step = D_80219488 * 512.0f * 3.0f;
            if ((t->tiltAng & 0x7FFF) < 0x2000) {
                step = step * 2.5f;
            }
            nt = narrowu16(t->tiltAng + step);
            if ((nt >> 15) != (t->tiltAng >> 15)) {
                t->tiltAng = (t->tiltAng + step) - (nt & 0x7FFF);
                t->tiltState = 0;
                func_80095B90(t, 0x32);
            } else {
                t->tiltAng = t->tiltAng + step;
            }
            t->f274 = tiltExtent(t->tiltAng, &t->f278);
            t->x += -func_8009D510(t->ang) * step * 0.005f;
            t->y += func_8009D4B0(t->ang) * step * 0.005f;
            func_800B129C(t->index, t->x, t->y);
            break;
        }
        case 1: {
            u16 step;
            u16 old;
            unsigned int old16;
            u16 next;
            unsigned int next16;

            step = D_80219488 * 512.0f * 3.0f;
            if ((t->tiltAng & 0x7FFF) > 0x6000) {
                step = step * 2.5f;
            }
            old = t->tiltAng;
            next = old - step;
            next16 = next;
            old16 = narrow16(old);
            if (next16 >> 15 != old16 >> 15) {
                t->tiltAng = old - (old16 & 0x7FFF);
                t->tiltState = 0;
                func_80095B90(t, 0x32);
            } else {
                t->tiltAng = next;
            }
            t->f274 = tiltExtent(t->tiltAng, &t->f278);
            t->x += func_8009D510(t->ang) * step * 0.005f;
            t->y += -func_8009D4B0(t->ang) * step * 0.005f;
            func_800B129C(t->index, t->x, t->y);
            break;
        }
        }
        break;
    case 1:
        if ((t->f8C & 0xF) == 0xF) {
            if (dir == 0) {
                t->f274 = 13.0f;
            } else if (t->f274 > 0.0f) {
                t->f274 -= D_80219488;
                if (dir < 0) {
                    t->ang += 0x888;
                } else {
                    t->ang -= 0x888;
                }
            }
        }
        break;
    case 5:
        if ((t->f8C & 0xF) == 0xF) {
            if (dir == 0) {
                t->f274 = 18.0f;
            } else if (t->f274 > 0.0f) {
                t->f274 -= D_80219488;
                if (dir < 0) {
                    t->ang += 0x666;
                } else {
                    t->ang -= 0x666;
                }
            }
        }
        break;
    case 4:
        if (dir != 0) {
            f32 max = MV_MAXSPEED(t) * 0.7f;
            u16 ang = t->ang;
            s16 side;
            u16 d;

            if (dir < 0) {
                ang += 0x4000;
                side = 1;
            } else {
                ang -= 0x4000;
                side = -1;
            }
            func_800B5DA8(&t->mv, D_80219488 * 500.0f, ang);
            if (max < MV_SPEED(t)) {
                MV_SPEED(t) = max;
            }
            d = MV_SPEED(t) / max * 1456.0f * D_80219488;
            if (side > 0) {
                t->roll -= d;
            } else {
                t->roll += d;
            }
        }
        break;
    case 6:
        if (dir > 0) {
            t->pitch = t->pitch - D_80219488 * 512.0f;
            if (t->pitch > 0x8000 && t->pitch < 0xC000) {
                t->pitch = 0xC000;
            }
        } else if (dir < 0) {
            t->pitch = t->pitch + D_80219488 * 512.0f;
            if (t->pitch > 0x4000 && t->pitch < 0x8000) {
                t->pitch = 0x4000;
            }
        } else if (t->pitch <= 0x7FFF) {
            t->pitch = t->pitch - MIN((f32)t->pitch, D_80219488 * 512.0f);
        } else {
            t->pitch = t->pitch + MIN((f32)(0x10000 - t->pitch), D_80219488 * 512.0f);
        }
        break;
    }
}
