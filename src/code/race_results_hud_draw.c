/* Race-results HUD callback. */
typedef unsigned char u8;
typedef signed char s8;
typedef unsigned short u16;
typedef short s16;
typedef int s32;
typedef unsigned int u32;
typedef float f32;
typedef struct { u32 w0, w1; } Gfx;
#define _SHIFTL(v, s, w) (((u32)(v) & ((0x01 << (w)) - 1)) << (s))
#define gDPSetPrimColor(pkt, m, l, r, g, b, a) \
    { Gfx *_g = (Gfx *)(pkt); \
      _g->w0 = (_SHIFTL(0xFA, 24, 8) | _SHIFTL(m, 8, 8) | _SHIFTL(l, 0, 8)); \
      _g->w1 = (_SHIFTL(r, 24, 8) | _SHIFTL(g, 16, 8) | _SHIFTL(b, 8, 8) | _SHIFTL(a, 0, 8)); }

typedef struct { u8 pad[0x16]; u16 x; u16 y; } Hud;
typedef struct { u16 pad; u16 x; u16 y; } Pos;
typedef struct Part { u8 pad[0x20]; struct Part *next; u8 pad24[0x12]; u8 slot; } Part;
typedef struct { u8 pad[0xA0]; Part *parts; } Obj;
typedef struct { u8 pad[0xA]; u8 active; u8 padB[1]; Part *parts; u8 pad10[0xD]; u8 owner; u8 pad1E[4]; u16 value; } Thing;
typedef struct { u8 pad[0x1B8]; Obj *lists[4]; u8 pad1C8[0x88]; } Player;
typedef struct { u16 pad; u16 x; } Tex;

extern s8 D_80117EB0;
extern u8 D_8011E0E4[], D_8011E2B4[], D_8011E384[], D_8011E454[];
extern Player D_80235F00[];
extern s32 D_802194A0;
extern u16 D_80117726;
extern u32 D_80117ED4[];
extern u8 D_80117724[], D_80117740[], D_8011775C[], D_80117778[], D_801177B0[];
extern Tex *D_8011DE88[];
extern u16 *D_8011DE78[];
extern char D_803A6038[][10];
extern s32 D_802194B0;

void func_8007BDFC(Gfx **, s32);
void func_8007C9B8(Gfx **, void *, s32, s32, f32, f32);
Thing *func_800A1A28(Thing *, s32);
s32 sprintf(char *, const char *, ...);
s32 func_800973E0(char *, s32, f32);
void func_80096F48(Gfx **, char *, s32, s32, s32, f32, f32);

static inline u16 race_slot(void *hud) {
    u16 ret;

    switch (D_80117EB0) {
    case 1:
        ret = 0;
        break;
    case 2:
        ret = hud != D_8011E0E4;
        break;
    case 3:
        if (hud == D_8011E384) {
            ret = 0;
        } else if (hud == D_8011E454) {
            ret = 1;
        } else {
            ret = 2;
        }
        break;
    case 4:
        if (hud == D_8011E2B4) {
            ret = 0;
        } else if (hud == D_8011E384) {
            ret = 1;
        } else if (hud == D_8011E454) {
            ret = 2;
        } else {
            ret = 3;
        }
        break;
    default:
        ret = 0;
        break;
    }
    return ret;
}

static inline Player *get_unit(s32 index) {
    if (index == 127) {
        return 0;
    }
    return &D_80235F00[index];
}

void func_800C9A3C(Gfx **gp, Hud *hud, Pos *pos) {
    s16 x = pos->x + hud->x;
    u16 idx = race_slot(hud);
    Player *pl = get_unit(idx);
    Part *part;
    Thing *t;
    void *p;
    u16 i;
    s16 step;
    u16 mask;
    s32 bits;
    u16 count;
    s32 value;
    s32 shade;
    u16 sh;

    if (D_802194A0 == 1 || D_802194A0 == 11 || D_802194A0 == 3) {
        mask = 0;
        if (hud != (void *)D_8011E2B4 && hud != (void *)D_8011E454) {
            x += 6;
            step = -D_80117726;
        } else {
            step = D_80117726;
        }
        if (pl->lists[0] != 0) {
            for (part = pl->lists[0]->parts; part != 0; part = part->next) {
                sh = part->slot < 4 ? part->slot * 2 : 0;
                mask |= 1 << sh;
            }
        }
        if (pl->lists[3] != 0) {
            for (part = pl->lists[3]->parts; part != 0; part = part->next) {
                sh = part->slot < 4 ? part->slot * 2 : 0;
                mask |= 1 << sh;
            }
        }
        for (t = func_800A1A28(0, 0x14); t != 0; t = func_800A1A28(t, 0x14)) {
            if (t->owner == idx) {
                for (part = t->parts; part != 0; part = part->next) {
                    sh = part->slot < 4 ? part->slot * 2 : 0;
                    mask |= 2 << sh;
                }
                break;
            }
        }
        func_8007BDFC(gp, 4);
        i = 0;
        bits = mask;
        for (; i < 4; i++) {
            shade = (bits >> (i * 2)) & 3;
            if (shade == 0) {
                continue;
            }
            if (shade == 1) {
                Gfx *g = *gp;

                gDPSetPrimColor(g++, 0, 0, 0, 0, 0, 255);
                *gp = g;
            } else {
                Gfx *g = *gp;

                gDPSetPrimColor(g++, 0, 0, 0, 0, 0, 128);
                *gp = g;
            }
            switch (D_80117ED4[i]) {
            case 1:
                p = D_80117724;
                break;
            case 4:
                p = D_80117740;
                break;
            case 2:
                p = D_8011775C;
                break;
            case 3:
            default:
                p = D_80117778;
                break;
            }
            func_8007C9B8(gp, p, x, (s16)(pos->y + hud->y), 1.0f, 1.0f);
            x += step;
        }
    } else if (D_802194A0 == 14) {
        count = 0;
        value = 0;
        if (pl->lists[0] != 0) {
            Part *q;

            for (q = pl->lists[0]->parts; q != 0; q = q->next) {
                count++;
            }
        }
        for (t = func_800A1A28(0, 0x13); t != 0; t = func_800A1A28(t, 0x13)) {
            if (t->active == 0) {
                value = t->value;
                break;
            }
        }
        p = D_8011DE88[idx];
        if (p == 0) {
            return;
        }
        func_8007BDFC(gp, 1);
        func_8007C9B8(gp, D_8011DE88[idx], x, (s16)(pos->y + hud->y), 1.0f, 1.0f);
        if (D_8011DE78[idx] == 0) {
            return;
        }
        func_8007BDFC(gp, 2);
        {
            Gfx *g = *gp;

            gDPSetPrimColor(g++, 0, 0, 255, 255, 255, 255);
            *gp = g;
        }
        {
            char *buf = D_803A6038[idx];

            sprintf(buf, "%d/%d/%d", count, value, D_802194B0);
            func_80096F48(gp, buf, 0, (s16)(x - func_800973E0(buf, 0, 1.0f) - 3), (s16)(pos->y + hud->y), 1.0f, 1.0f);
        }
    } else {
        p = D_8011DE88[idx];
        if (p == 0) {
            return;
        }
        func_8007BDFC(gp, 1);
        func_8007C9B8(gp, D_8011DE88[idx], x, (s16)(pos->y + hud->y), 1.0f, 1.0f);
        if (D_8011DE78[idx] == 0) {
            return;
        }
        func_8007BDFC(gp, 2);
        {
            Gfx *g = *gp;

            gDPSetPrimColor(g++, 0, 0, 255, 255, 255, 255);
            *gp = g;
        }
        if (D_8011DE88[idx] == (Tex *)D_801177B0) {
            sprintf(D_803A6038[idx], "%d", *D_8011DE78[idx]);
        } else {
            sprintf(D_803A6038[idx], "%d/%d", *D_8011DE78[idx], D_802194B0);
        }
        if (hud == (void *)D_8011E2B4 || hud == (void *)D_8011E454) {
            func_80096F48(gp, D_803A6038[idx], 0, (s16)(pos->x + ((Tex *)p)->x + (hud->x + 3)), (s16)(pos->y + hud->y), 1.0f, 1.0f);
        } else {
            char *buf = D_803A6038[idx];

            func_80096F48(gp, buf, 0, (s16)(x - func_800973E0(buf, 0, 1.0f) - 3), (s16)(pos->y + hud->y), 1.0f, 1.0f);
        }
    }
}
