/* SPAN 0x800AA598 */
/* RODATA_VRAM 0x80072D80 */
typedef unsigned char u8;
typedef signed char s8;
typedef unsigned int u32;

typedef struct { u32 w0, w1; } Gfx;
typedef struct { s8 v[3]; } Byte3;
typedef struct { u8 v[3]; } Col3;

typedef struct {
    Col3 col;
    char pad1;
    Col3 colc;
    char pad2;
    Byte3 dir;
    char pad3;
    char pad4[4];
} Light;

#define _SHIFTL(v, s, w) ((u32)(((u32)(v) & ((1 << (w)) - 1)) << (s)))
#define gSPLight(pkt, l, n) \
    { Gfx *_g = (Gfx *)(pkt); \
      _g->w0 = _SHIFTL(0xDC, 24, 8) | _SHIFTL((sizeof(Light) - 1) >> 3, 19, 5) | \
               _SHIFTL(((n) * 24 + 24) / 8, 8, 8) | _SHIFTL(0x0A, 0, 8); \
      _g->w1 = (u32)(l); }
#define gSPNumLights(pkt, n) \
    { Gfx *_g = (Gfx *)(pkt); \
      _g->w0 = _SHIFTL(0xDB, 24, 8) | _SHIFTL(0x02, 16, 8) | _SHIFTL(0, 0, 16); \
      _g->w1 = (u32)((n) * 24); }
#define gSPEndDisplayList(pkt) \
    { Gfx *_g = (Gfx *)(pkt); _g->w0 = _SHIFTL(0xDF, 24, 8); _g->w1 = 0; }

typedef struct {
    Byte3 col;
    Byte3 dir;
} LightSrc;

typedef struct {
    Byte3 col;
    char pad1;
    Byte3 colc;
    char pad2;
} Ambient;

typedef struct {
    float pos[3];
    u8 col[3];
    u8 falloff;
} PointLight;

typedef struct {
    Byte3 col;
    u8 nPoints;
    PointLight pts[16];
    Gfx *dl;
    Ambient *amb;
} AreaLight;

typedef struct {
    u8 n;
    LightSrc lights[2];
    AreaLight areas[1];
} LightSet;

extern LightSet D_80236B20;

void *func_8007B190(int n);

#define ABS(x) ((0.0f < (x)) ? (x) : -(x))

Gfx *func_800AA058(u8 area, float *pos) {
    LightSet *ls;
    int limit = 7 - D_80236B20.n;
    AreaLight *a = &D_80236B20.areas[area];
    Col3 col[7];
    Byte3 dir[7];
    int n = 0;
    int i;
    Light *l;
    Gfx *dl;
    int cnt;

    for (i = 0; i < a->nPoints && n < limit; i++) {
        float dx = a->pts[i].pos[0] - pos[0];
        float dz = a->pts[i].pos[2] - pos[2];
        float dy = a->pts[i].pos[1] - pos[1];
        float s;
        float d = dx * dx + dz * dz + dy * dy - 1.0f;
        if (d < 0.0f) {
            d = 0.0f;
        }
        d *= a->pts[i].falloff * 0.000003814697265625f;
        d += 1.0f;
        d = 1.0f / d;
        if (d > 0.03125) {
            col[n].v[0] = a->pts[i].col[0] * d;
            col[n].v[1] = a->pts[i].col[1] * d;
            col[n].v[2] = a->pts[i].col[2] * d;
            s = 126.0f / (((ABS(dx) > ABS(dz)) ? ((ABS(dx) > ABS(dy)) ? ABS(dx) : ABS(dy))
                                              : ((ABS(dz) > ABS(dy)) ? ABS(dz) : ABS(dy))) + 1.0f);
            dir[n].v[0] = dx * s;
            dir[n].v[1] = dz * s;
            dir[n].v[2] = dy * s;
            n++;
        }
    }
    if (n == 0) {
        return a->dl;
    }
    cnt = n + 3;
    ls = &D_80236B20;
    l = func_8007B190(n * 2);
    if (l == 0) {
        return a->dl;
    }
    dl = func_8007B190(cnt);
    if (dl == 0) {
        return a->dl;
    }
    gSPNumLights(&dl[0], ls->n + n);
    for (i = 0; i < n; i++) {
        gSPLight(&dl[i + 1], &l[i], i + D_80236B20.n + 1);
        l[i].col = col[i];
        l[i].colc = col[i];
        l[i].dir = dir[i];
    }
    gSPLight(&dl[n + 1], a->amb, D_80236B20.n + n + 1);
    gSPEndDisplayList(&dl[n + 2]);
    return dl;
}
