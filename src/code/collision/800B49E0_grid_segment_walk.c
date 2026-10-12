/* Walk a segment through the collision grid. */
typedef unsigned char u8;
typedef short s16;
typedef unsigned short u16;
typedef unsigned int u32;

typedef struct {
    int unk0;
    int unk4;           /* 0x04 */
    u16 link[4];        /* 0x08 */
    s16 x, z, y;        /* 0x10 */
    s16 dx0, dx1;       /* 0x16 */
    s16 dz0, dz1;       /* 0x1A */
    u16 unk1E, unk20;   /* 0x1E */
    s16 radius;         /* 0x22 */
    u16 unk24;          /* 0x24 */
    u16 grid;           /* 0x26 */
} GridNode;

typedef struct {
    s16 x0, z0;         /* 0x00 */
    u16 w, h;           /* 0x04 */
    u16 cw, ch;         /* 0x08 */
    u16 *cells;         /* 0x0C */
    float scale;        /* 0x10 */
    void *tbl;          /* 0x14 */
} Grid;

typedef struct { float x, y; } Vec2;

typedef struct {
    int data;           /* 0x00 */
    u16 id;             /* 0x04 */
    float x, z, y;      /* 0x08 */
    Vec2 push;          /* 0x14 */
    float unk1C;        /* 0x1C */
    s16 side;           /* 0x20 */
} Contact;

extern GridNode D_803978E0[];
extern Grid D_803977F0[];
extern u16 D_801166F0;
extern u16 D_80397658[];
extern u16 D_801166E0[4];
extern u16 D_801166E8[4];

u16 func_800B2890(s16 x, s16 z, u16 id);

extern inline void func_800B0B8C(u16 id) {
    GridNode *n = &D_803978E0[id];

    n->grid |= 0x1000;
    D_80397658[D_801166F0] = id;
    D_801166F0++;
}

extern inline void func_800B0BE0(void) {
    u16 i;

    for (i = 0; i < D_801166F0; i++) {
        (&D_803978E0[(&D_80397658[i])[0]])->grid &= ~0x1000;
    }
    D_801166F0 = 0;
}

u16 func_800B4684(Vec2 *a, Vec2 *b, u16 head, u16 dir, int mask, u16 layer, u16 grow, int excl,
                  Contact *best, u32 *bestd);

#define ABS(x) ((x) > 0.0f ? (x) : -(x))

u16 func_800B49E0(Vec2 *a, Vec2 *b, int mask, u16 layer, u16 grow, int excl, Contact *out) {
    Grid *g = &D_803977F0[layer];
    float dx = b->x - a->x;
    float dy = b->y - a->y;
    float sx, sy;
    u32 best = -1;
    u16 nx, ny, steps;
    int cx, cy;
    u16 res = 0;
    u16 k, i;

    nx = ABS(dx) / 512.0f;
    ny = ABS(dy) / 512.0f;
    nx = nx ? nx : 1;
    ny = ny ? ny : 1;
    if (nx >= ny) {
        steps = nx;
        sx = dx / nx;
        sy = dy / nx;
    } else {
        steps = ny;
        sx = dx / ny;
        sy = dy / ny;
    }
    cx = (s16)(a->x + sx / 2.0f - g->x0);
    cy = (s16)(a->y + sy / 2.0f - g->z0);
    if (cx < 0 || cy < 0 || cx >= g->cw << 10 || cy >= g->ch << 10) {
        func_800B0BE0();
        return 0;
    }
    for (k = 0; ; ) {
        if (cx < 0 || cy < 0 || cx >= g->cw << 10 || cy >= g->ch << 10) {
            break;
        }
        for (i = 0; i < 4; i++) {
            res |= func_800B4684(a, b,
                                 g->cells[1 + (u16)((((cy + D_801166E8[i]) >> 10) + i * g->ch) * g->cw
                                                    + ((cx + D_801166E0[i]) >> 10))],
                                 i, mask, layer, grow, excl, out, &best);
        }
        if (res) {
            break;
        }
        cx += (s16)sx;
        cy += (s16)sy;
        k++;
        if (k > steps) {
            break;
        }
    }
    res |= func_800B4684(a, b, g->cells[0], 0, mask, layer, grow, excl, out, &best);
    func_800B0BE0();
    return res;
}
