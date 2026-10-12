/* SPAN 0x8008B6D0 */
/* RODATA_VRAM 0x800718F0 */
#include "types.h"
typedef struct { f32 x, y, z; } Vec3;
struct Player;
typedef struct Obj {
    void * node;
    struct Obj * next;
    Vec3 pos;
    Vec3 prev;
    u16 angle;
    u8 pad022[0x2];
    s16 h24;
    s16 h26;
    u8 shape[0xC];
    f32 speed;
    u8 pad038[0x5C];
    u8 color;
    u8 team;
    u8 b96;
    u8 b97;
    s32 type;
    s32 kind;
    s32 iA0;
    u8 pad0A4[0x12C];
    struct Player * owner;
    s32 hp;
    s32 hpMax;
    u8 pad1DC[0x4];
    u32 flags;
    f32 f1E4;
    f32 f1E8;
    f32 f1EC;
    f32 f1F0;
    u16 collision;
    s16 ammo[0x12];
    u8 pad21A[0x2];
    s32 weapon;
    s32 weapon2;
    s32 t224;
    s32 t228;
    u8 pad22C[0x4];
    s32 t230;
    s32 t234;
    u8 pad238[0x8];
    s32 i240;
    s32 t244;
    u8 pad248[0x10];
    f32 f258;
    f32 f25C;
    s32 i260;
    u8 pad264[0x4];
    s32 t268;
    s16 h26C;
    u8 pad26E[0x2];
    s16 h270;
    s16 h272;
    u8 pad274[0x4];
    f32 f278;
    s32 i27C;
    s32 i280;
    s32 i284;
    s32 i288;
    s32 t28C;
    u8 pad290[0x20C];
    s32 t49C;
    s32 i4A0;
    u8 pad4A4[0x2];
    u8 nTurrets;
    u8 pad4A7[0x1];
    s32 turret[2];
    u8 pad4B0[0x10];
    f32 scale;
    u8 pad4C4[0x4];
    s32 t4C8;
} Obj;
typedef struct Player {
    u8 pad000[0xA];
    u8 caps;
    u8 id;
    u8 pad00C[0x1A4];
    u8 b1B0[8];
    struct Obj * lists[4];
    u8 counts[8];
    f32 hpScale;
    f32 speedScale;
    u8 pad1D8[0x78];
} Player;
typedef struct Desc {
    Vec3 pos;
    u16 angle;
    u8 color;
    u8 team;
    s32 type;
    s32 kind;
    u8 pad018[0x4];
    u32 flags;
    s32 weapon0;
    s32 weapon1;
    s32 x28;
} Desc;
typedef struct TypeInfo {
    s16 s[6];
    s32 i0C;
    u8 pad010[0x4C];
    u16 hp;
    u8 pad05E[0x2];
    u8 shape[0x1C];
    u32 flags;
    u8 pad080[0x50];
} TypeInfo;
typedef struct { u8 pad[0xC]; Obj *obj; } Node;

extern Obj D_801AD128[24];
extern struct Player D_80235F00[];
extern TypeInfo D_80122E3C[];
extern u16 D_801AD120;
extern u8 D_80125AB1;
extern s32 D_8021945C;
extern s16 D_8011F218[];
extern u8 D_80219587[];
extern u8 *D_80219498;
extern s32 D_802194B0[];

Node *func_800A18D0(s32, s32);
void func_8008B82C(Obj *, s32, s32);
void func_800B5A10(void *, void *);
u16 func_800B1898(void *, s16, s16, s32, s16, s16, s16, s16, s16, s16, u16, s32, u8);
void _bzero(void *, s32);
void func_8008ECB4(Obj *, s32, s32);
void func_800C8F00(s16 *, u8, s32);
void func_800C924C(s16 *, u8, s32);
void func_800C962C(s32 *, s32 *, u8);
void func_800C95A0(u8 *, u8);
s32 func_800B5B28(void *, void *, Vec3 *);
void func_80089F40(Obj *, s32, s32, Desc *);
s32 func_800E2AEC(s32, Vec3 *, s32, s32, s32, s32, void *);
s32 func_8009D144(void);

static inline struct Player *get_unit(s32 index) {
    if (index == 127) {
        return 0;
    }
    return &D_80235F00[index];
}

Obj *func_8008AE04(Desc *d) {
    Obj *o = 0;
    struct Player *pl = get_unit(d->team);
    TypeInfo *t;
    Vec3 v;
    s32 i;
    Node *n;

    for (i = 0; i < 24; i++) {
        if (!(D_801AD128[i].flags & 1)) {
            o = &D_801AD128[i];
            break;
        }
    }
    if (o == 0) {
        if (d->kind != 0) {
            return 0;
        }
        for (i = 0; i < 24; i++) {
            if (D_801AD128[i].kind == 1 || D_801AD128[i].kind == 2) {
                goto found;
            }
        }
        goto alloc;
found:
        o = &D_801AD128[i];
        func_8008B82C(o, 0x7F, 0);
    }
alloc:
    n = func_800A18D0(4, 16);
    if (n == 0) {
        return 0;
    }
    n->obj = o;
    o->node = n;
    o->pos = d->pos;
    o->prev = o->pos;
    o->angle = d->angle;
    o->h24 = 0;
    o->h26 = 0;
    o->color = d->color;
    o->team = d->team;
    o->type = d->type;
    o->kind = d->kind;
    o->hpMax = o->hp = D_80122E3C[d->type].hp * pl->hpScale;
    D_801AD120++;
    o->flags = d->flags | 1;
    o->owner = get_unit(o->team);
    o->next = pl->lists[o->kind];
    pl->lists[o->kind] = o;
    pl->counts[o->kind]++;
    if (o->owner->caps & 0x10) {
        o->scale = 0.25f;
    } else {
        o->scale = 1.0f;
    }
    o->i280 = 0;
    o->i284 = 0;
    o->i288 = 0;
    o->f1E4 = o->f1EC = o->f1E8 = o->f1F0 = 0.0f;
    func_800B5A10(o->shape, D_80122E3C[d->type].shape);
    o->speed *= pl->speedScale;
    t = &D_80122E3C[o->type];
    o->collision = func_800B1898(o->node, o->pos.x, o->pos.y, 0,
                                 D_80122E3C[o->type].s[0] * o->scale, D_80122E3C[o->type].s[1] * o->scale,
                                 D_80122E3C[o->type].s[2] * o->scale, D_80122E3C[o->type].s[3] * o->scale,
                                 D_80122E3C[o->type].s[4] * o->scale, D_80122E3C[o->type].s[5] * o->scale,
                                 o->angle, 8, o->color);
    _bzero(o->ammo, 0x24);
    o->ammo[1] = D_80122E3C[o->type].i0C;
    o->weapon = 1;
    o->weapon2 = 0;
    o->t230 = -1000;
    o->t234 = -1000;
    o->t224 = D_8021945C;
    o->t228 = D_8021945C;
    if (D_80125AB1) {
        o->ammo[0x2] = 30;
        o->weapon2 = 3;
        o->ammo[0x9] = 30;
        o->ammo[0x4] = 30;
        o->ammo[0x3] = 30;
        o->ammo[0xD] = 30;
        o->ammo[0x6] = 100;
        o->ammo[0xC] = 1000;
        o->ammo[0xE] = 30;
        o->ammo[0xB] = 30;
        o->ammo[0xF] = 100;
        o->ammo[0x10] = 20;
        if (o->flags & 2) {
            o->flags |= 0x200;
            if (o->owner->id < 2) {
                D_8011F218[o->owner->id] = 1;
            }
        }
    }
    func_8008ECB4(o, d->weapon0, 0);
    func_8008ECB4(o, d->weapon1, 0);
    o->h26C = 0;
    o->h270 = 0;
    o->h272 = 0;
    o->i27C = 0;
    o->i240 = 0;
    o->t244 = -1000;
    o->f258 = o->f25C = 0.0f;
    o->f278 = 1.0f;
    if (o->flags & 2) {
        func_800C8F00(&o->ammo[o->weapon], o->owner->id, o->type);
        func_800C924C(&o->ammo[o->weapon2], o->owner->id, o->weapon2);
        func_800C962C(&o->hp, &o->hpMax, o->owner->id);
        func_800C95A0(o->owner->b1B0, o->owner->id);
        if (!D_80125AB1 && o->owner->id < 2) {
            D_8011F218[o->owner->id] = 0;
        }
    }
    if (o->kind == 3 || (d->flags & 0x400)) {
        o->angle = func_800B5B28(o->shape, D_80219498 + (D_80219587[o->team] * 24 + 0x1F4), &o->pos) + 0x4000;
    }
    o->iA0 = 0;
    func_80089F40(o, 4, o->kind, d);
    o->nTurrets = 0;
    if (D_80122E3C[o->type].flags & 0x80) {
        v.x = -82.8f;
        v.y = 0.0f;
        v.z = 32.4f;
        o->turret[0] = func_800E2AEC(3, &v, 0xC000, 0x4000, o->color, o->team, o->node);
        v.x = 82.8f;
        o->turret[1] = func_800E2AEC(3, &v, 0x4000, 0xC000, o->color, o->team, o->node);
        o->nTurrets = 2;
    }
    o->i260 = -1;
    o->t49C = -1000;
    o->b96 = 0;
    o->b97 = 0;
    o->i4A0 = d->x28;
    if (o->flags & 0x40) {
        D_802194B0[0]++;
    }
    if (o->kind == 0 && (o->owner->caps & 8)) {
        o->ammo[0x11] = 1;
        if (o->weapon2 == 0) {
            o->weapon2 = 0x11;
        }
    }
    if (!func_8009D144() && o->kind == 0 && D_8021945C != 0) {
        o->i260 = -100;
        o->t268 = D_8021945C + 90;
        o->flags |= 0x80;
    }
    o->t28C = -1000;
    o->t4C8 = -1000;
    return o;
}
