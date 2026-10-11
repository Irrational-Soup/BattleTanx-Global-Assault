/* SPAN 0x8008B788 */
#include "types.h"
typedef struct { f32 x, y, z; } Vec3;
typedef struct Node { u8 pad[0xC]; struct Obj *obj; } Node;
typedef struct { u16 h0; u16 deaths; } Team;
typedef struct { u8 pad[4]; s32 kind; u8 pad08[0x23]; u8 count; } Script;
struct Player;
typedef struct Obj {
    Node * node;
    struct Obj * next;
    Vec3 pos;
    Vec3 prev;
    u16 angle;
    u8 pad022[0x72];
    u8 color;
    u8 team;
    u8 pad096[0x2];
    s32 type;
    s32 kind;
    u8 pad0A0[0x130];
    struct Player * owner;
    u8 pad1D4[0xC];
    u32 flags;
    u8 pad1E4[0x10];
    u16 collision;
    u8 pad1F6[0x2AA];
    Script * script;
    u8 pad4A4[0x2];
    u8 nTurrets;
    u8 pad4A7[0x1];
    s32 turret[2];
    u8 pad4B0[0x1C];
} Obj;
typedef struct Player {
    u8 pad000[0xA];
    u8 caps;
    u8 id;
    u8 pad00C[0x4];
    Team * team;
    u8 pad014[0x1A4];
    struct Obj * lists[4];
    u8 counts[8];
    u8 pad1D0[0x14];
    u8 c1E4;
    u8 c1E5;
    u8 c1E6;
    u8 pad1E7[0x2B];
    u16 losses;
    u8 pad214[0x3C];
} Player;
typedef struct TypeInfo {
    u8 pad000[0x44];
    s32 effect;
    u8 pad048[0x4];
    s32 sfx;
    u8 pad050[0x68];
    s32 score;
    u8 pad0BC[0x14];
} TypeInfo;

extern Player D_80235F00[];
extern TypeInfo D_80122E3C[];
extern u16 D_801AD120;
extern s16 D_8011F218[];
extern s32 D_802194B0[];
extern s32 D_80117EB4;
extern s32 D_803A53A0[];
extern s32 D_803A5660[];
extern u8 D_80115BC8[];

void func_800A89B0(s32, s32);
void func_800A9A98(Player *, s32);
void func_800E4F00(s32, Node *);
void func_800E75F4(Obj *);
void func_80097FB4(s32, f32, f32, f32, u8);
void func_800A5BD8(Vec3 *, u16, u8, f32, void *, s32);
void func_800F6650(Vec3 *, u16, u8, s32, s32, s32);
void *func_800D7DE0(s32, Vec3 *, u8, u16, Player *, u16, u8);
void func_800B22F8(u16);
void func_800DA7D0(s32, Vec3 *, u16, u8, s32, s32, u8, u8, u8);
void func_800CA1A8(u8);
void func_800A929C(Player *, Obj *);
void func_800D8C60(Vec3 *, u8, s32, s32, Team *, s32);
void func_80095BE4(Obj *);
void func_80089F40(Obj *, s32, s32, s32);

static inline Player *get_unit(s32 index) {
    if (index == 127) {
        return 0;
    }
    return &D_80235F00[index];
}

static inline void obj_release(Obj *o) {
    s32 kind = o->kind;
    Obj **link = &o->owner->lists[kind];

    while (*link != 0 && *link != o) {
        link = &(*link)->next;
    }
    *link = o->next;
    o->owner->counts[kind]--;
    o->flags &= ~1;
    o->node->obj = 0;
    D_801AD120--;
    o->kind = 4;
    func_80089F40(o, kind, 4, 0);
}

void func_8008B6D0(Obj *o) {
    obj_release(o);
}
