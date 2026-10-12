typedef unsigned char u8;
typedef signed char s8;
typedef unsigned short u16;
typedef unsigned int u32;
typedef int s32;
typedef float f32;

typedef struct PlayerColor {
    short x;
    short y;
    short z;
    char pad6[2];
    s32 f8;
    s32 fC;
    char pad10[8];
    u8 id;
    u8 color[3];
} PlayerColor;

typedef struct ModelInfo {
    char pad0[0x18];
    s32 field18;
    s32 field1C;
    s32 field20;
} ModelInfo;

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
    s8 field30;
    u8 pad31[3];
    u32 mode;
    s32 info20;
    s32 info18;
    s32 info1C;
} PlayerSetup;

typedef struct GameState {
    void *world;
    s32 track;
    u32 mode;
    u8 nHuman;
    u8 nPlayers;
    u8 nTanks;
    u8 nSlots;
    u8 teams[5];
    char pad15[0xEF - 0x15];
    u8 order[5];
    char padF4[0x108 - 0xF4];
    s32 slotVal[5];
} GameState;

extern GameState D_80219498;
extern char D_80235F00[];
extern PlayerColor D_80236A90[];
extern u8 D_80116580[][3];
extern f32 D_80116624[][6];
extern f32 D_8011663C[6];
extern s32 D_80117EB4;

void _bzero(void *, s32);
s32 func_8009ACDC(s32);
void func_800A77A8(void *, PlayerSetup *);
void func_800C1AF8(s32);
ModelInfo *func_800D69E0(s32);

void func_800A7D70(void) {
    s32 slot;
    s32 humanFlag;

    _bzero(D_80235F00, 0xB90);
    _bzero(D_80236A90, 0x8C);
    for (slot = 0; slot < 4; slot++) {
        u8 r = D_80116580[slot][0];
        u8 g = D_80116580[slot][1];
        u8 b = D_80116580[slot][2];
        PlayerColor *color = &D_80236A90[slot];

        color->id = slot;
        color->x = 0;
        color->y = 0;
        color->z = 0;
        color->f8 = 0;
        color->fC = 0;
        color->color[0] = r;
        color->color[1] = g;
        color->color[2] = b;
    }


    for (slot = 0; slot < D_80219498.nTanks; slot++) {
        PlayerSetup setup;
        ModelInfo *info;
        s32 j;
        s32 info18;
        s32 info1C;
        u32 resultMode;
        s32 worldOffset;
        u8 team;

        humanFlag = 2;
        setup.flags = 0;

        if (slot < D_80219498.nHuman) {

            setup.flags = humanFlag;
        }
        worldOffset = D_80219498.order[slot] * 60 + 200;
        setup.worldValue = (s32)D_80219498.world + worldOffset;
        if (slot < D_80219498.nPlayers) {
            setup.flags |= 1;
        }
        setup.slot = slot;
        team = D_80219498.teams[slot];
        setup.field8 = 0;
        setup.fieldC = 0;
        setup.color = &D_80236A90[team];
        setup.model = D_80219498.slotVal[slot];
        info = func_800D69E0(setup.model);
        setup.info18 = info->field18;
        setup.info1C = info->field1C;

        j = 0;
        if (setup.flags & 2) {
            do {
                setup.values[j] = D_80116624[func_8009ACDC(slot)][j];
                j++;
            } while (j < 6);
        } else {
            do {
                setup.values[j] = D_8011663C[j];
                j++;
            } while (j < 6);
        }

        setup.info20 = func_800D69E0(setup.model)->field20;
        setup.field30 = 0;
        if (setup.flags & 2) {
            if (D_80117EB4 == 10) {
                goto human_mode_ten;
            }
            if (D_80219498.mode != 3) {
                if (D_80219498.mode < 4) {
                    if (D_80219498.mode != 1) {
                        setup.mode = 0;
                    } else {
                        setup.mode = humanFlag;
                    }
                } else if (D_80219498.mode == 5) {
                    setup.mode = D_80219498.mode;
                } else {
                    setup.mode = 0;
                }
            } else {
                setup.mode = humanFlag;
            }
            goto mode_done;
        } else {
            u32 gameMode = D_80219498.mode;

            switch (gameMode) {
            case 1:
            case 3:
                resultMode = 1;
                break;
            case 5:
                resultMode = 6;
                break;
            default:
                resultMode = 8;
                break;
            }
            goto assign_result_mode;
        }
human_mode_ten:
        resultMode = 8;
assign_result_mode:
        setup.mode = resultMode;
mode_done:

        func_800A77A8(&D_80235F00[(s32)slot * 0x250], &setup);
        func_800C1AF8((u16)slot);
    }
}
