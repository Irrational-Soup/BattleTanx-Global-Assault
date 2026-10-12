/* Translation unit 0x8009299C..0x80094744: func_8009299C + func_80092C38 (close-tank-render-state).
 * Owns .rodata 0x80071FD8..0x80072158 (0x180). The jump table and doubles make the unit's .rodata
 * 8-aligned, so func_80092C38's pool (0x80071FDC) can only be emitted together with func_8009299C's
 * 2^31 constant at 0x80071FD8: a standalone func_80092C38 object cannot match (tested, see HANDOFF).
 * func_80092C38: exact, clean (no function-gated normalizer rule), production pipeline and ASN64.
 * func_8009299C: unchanged from the data-owner lane; exact only with the existing production rule
 * V3_TANK_COLOR_FADE_SCHEDULE (normalizer-assisted, already integrated). */
/* RODATA_VRAM 0x80071FD8 */
/* SPAN 0x80094744 */
typedef signed char s8;
typedef unsigned char u8;
typedef short s16;
typedef unsigned short u16;
typedef int s32;
typedef unsigned int u32;
typedef float f32;

typedef struct { f32 x, y; } Vec2;
typedef struct { f32 x, y, z; } Vec3;
typedef struct { f32 m[4][4]; } Mtx;
typedef struct { Mtx mtx; s32 flag; } MtxObj;
typedef struct { u32 w0, w1; } Gfx;

typedef struct {
    s16 kind;           /* 0x00 */
    f32 radius;         /* 0x04 */
    f32 time;           /* 0x08 */
    f32 amp;            /* 0x0C */
} Ripple;

typedef struct {
    u8 primFrom[4];     /* 0x00 */
    u8 envFrom[4];      /* 0x04 */
    s32 duration;       /* 0x08 */
    u8 primTo[4];       /* 0x0C */
    u8 envTo[4];        /* 0x10 */
} ColorFade;

typedef struct {
    s32 type;           /* 0x00 */
    s32 tex;            /* 0x04 */
} Part;

typedef struct {
    s32 nPartsA;        /* 0x00 */
    Part *partsA;       /* 0x04 */
    s32 nPartsB;        /* 0x08 */
    Part *partsB;       /* 0x0C */
    char p10[6];
    s16 length;         /* 0x16 */
    char p18[6];
    s16 height;         /* 0x1E */
    char p20[0x10];
    s32 animDur;        /* 0x30 */
    char p34[0x20];
    s32 shadowTex;      /* 0x54 */
    char p58[0x38];
    s32 flags;          /* 0x90 */
    f32 turretX;        /* 0x94 */
    f32 turretZ;        /* 0x98 */
    f32 turretY;        /* 0x9C */
    char pa0[4];
    f32 barrelX;        /* 0xA4 */
    f32 barrelZ;        /* 0xA8 */
    f32 barrelY;        /* 0xAC */
    char pb0[8];
    u16 radius;         /* 0xB8 */
    char pba[2];
    s32 trailId;        /* 0xBC */
    char pc0[0x10];
} TankDef;

typedef struct {
    s32 tex[2];         /* D_80122E8C / D_80122E90 */
    char p8[0xD0 - 8];
} TankTexDef;

typedef struct {
    char p0[0x70];
    s32 f70;            /* 0x070 */
    char p74[0x1E4 - 0x74];
    u8 color[3];        /* 0x1E4 */
} Player;

typedef struct {
    char p0[0xC];
    f32 x;              /* 0x0C */
    f32 z;              /* 0x10 */
    f32 y;              /* 0x14 */
    u16 ang;            /* 0x18 */
    char p1a[6];
    u8 kind;            /* 0x20 */
} Attach;

typedef struct {
    s32 tex;
    char p4[0x5C];
} AttachDef;

typedef union {
    s32 w;
    struct { u16 a, b; } h;
} AnglePair;

typedef struct {
    s32 id;             /* 0x000 */
    char p004[0x1C];
    u16 ang;            /* 0x020 */
    char p022[2];
    u16 turretAng;      /* 0x024 */
    char p026[0xA];
    f32 speed;          /* 0x030 */
    f32 maxSpeed;       /* 0x034 */
    char p038[0x2C];
    AnglePair roll;     /* 0x064 */
    AnglePair tilt;     /* 0x068 */
    char p06c[0x20];
    u16 f8C;            /* 0x08C */
    char p08e[6];
    u8 state;           /* 0x094 */
    u8 pad;             /* 0x095 */
    u8 trailHead;       /* 0x096 */
    u8 trailCount;      /* 0x097 */
    s32 kind;           /* 0x098 */
    char p09c[4];
    s32 shadow;         /* 0x0A0 */
    char p0a4[0x1D0 - 0xA4];
    Player *owner;      /* 0x1D0 */
    s32 maxHealth;      /* 0x1D4 */
    s32 health;         /* 0x1D8 */
    char p1dc[4];
    s32 flags;          /* 0x1E0 */
    f32 shakeX;         /* 0x1E4 */
    char p1e8[4];
    f32 shakeY;         /* 0x1EC */
    char p1f0[4];
    u16 index;          /* 0x1F4 */
    char p1f6[0x224 - 0x1F6];
    s32 f224;           /* 0x224 */
    char p228[8];
    s32 fadeStart[2];   /* 0x230 */
    ColorFade *fade[2]; /* 0x238 */
    s32 f240;           /* 0x240 */
    char p244[4];
    s32 f248;           /* 0x248 */
    char p24c[4];
    f32 f250;           /* 0x250 */
    char p254[4];
    f32 scrollL;        /* 0x258 */
    f32 scrollR;        /* 0x25C */
    s32 f260;           /* 0x260 */
    s32 f264;           /* 0x264 */
    char p268[4];
    u16 f26C;           /* 0x26C */
    char p26e[2];
    u16 f270;           /* 0x270 */
    u16 tiltAng;        /* 0x272 */
    f32 f274;           /* 0x274 */
    f32 f278;           /* 0x278 */
    s32 f27C;           /* 0x27C */
    char p280[0x29C - 0x280];
    Mtx trail[8];       /* 0x29C */
    s32 f49C;           /* 0x49C */
    char p4a0[4];
    u16 f4A4;           /* 0x4A4 */
    u8 nAttach;         /* 0x4A6 */
    char p4a7;
    Attach *attach[6];  /* 0x4A8 */
    f32 scale;          /* 0x4C0 */
    s32 f4C4;           /* 0x4C4 */
    s32 f4C8;           /* 0x4C8 */
} Tank;

extern TankDef D_80122E28[];
extern TankTexDef D_80122E8C[];
extern AttachDef D_80123BC8[];
extern Mtx D_8007192C;
extern s32 D_8021945C;
extern s32 D_80117EB4;
extern void *D_803A53A0[];

void func_800998A8(u8 pad, s32 a1, s32 a2, s32 a3, u8 alpha);
s32 func_8009D914(void);
void func_8009EEE0(Mtx *m);
void func_8009EF30(Mtx *m, Vec2 *pos);
void func_8009EF4C(Mtx *m, f32 x, f32 z, u16 ang);
void func_8009EFD4(Mtx *m, f32 x, f32 y, f32 z, u16 ang);
void func_8009F090(Mtx *m, u16 a, u16 b, u16 c);
void func_8009F4B4(Mtx *a, Mtx *b, Mtx *out);
void func_8009F538(Mtx *a, Mtx *b, Mtx *out);
void func_8009F824(Mtx *m, f32 sx, f32 sy, f32 sz);
void func_8009F8A0(Mtx *in, Mtx *out, u16 ang);
void func_8009FA04(Mtx *in, Mtx *out, u16 ang);
void func_8009FB68(Mtx *in, Mtx *out, u16 ang);
void func_8009FCCC(Mtx *m, Vec3 *a, Vec3 *b, u16 ang, s32 c, s32 d);
s32 func_800AA058(u8 state, Vec2 *pos);
u8 func_800ACF20(u16 index, u8 state);
u8 func_800AD14C(f32 x, f32 z, f32 r, u8 state);
void func_800AD9A8(void *tex, s32 a1, MtxObj *m, s32 a3, s32 a4, u8 alpha, Gfx *cmds, s32 n);
void func_800AE184(void *tex, s32 a1, MtxObj *m, s32 xlu, s32 frame, u8 vis, Gfx *cmds, s32 n, s32 a8, Ripple *fx);
void func_800AE4D0(void *tex, s32 a1, MtxObj *m, s32 a3, s32 a4, s32 a5, u8 vis);
void func_800D0858(u16 id, u8 *r, u8 *g, u8 *b);
s32 func_800D0960(u16 id);
s32 func_800E4ECC(Attach *a, s32 id);
void func_800E7768(s32 shadow, Vec3 *pos, u8 state, u16 phase, s32 mask);
void func_800F4698(s32 id, u8 n, Mtx *trail, u8 *c1, u8 *c2, s32 start, s32 len, s32 state);
void func_800F8264(void *tex, MtxObj *m, s32 a2, u8 vis);

static inline void lerpColor(u8 *out, u8 *from, u8 *to, f32 frac) {
    s32 i;

    for (i = 0; i < 4; i++) {
        out[i] = from[i] + (f32)(to[i] - from[i]) * frac;
    }
}

void func_8009299C(Tank *t, MtxObj *pos, u8 alpha) {
    u32 k;

    for (k = 0; k < 2; k++) {
        u8 prim[4];
        u8 env[4];
        Gfx cmds[2];
        f32 frac;
        void **tex;
        void **texTab;

        texTab = D_803A53A0;
        if (t->fadeStart[k] < 0) {
            continue;
        }
        frac = (f32)(D_8021945C - t->fadeStart[k]) / (f32)t->fade[k]->duration;
        lerpColor(env, t->fade[k]->envFrom, t->fade[k]->envTo, frac);
        lerpColor(prim, t->fade[k]->primFrom, t->fade[k]->primTo, frac);
        cmds[0].w0 = 0xFA000000;
        cmds[1].w0 = 0xFB000000;
        cmds[0].w1 = (prim[0] << 24) | (prim[1] << 16) | (prim[2] << 8) | prim[3];
        cmds[1].w1 = (env[0] << 24) | (env[1] << 16) | (env[2] << 8) | env[3];
        if (k == 0) {
            tex = &texTab[D_80122E8C[t->kind].tex[0]];
        } else {
            tex = &texTab[D_80122E8C[t->kind].tex[1]];
        }
        func_800AD9A8(*tex, 0, pos, 1, 0, alpha, cmds, 2);
    }
}

#define gSetWords(pkt, a, b) \
    { \
        Gfx *_g = (Gfx *)(pkt); \
        _g->w0 = (a); \
        _g->w1 = (b); \
    }

#define IDENT { { { { 1.0f, 0.0f, 0.0f, 0.0f }, { 0.0f, 1.0f, 0.0f, 0.0f }, \
                    { 0.0f, 0.0f, 1.0f, 0.0f }, { 0.0f, 0.0f, 0.0f, 1.0f } } }, 0 }

static inline void squash(Mtx *wm, Mtx *m, f32 k, f32 h, f32 w) {
    f32 sx, sy;
    f32 d;
    f32 z;

    m[0] = D_8007192C;
    if (k > 0.66666f) {
        sy = 0.1f;
        z = (1.0f - (k - 0.666666f) / 0.3333333f) * 0.9f + 0.1f;
        sx = 0.1f;
    } else if (k > 0.333333f) {
        sy = 0.1f;
        sx = (1.0f - (k - 0.33333334f) / 0.3333333f) * 0.9f + 0.1f;
        z = 1.0f;
    } else {
        z = 1.0f;
        sy = (1.0f - k / 0.3333333f) * 0.9f + 0.1f;
        sx = 1.0f;
    }
    d = 1.0f - sy;
    m[0].m[0][0] = sx;
    m[0].m[1][1] = sy;
    m[0].m[2][2] = z;
    m[0].m[0][1] = d * (w / h) * sx;
    func_8009F538(&m[0], wm, &m[1]);
    m[1].m[3][0] = wm->m[3][0];
    m[1].m[3][1] = wm->m[3][1] + w * d / 2.0f;
    m[1].m[3][2] = wm->m[3][2];
    m[1].m[0][3] = 0.0f;
    m[1].m[1][3] = 0.0f;
    m[1].m[2][3] = 0.0f;
    m[1].m[3][3] = 1.0f;
    *wm = m[1];
}

void func_80092C38(Tank *t, Vec2 *pos, u8 noFx) {
    MtxObj world = IDENT;
    MtxObj turret;
    Mtx tmp;
    MtxObj *top;
    Player *owner;
    s32 vis2;
    u8 vis;
    s32 drew;
    s32 xlu;
    s32 nParts;
    s32 i;
    u8 alpha;
    s32 dt;
    s32 n;
    Ripple *ripple;
    TankDef *def;
    Part *parts;

    dt = 0;
    drew = 0;
    xlu = 0;
    if (t == 0) {
        return;
    }
    if (t->shadow != 0) {
        Vec3 sp;

        sp.x = pos->x;
        sp.z = (f32)D_80122E28[t->kind].height + 20.0f;
        sp.y = pos->y;
        func_800E7768(t->shadow, &sp, t->state, D_8021945C << 9,
                      (t->flags & 2) ? ~(1 << t->pad) & 0xF : 0xF);
    }
    owner = t->owner;
    if (t->index != 0xFFFF && !noFx) {
        vis = func_800ACF20(t->index, t->state);
    } else {
        vis = func_800AD14C(pos->x, pos->y, D_80122E28[t->kind].radius, t->state);
    }
    if ((t->flags & 8) && (dt = D_8021945C - t->f248) >= 21 && dt < t->f4C4 + 80) {
        return;
    }
    if (t->flags & 0x30) {
        u8 a;

        if (t->f250 >= 1.0) {
            a = 0xFF;
        } else {
            a = t->f250 * 255.0f;
        }
        func_800998A8(t->pad, 0, 0, 0, a);
    }
    if (vis != 0) {
    Gfx cmds[6];
    Ripple fx;
    Mtx m[2];

    func_8009EEE0(&tmp);
    n = 0;
    func_8009EF30(&tmp, pos);
    alpha = 0xFF;
    ripple = 0;
    if (t->roll.w != 0) {
        func_8009FB68(&tmp, &world.mtx, t->roll.h.a);
        func_8009F8A0(&world.mtx, &tmp, t->roll.h.b);
    }
    if (t->tilt.w != 0) {
        func_8009FB68(&tmp, &world.mtx, t->tilt.h.a);
        func_8009F8A0(&world.mtx, &tmp, t->tilt.h.b);
    }
    func_8009FB68(&tmp, &world.mtx, t->shakeX * 182.04444444);
    func_8009F8A0(&world.mtx, &tmp, t->shakeY * 182.04444444);
    func_8009FA04(&tmp, &world.mtx, t->ang);
    if (t->scale != 1.0f) {
        func_8009F824(&world.mtx, t->scale, t->scale, t->scale);
    }
    if (t->flags & 8) {
        f32 k;
        f32 h;
        f32 w;

        if (dt < 21) {
            k = dt / 20.0f;
        } else {
            k = 1.0f - ((f32)dt - (f32)(t->f4C4 + 80)) / 20.0f;
        }
        h = (f32)(D_80122E28[t->kind].length * 2) * t->scale;
        w = (f32)D_80122E28[t->kind].height * t->scale;
        squash(&world.mtx, m, k, h, w);
    }
    if (t->tiltAng != 0) {
        Vec3 a = { 0.0f, 0.0f, 0.0f };
        Vec3 b = { 0.0f, 0.0f, 0.0f };
        u16 ang;

        ang = t->tiltAng;
        a.z = -24.5f;
        b.z = t->f274;
        func_8009EEE0(&m[0]);
        func_8009FCCC(&m[0], &a, &b, ang, 0, 0);
        func_8009F4B4(&m[0], &world.mtx, &m[1]);
        world.mtx = m[1];
    }
    /* Retail definition invariant: in both health-selected part lists, types
     * 1/11/12/18 occur only for definitions with flags & 1. Those renderers
     * read turret below; do not treat this local as initialized otherwise. */
    if (D_80122E28[t->kind].flags & 1) {
        func_8009EEE0(&tmp);
        func_8009EFD4(&tmp, D_80122E28[t->kind].turretX, D_80122E28[t->kind].turretY,
                      D_80122E28[t->kind].turretZ, t->turretAng);
        func_8009F4B4(&tmp, &world.mtx, &turret.mtx);
        turret.flag = 0;
        top = &turret;
    } else {
        top = &world;
    }
    vis2 = func_800AA058(t->state, pos);
    if (t->f240 != 0 && D_80122E28[t->kind].trailId != 0 && !noFx) {
        if (t->f49C != D_8021945C) {
            t->trail[t->trailHead] = world.mtx;
            t->trailHead = (t->trailHead + 1) % 8;
            t->trailCount++;
            if (t->trailCount > 8) {
                t->trailCount = 8;
            }
        }
        if (t->trailCount >= 2) {
            u8 c1[4] = { 0xFF, 0xFD, 0x4C, 0xFF };
            u8 c2[4] = { 0x4D, 0xA5, 0xFF, 0xFF };

            func_800F4698(D_80122E28[t->kind].trailId, t->trailCount, t->trail, c1, c2,
                          (t->trailHead - (s16)(t->trailCount - 8)) % 8, 8, t->state);
        }
    }
    if (t->f260 != -1 && !noFx) {
        if (t->f264 != 0) {
            if (D_8021945C - t->f260 < 40) {
                f32 k = ((f32)D_8021945C - (f32)t->f260) / 40.0f;
                f32 a;

                if (k < 0.5f) {
                    fx.amp = k * 20.0f;
                } else {
                    fx.amp = (1.0f - k) * 20.0f;
                }
                ripple = &fx;
                a = (k - 0.5f) * 2.0f + 0.5f;
                fx.kind = 0x1556;
                fx.time = (f32)D_8021945C * 8.0f;
                fx.radius = 140.0f;
                if (a < 0.0f) {
                    alpha = 0xFF;
                } else if (a < 1.0f) {
                    gSetWords(&cmds[n++], 0xE200001C, 0xC8104A50);
                    xlu = 1;
                    alpha = ~(s32)(a * 256.0f);
                } else {
                    gSetWords(&cmds[n++], 0xE200001C, 0xC8104A50);
                    alpha = 0;
                    xlu = 1;
                }
            } else {
                gSetWords(&cmds[n++], 0xE200001C, 0xC8104A50);
                alpha = 0;
                xlu = 1;
                t->f264 = 0;
                if (!(t->flags & 0x1000)) {
                    t->flags |= 0x80;
                }
            }
        } else {
            f32 k = ((f32)D_8021945C - (f32)t->f260) / 20.0f;

            gSetWords(&cmds[n++], 0xE200001C, 0xC8104A50);
            xlu = 1;
            if (k > 1.0f) {
                alpha = 0;
            } else {
                alpha = (1.0f - k) * 192.0f;
            }
        }
        if (alpha == 0) {
            if (!(t->flags & 2)) {
                return;
            }
            vis &= 1 << t->pad;
            if (vis == 0) {
                return;
            }
            alpha = 0x20;
        }
    }
    if (D_80117EB4 == 10) {
        u8 r, g, b;

        func_800D0858(t->f4A4, &r, &g, &b);
        gSetWords(&cmds[n++], 0xFB000000, (r << 24) | (g << 16) | (b << 8) | alpha);
    } else {
        gSetWords(&cmds[n++], 0xFB000000,
                  (owner->color[0] << 24) | (owner->color[1] << 16) | (owner->color[2] << 8) | alpha);
    }
    def = &D_80122E28[t->kind];
    if (t->maxHealth / 2 < t->health) {
        parts = def->partsA;
        nParts = def->nPartsA;
    } else {
        parts = def->partsB;
        nParts = def->nPartsB;
    }
    for (i = 0; i < nParts; i++) {
        switch (parts[i].type) {
        case 10:
            if (D_8021945C - t->f224 < def->animDur) {
                s32 v;

                v = (s32)((1.0f - (f32)(D_8021945C - t->f224) / (f32)def->animDur) * 64.0f) - 32;
                gSetWords(&cmds[n], 0xF2000000 | (((v & ~v >> 31) & 0xFFF) << 12), 0x1FC07C);
                func_800AE184(D_803A53A0[parts[i].tex], vis2, &world, xlu, 0, vis, cmds, n + 1, 0, ripple);
            } else {
                func_800AE184(D_803A53A0[parts[i].tex], vis2, &world, xlu, 0, vis, cmds, n, 0, ripple);
            }
            break;
        case 2:
            gSetWords(&cmds[n], 0xF2000000 | ((s32)t->scrollL & 0xFFF), 0x7C0FC);
            func_800AE184(D_803A53A0[parts[i].tex], vis2, &world, xlu, 0, vis, cmds, n + 1, 0, ripple);
            break;
        case 3:
            gSetWords(&cmds[n], 0xF2000000 | ((s32)t->scrollR & 0xFFF), 0x7C0FC);
            func_800AE184(D_803A53A0[parts[i].tex], vis2, &world, xlu, 0, vis, cmds, n + 1, 0, ripple);
            break;
        case 7: {
            MtxObj mb = IDENT;
            Mtx rb;

            func_8009EEE0(&rb);
            rb.m[3][0] = def->barrelX;
            rb.m[3][1] = def->barrelY;
            rb.m[3][2] = def->barrelZ;
            func_8009F090(&rb, t->f26C, 0, 0);
            func_8009F4B4(&rb, &world.mtx, &mb.mtx);
            func_800AE184(D_803A53A0[parts[i].tex], vis2, &mb, xlu, 0, vis, cmds, n, 0, ripple);
            break;
        }
        case 1:
            func_800AE184(D_803A53A0[parts[i].tex], vis2, &turret, xlu, 0, vis, cmds, n, 0, ripple);
            break;
        case 12: {
            s32 f = D_8021945C - t->f224;

            if (f < 14) {
                f /= 2;
                if (f >= 4) {
                    f = 6 - f;
                }
                f++;
            } else {
                f = 0;
            }
            func_800AE184(D_803A53A0[parts[i].tex], vis2, &turret, xlu, f, vis, cmds, n, 0, ripple);
            break;
        }
        case 11: {
            f32 f = 0.0f;

            if (D_8021945C - t->f224 < def->animDur) {
                f = 1.0f - (f32)(D_8021945C - t->f224) / (f32)def->animDur;
            }
            gSetWords(&cmds[n], 0xF2000000 | ((s32)(f * 64.0f) & 0xFFF), 0x7C0FC);
            func_800AE184(D_803A53A0[parts[i].tex], vis2, &turret, xlu, 0, vis, cmds, n + 1, 0, ripple);
            break;
        }
        case 4:
        case 5:
        case 6: {
            s32 ok = 1;

            if (parts[i].type == 4 && !(t->flags & 4)) {
                ok = 0;
            } else if (parts[i].type == 5 && (t->flags & 4)) {
                ok = 0;
            }
            if (ok && D_8021945C - t->f224 < def->animDur) {
                MtxObj mr = IDENT;
                f32 f;

                f = 1.0f - (f32)(D_8021945C - t->f224) / (f32)def->animDur;
                func_8009EEE0(&tmp);
                tmp.m[3][2] = f * def->barrelZ;
                func_8009F4B4(&tmp, &top->mtx, &mr.mtx);
                drew = 1;
                func_800AE184(D_803A53A0[parts[i].tex], vis2, &mr, xlu, 0, vis, cmds, n, 0, ripple);
                func_8009299C(t, &mr, vis);
            } else {
                func_800AE184(D_803A53A0[parts[i].tex], vis2, top, xlu, 0, vis, cmds, n, 0, ripple);
            }
            break;
        }
        case 8:
        case 9: {
            MtxObj mp = IDENT;
            Mtx rp;
            f32 x;

            func_8009EEE0(&rp);
            x = def->barrelX;
            if (parts[i].type != 9) {
                x = -x;
            }
            rp.m[3][0] = x;
            rp.m[3][1] = def->barrelY;
            rp.m[3][2] = def->barrelZ;
            func_8009F090(&rp, 0, t->f270, 0);
            func_8009F4B4(&rp, &world.mtx, &mp.mtx);
            func_800AE184(D_803A53A0[parts[i].tex], vis2, &mp, xlu, 0, vis, cmds, n, 0, ripple);
            break;
        }
        case 16: {
            f32 y = t->speed / t->maxSpeed * 35.0f;
            MtxObj ms;

            func_8009EEE0(&ms.mtx);
            func_8009EFD4(&ms.mtx, pos->x, y, pos->y, t->ang);
            ms.flag = 0;
            func_800AE4D0(D_803A53A0[parts[i].tex], 0, &ms, 0, xlu, 0, vis);
            break;
        }
        case 13: {
            if (t->f27C == 1 && (t->tiltAng & 0x7FFF) > 0x4000) {
                Gfx gc[2];

                gSetWords(&gc[0], 0xFA000000, 0xF00000FF);
                gSetWords(&gc[1], 0xFB000000, 0xF0F00000);
                func_800AE184(D_803A53A0[parts[i].tex], 0, &world, 1, 0, vis, gc, 2, 0, ripple);
            }
            break;
        }
        case 14: {
            if (t->f27C == 2 && (t->tiltAng & 0x7FFF) < 0x4000) {
                Gfx gc[2];

                gSetWords(&gc[0], 0xFA000000, 0xF00000FF);
                gSetWords(&gc[1], 0xFB000000, 0xF0F00000);
                func_800AE184(D_803A53A0[parts[i].tex], 0, &world, 1, 0, vis, gc, 2, 0, ripple);
            }
            break;
        }
        case 15: {
            if (t->f240 != 0) {
                Gfx gc[2];

                gSetWords(&gc[0], 0xFA000000, ((func_8009D914() & 0x3F) ^ 0xFF) | 0x4DA5FF00);
                gSetWords(&gc[1], 0xFB000000, 0xFFFFFF00);
                func_800AE184(D_803A53A0[parts[i].tex], vis2, &world, 1, 0, vis, gc, 2, 0, ripple);
            }
            break;
        }
        case 17:
            if (D_80117EB4 == 10) {
                func_800F8264(D_803A53A0[parts[i].tex], &world, func_800D0960(t->f4A4), vis);
            } else {
                func_800F8264(D_803A53A0[parts[i].tex], &world, owner->f70, vis);
            }
            break;
        case 18:
            if (D_80117EB4 == 10) {
                func_800F8264(D_803A53A0[parts[i].tex], &turret, func_800D0960(t->f4A4), vis);
            } else {
                func_800F8264(D_803A53A0[parts[i].tex], &turret, owner->f70, vis);
            }
            break;
        default:
            func_800AE184(D_803A53A0[parts[i].tex], vis2, &world, xlu, 0, vis, cmds, n, 0, ripple);
            break;
        }
    }
    {
        Gfx prim;

        prim.w0 = 0xFA000000;
        prim.w1 = (alpha * 160 / 256) & 0xFF;
        if (D_8021945C - t->f4C8 >= 13) {
            if ((t->f8C & 0xF) == 0xF) {
                if (t->flags & 0x8000) {
                    t->flags &= ~0x8000;
                    t->f4C8 = D_8021945C;
                }
            } else if (!(t->flags & 0x8000)) {
                t->flags |= 0x8000;
                t->f4C8 = D_8021945C;
            }
        }
        if ((t->flags & 0x8000) || t->kind == 3) {
            MtxObj sh = IDENT;

            func_8009EF4C(&sh.mtx, pos->x, pos->y, t->ang);
            func_8009F824(&sh.mtx, t->scale * t->f278, t->scale, t->scale);
            func_800AD9A8(D_803A53A0[D_80122E28[t->kind].shadowTex], 0, &sh, 5, 0, vis, &prim, 1);
        } else {
            func_800AD9A8(D_803A53A0[D_80122E28[t->kind].shadowTex], 0, &world, 5, 0, vis, &prim, 1);
        }
    }
    if (!drew) {
        if (D_80122E28[t->kind].flags & 1) {
            func_8009299C(t, &turret, vis);
        } else {
            func_8009299C(t, &world, vis);
        }
    }
    for (i = 0; i < t->nAttach; i++) {
        if (func_800E4ECC(t->attach[i], t->id)) {
            Mtx l;
            MtxObj o;

            l = D_8007192C;
            func_8009EFD4(&l, t->attach[i]->x, t->attach[i]->y, t->attach[i]->z, t->attach[i]->ang);
            func_8009F4B4(&l, &world.mtx, &o.mtx);
            o.flag = 0;
            func_800AE4D0(D_803A53A0[D_80123BC8[t->attach[i]->kind].tex], vis2, &o, 0, 0, 0, vis);
        }
    }
    }
}
