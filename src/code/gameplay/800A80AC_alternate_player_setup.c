typedef unsigned char u8;
typedef signed char s8;
typedef unsigned short u16;
typedef unsigned int u32;
typedef int s32;
typedef float f32;

typedef struct PlayerColor {
    short x, y, z;
    char pad6[2];
    s32 f8, fC;
    char pad10[8];
    u8 id;
    u8 color[3];
} PlayerColor;

typedef struct SixFloats { f32 v[6]; } SixFloats;
typedef struct InfoPair { s32 a, b; } InfoPair;

typedef struct PlayerSetup {
    u8 flags;
    s8 slot;
    u8 pad2[2];
    PlayerColor *color;
    s32 field8;
    s32 fieldC;
    s32 model;
    f32 values[6];
    s32 worldValue;
    u8 field30;
    u8 pad31[3];
    s32 mode;
    s32 info20;
    s32 info18;
    s32 info1C;
} PlayerSetup;

typedef struct LevelInfo {
    char pad0[0x12];
    u8 field12[5];
    char pad17;
    s32 model[3];
    s32 field24[3];
} LevelInfo;

typedef struct GameState {
    LevelInfo *world;
    s32 track;
    s32 mode;
    u8 nHuman;
    u8 nPlayers;
    u8 nTanks;
    u8 nSlots;
    u8 teams[5];
    char pad15[0xEF - 0x15];
    u8 order[5];
    LevelInfo *world2;
} GameState;

extern GameState D_80219498;
extern char D_80235F00[];
extern short D_80236A90, D_80236A92, D_80236A94;
extern s32 D_80236A98, D_80236A9C;
extern s8 D_80236AA8, D_80236AA9, D_80236AAA, D_80236AAB;
extern short D_80236AAC, D_80236AAE, D_80236AB0;
extern s32 D_80236AB4, D_80236AB8;
extern s8 D_80236AC4, D_80236AC5, D_80236AC6, D_80236AC7;
extern short D_80236AC8, D_80236ACA, D_80236ACC;
extern s32 D_80236AD0, D_80236AD4;
extern s8 D_80236AE0, D_80236AE1, D_80236AE2, D_80236AE3;
extern short D_80236AE4, D_80236AE6, D_80236AE8;
extern s32 D_80236AEC, D_80236AF0;
extern s8 D_80236AFC, D_80236AFD, D_80236AFE, D_80236AFF;
extern s32 D_803A8314;
extern s32 D_803A8318[];
extern u32 D_80117EBC;
extern SixFloats D_80116594;
extern SixFloats D_801165AC;
extern SixFloats D_801165C4;
extern SixFloats D_801165DC;
extern SixFloats D_801165F4;
extern SixFloats D_8011660C;

void _bzero(void *, s32);
f32 func_8009D1CC(void);
void func_800A77A8(void *, PlayerSetup *);
void func_800A97FC(void);
void func_800C1AF8(s32);

void func_800A80AC(void) {
    s32 slot;

    _bzero(D_80235F00, 0xB90);
    _bzero(&D_80236A90, 0x8C);
    D_80236AC4 = 1; D_80236AE0 = 2;
    D_80236A90 = 0; D_80236A92 = 0; D_80236A94 = 0; D_80236A98 = 0;
    D_80236AA8 = 0; D_80236AA9 = 0; D_80236AAA = 0; D_80236AAB = 0;
    D_80236AAC = 0; D_80236AAE = 0; D_80236AB0 = 0; D_80236AB4 = 0; D_80236AB8 = 0;
    D_80236AC5 = 0; D_80236AC6 = 0; D_80236AC7 = 0;
    D_80236AC8 = 0; D_80236ACA = 0; D_80236ACC = 0; D_80236AD0 = 0; D_80236AD4 = 0;
    D_80236AE1 = 0; D_80236AE2 = 0; D_80236AE3 = 0;
    D_80236AE4 = 0; D_80236AE6 = 0; D_80236AE8 = 0; D_80236AEC = 0; D_80236AF0 = 0;
    D_80236A9C = D_803A8314;
    D_80236AFC = 3; D_80236AFD = 0; D_80236AFE = 0; D_80236AFF = 0;

    for (slot = 0; slot < D_80219498.nTanks; slot++) {
        PlayerSetup setup;
        s32 j;
        s32 playerValue;
        s32 worldOffset;
        s32 *infoPair;

        setup.flags = 0;
        if (slot < D_80219498.nHuman) {
            setup.flags = 2;
            playerValue = D_803A8318[slot];
            setup.field8 = playerValue;
            setup.fieldC = playerValue;
            if (D_80219498.world2->model[17] != 0) setup.flags = 10;
        }
        worldOffset = D_80219498.order[slot] * 60 + 200;
        setup.worldValue = (s32)D_80219498.world + worldOffset;
        if (slot < D_80219498.nPlayers) setup.flags |= 1;
        setup.slot = slot;
        setup.color = &((PlayerColor *)&D_80236A90)[D_80219498.teams[slot]];
        setup.model = D_80219498.world2->model[D_80219498.order[slot]];

        if (setup.flags & 2) {
            switch (D_80117EBC) {
            case 1: *(SixFloats *)setup.values = D_801165DC; break;
            case 2: *(SixFloats *)setup.values = D_801165F4; break;
            case 3: *(SixFloats *)setup.values = D_8011660C; break;
            default: break;
            }
            for (j = 0; j < 6; j++) setup.values[j] *= func_8009D1CC();
            setup.info20 = 1;
            setup.info1C = 0;
            setup.info18 = 0;
        } else {
            switch (D_80117EBC) {
            case 1: *(SixFloats *)setup.values = D_80116594; break;
            case 2: *(SixFloats *)setup.values = D_801165AC; break;
            case 3: *(SixFloats *)setup.values = D_801165C4; break;
            default: break;
            }
            for (j = 0; j < 6; j++) setup.values[j] /= func_8009D1CC();
            setup.info20 = *(s32 *)((char *)D_80219498.world2 + 0x24 + D_80219498.order[slot] * 4);
            *(InfoPair *)&setup.info18 = *(InfoPair *)((char *)D_80219498.world2 + 0x28 + D_80219498.order[slot] * 8);
        }
        setup.field30 = D_80219498.world2->field12[D_80219498.order[slot]];
        if (setup.flags & 2) {
            if (D_80219498.track == 15) setup.mode = 7;
            else if (D_80219498.mode == 11) setup.mode = 4;
            else setup.mode = 3;
        } else {
            if (D_80219498.mode == 11) setup.mode = 1;
            else setup.mode = 8;
        }
        func_800A77A8(&D_80235F00[slot * 0x250], &setup);
        func_800C1AF8((u16)slot);
    }
    func_800A97FC();
}
