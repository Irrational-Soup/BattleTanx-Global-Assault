/* SPAN 0x800A7D70 */
/* RODATA_VRAM 0x80072CE0 */
#include "types.h"
typedef struct { f32 x, y, z; } Vec3;
typedef struct Obj { void *node; } Obj;
typedef struct { f32 x, y; u16 angle; u8 color; u8 pad; } SpawnPt;
typedef struct PlayerColor {
    s16 x, y, z;
    u8 pad6[2];
    s32 f8, fC, f10, f14;
    u8 id;
    u8 color[3];
} PlayerColor;
typedef struct { s32 types[5]; u8 rgb[3]; } TankDef;
typedef struct InfoPair { s32 a, b; } InfoPair;
typedef struct PlayerSetup {
    u8 flags;
    u8 slot;
    u8 pad2[2];
    PlayerColor *color;
    s32 field8;
    s32 fieldC;
    s32 model;
    f32 values[6];
    SpawnPt *spawn;
    u8 field30;
    u8 pad31[3];
    s32 mode;
    s32 info20;
    InfoPair weapons;
} PlayerSetup;
typedef struct Player {
    s32 i0;
    s32 i4;
    s16 h8;
    u8 flags;
    u8 id;
    u8 bC;
    u8 pad00D[0x3];
    PlayerColor * color;
    u8 pad014[0x5C];
    s32 model;
    u8 pad074[0x4];
    u8 cam[0x94];
    s32 camTarget;
    u8 camOn;
    u8 pad111[0x7];
    s32 i118;
    s32 i11C;
    u8 pad120[0x90];
    s32 i1B0;
    s32 i1B4;
    Obj * lists[4];
    u8 counts[4];
    f32 values[6];
    u8 rgb[3];
    u8 pad1E7[0x1];
    SpawnPt * spawn;
    s32 i1EC;
    s32 i1F0;
    InfoPair weapons;
    u8 b1FC;
    u8 b1FD;
    u8 order[17];
    u8 b20F;
    s16 h210;
    s16 h212;
    s16 h214;
    u8 pad216[0x2];
    s32 t218;
    s32 timers[13];
} Player;
typedef struct Desc {
    Vec3 pos;
    u16 angle;
    u8 color;
    u8 team;
    s32 type;
    s32 kind;
    s32 i18;
    u32 flags;
    s32 weapon0;
    s32 weapon1;
    s32 x28;
} Desc;

extern u8 D_80125AB8[];
extern u8 D_802194A6;
extern s32 D_80117EB4;
extern u8 D_80122330[];

TankDef *func_800D69E0(s32);
void func_800A72C0(Player *);
void _bzero(void *, s32);
Obj *func_8008AE04(Desc *);
s32 func_8009D144(void);
void func_800DE930(SpawnPt *, u16, u8, u8, s32, u16, s32, s32, s32, s32, s32, s32, s32, s32);
s32 func_800D6E40(Player *);
void func_800A61A0(void *, void *, s32, s32);
void func_800A8B38(Player *);
void func_80086700(Player *);

void func_800A77A8(Player *pl, PlayerSetup *setup) {
    TankDef *def = func_800D69E0(setup->model);
    Desc d;
    s32 i;
    s32 j;
    s32 mask;
    s32 target;

    pl->i0 = 0;
    pl->i4 = 0x43;
    pl->h8 = 0;
    pl->h210 = 0;
    pl->h212 = 0;
    pl->h214 = 0;
    pl->t218 = -1000;
    for (j = 0; j <= 12; j++) {
        pl->timers[j] = -1000;
    }
    pl->flags = setup->flags;
    if (D_80125AB8[setup->slot]) {
        pl->flags |= 0x10;
    }
    pl->id = setup->slot;
    pl->color = setup->color;
    pl->i1B0 = setup->field8;
    pl->i1B4 = setup->fieldC;
    pl->spawn = setup->spawn;
    pl->color->f10 = pl->color->fC;
    pl->color->f14 = 0;
    for (j = 0; j < 17; j++) {
        pl->order[j] = j + 1;
        pl->b20F = 2;
    }
    pl->bC = 0x1F;
    pl->i1EC = 0;
    pl->i1F0 = setup->info20;
    pl->b1FD = setup->field30;
    pl->b1FC = 0;
    pl->weapons = setup->weapons;
    if (pl->flags & 1) {
        func_800A72C0(pl);
    } else {
        pl->i118 = 0;
        pl->i11C = 0;
    }
    pl->model = setup->model;
    {
        s32 j;
        for (j = 0; j < 6; j++) {
            pl->values[j] = setup->values[j];
        }
    }
    _bzero(pl->lists, 0x10);
    _bzero(pl->counts, 4);
    switch (setup->mode) {
    case 7:
        d.pos.x = pl->spawn[1].x;
        d.pos.z = 0.0f;
        d.pos.y = pl->spawn[1].y;
        d.angle = pl->spawn[1].angle;
        d.color = pl->spawn[1].color;
        d.team = pl->id;
        d.type = 2;
        d.kind = 0;
        d.i18 = 4;
        d.flags = 0x402;
        d.x28 = 0;
        d.weapon0 = pl->weapons.a;
        d.weapon1 = pl->weapons.b;
        func_8008AE04(&d);
        break;
    case 2:
        d.pos.x = pl->spawn[1].x;
        d.pos.z = 0.0f;
        d.pos.y = pl->spawn[1].y;
        d.angle = pl->spawn[1].angle;
        d.color = pl->spawn[1].color;
        d.team = pl->id;
        d.type = 2;
        d.kind = 3;
        d.i18 = 0x16;
        d.flags = 0;
        d.x28 = 0;
        d.weapon0 = pl->weapons.a;
        d.weapon1 = pl->weapons.b;
        func_8008AE04(&d);
    case 0:
    case 5:
        d.pos.x = pl->spawn[0].x;
        d.pos.z = 0.0f;
        d.pos.y = pl->spawn[0].y;
        d.angle = pl->spawn[0].angle;
        d.color = pl->spawn[0].color;
        d.team = pl->id;
        d.type = def->types[0];
        d.kind = 0;
        d.i18 = 4;
        d.flags = 2;
        d.weapon0 = pl->weapons.a;
        d.weapon1 = pl->weapons.b;
        d.x28 = 0;
        func_8008AE04(&d);
        break;
    case 1:
    case 4:
        d.pos.x = pl->spawn[1].x;
        d.pos.z = 0.0f;
        d.pos.y = pl->spawn[1].y;
        d.angle = pl->spawn[1].angle;
        d.color = pl->spawn[1].color;
        d.team = pl->id;
        d.type = 2;
        d.kind = 3;
        d.i18 = 0x16;
        d.flags = 0;
        d.weapon0 = pl->weapons.a;
        d.weapon1 = pl->weapons.b;
        d.x28 = 0;
        func_8008AE04(&d);
        break;
    }
    if ((!func_8009D144() && !(pl->flags & 2)) || setup->mode == 5 || setup->mode == 6) {
        mask = 0;
        for (i = 0; i < 5; i++) {
            mask |= 1 << def->types[i];
        }
        for (i = 0; i < 5; i++) {
            func_800DE930(&pl->spawn[i], pl->spawn[i].angle, pl->spawn[i].color, pl->id, 0xFFFF, mask, 0, 0, 6, 0, 0, 0, 0, 0);
        }
        if (setup->mode == 6) {
            switch (D_802194A6) {
            case 3:
                pl->b1FD = 4;
                break;
            case 2:
                pl->b1FD = 5;
                break;
            case 4:
                pl->b1FD = 3;
                break;
            }
        } else if (setup->mode == 5) {
            pl->b1FD = 4;
        } else {
            pl->b1FD = 1;
        }
    }
    if (pl->flags & 1) {
        if (setup->mode == 3 || setup->mode == 4) {
            target = func_800D6E40(pl);
        } else if (pl->lists[0] != 0) {
            target = (s32)pl->lists[0]->node;
        } else if (pl->lists[1] != 0) {
            target = (s32)pl->lists[1]->node;
        } else {
            if (D_80117EB4 != 10) {
                return;
            }
            target = 0;
        }
        func_800A61A0(pl->cam, D_80122330, target, 0);
        pl->camTarget = target;
        pl->camOn = 1;
        func_800A8B38(pl);
    } else {
        _bzero(pl->cam, 0x94);
    }
    if (func_8009D144()) {
        pl->rgb[0] = def->rgb[0];
        pl->rgb[1] = def->rgb[1];
        pl->rgb[2] = def->rgb[2];
    } else {
        pl->rgb[0] = pl->color->color[0];
        pl->rgb[1] = pl->color->color[1];
        pl->rgb[2] = pl->color->color[2];
    }
    func_80086700(pl);
}
