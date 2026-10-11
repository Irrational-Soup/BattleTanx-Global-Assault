/* func_8009C524: per-frame game/mode update. Unit 0x8009C524-0x8009D144 (0xC20).
 * Exact (clean production gate and ASN64): text + owned .rodata, close-8009c524.
 * Owns .rodata 0x80072518-0x80072558 (0x40): mode-7 state jump table (7), 300.0f, 301.0f,
 * alignment word, mode jump table (6). */
/* RODATA_VRAM 0x80072518 */
/* SPAN 0x8009D144 */
typedef signed char s8;
typedef unsigned char u8;
typedef short s16;
typedef unsigned short u16;
typedef int s32;
typedef unsigned int u32;
typedef float f32;

typedef struct {
    s8 x;               /* 0x00 */
    s8 y;               /* 0x01 */
    char p2[2];
    s32 held;           /* 0x04 */
    s32 pressed;        /* 0x08 */
} Pad;

typedef struct {
    u16 icon;           /* 0x00 */
    u16 color;          /* 0x02 */
    char p4[8];
    s32 score;          /* 0x0C */
    char p10[2];
    s16 f12;            /* 0x12 */
    char p14[2];
    s16 f16;            /* 0x16 */
} TeamInfo;

typedef struct {
    char p0[0x10];
    TeamInfo *info;     /* 0x010 */
    char p14[0x60];
    s32 status;         /* 0x074 */
    char p78[0x138];
    s32 kills;          /* 0x1B0 */
    s32 deaths;         /* 0x1B4 */
    char p1b8[0x58];
    u16 f210;           /* 0x210 */
    u16 f212;           /* 0x212 */
    char p214[0x3C];
} Unit;

typedef struct {
    void *world;        /* 0x80219498 */
    s32 track;          /* 0x8021949C */
    u32 mode;           /* 0x802194A0 */
    u8 nHuman;          /* 0x802194A4 */
    u8 nPlayers;        /* 0x802194A5 */
    u8 nUnits;          /* 0x802194A6 */
} GameState;

typedef struct {
    s32 type;
} LevelDef;

extern GameState D_80219498;
extern Unit D_80235F00[];
extern u8 D_80219460[4][4];
extern s32 D_80114860;
extern u16 D_80114864;
extern s32 D_80117EB4;
extern u8 D_80121CE0;
extern u8 D_80121CE1;
extern u8 D_80219258[][0x100];
extern u16 D_80219458;
extern s32 D_8021945C;
extern f32 D_80219470;
extern void *D_80219490;
extern s32 D_802195C4;
extern s32 D_802195C8;
extern u32 D_802195CC;
extern s32 D_802195D4;
extern s32 D_802195D8;
extern f32 D_803A5948;

void func_800979F4(s32);
void func_80097B20(s32 fade);
void func_80097D14(s32 track, s32 fade);
Pad *func_80098250(s32 n);
void func_80098B2C(void);
void func_80098B40(void);
void func_80098BF8(void);
s32 func_80098F24(void);
void func_80098FBC(void);
void func_800998E8(void);
void func_80099FE8(void);
void func_8009AE38(void);
void func_8009B0F0(void);
s32 func_8009B694(void);
void func_8009C098(void);
void func_8009C31C(void);
s32 func_8009D144(void);
void func_800A1D24(s32 mode);
void func_800A8690(s32 id);
s32 func_800A977C(Unit *u);
void func_800A9A98(Unit *u, s32 v);
void func_800A9EC0(void);
void func_800B04E0(void);
void func_800BF798(void);
void func_800BFAEC(void);
void func_800C6D68(void);
void func_800C8EDC(u16 id);
/* matched callee (race_popup_show.c) stores its second argument word unchanged; this caller passes 300.0f bits in a1 */
void func_800CAA0C(char *popup, f32 time);
void func_800CAA48(s32 a, s32 b, f32 time, u16 c);
void func_800CAB44(void);
void func_800CE610(s32, s32, u16, u16, s32, s32, s16, s16, s16);
void func_800CE77C(s32, s32, u16, u16, s32, s32);
void func_800CE814(s32, s32, s32, s32, s32, s32, s32, s32, s32, s32, s32, s32, s16);
void func_800CE9A0(s32, s32, s32, s32, u16, u16, u16, u16, s32, s32);
void func_800CEA50(u16 player, s32, s32, u16, u16, s32, s32);
void func_800D4DE0(void);
u16 func_800D5508(void);
void func_800D56FC(void);
s32 func_800E8C88(s32);
s32 func_800E8E34(s32);
s32 func_800E8F90(s32);
char *func_800E9030(s32);
s32 func_800E918C(s32);
LevelDef *func_800E9424(void);
s32 func_800E98F8(void);
void func_800F6578(void);

static inline Unit *get_unit(s32 index) {
    if (index == 127) {
        return 0;
    }
    return &D_80235F00[index];
}

/* Body of func_80099854 (clear the fade alphas, flip the display-list buffer). */
static inline void flip_frame(void) {
    s32 i;

    for (i = 3; i >= 0; i--) {
        D_80219460[i][3] = 0;
    }
    D_80114860 = (D_80114860 + 1) & 1;
    D_80219490 = D_80219258[D_80114860];
}

static inline s32 any_unit_done(void) {
    s32 i;

    for (i = 0; i < D_80219498.nHuman; i++) {
        if (get_unit(i)->status == 1) {
            return 1;
        }
    }
    return 0;
}

void func_8009C524(void) {
    s32 i;

    if (D_802195D4 == 0) {
        func_8009AE38();
    }
    if (D_802195C4 == 0) {
        switch (D_802195CC) {
        case 3:
            func_800C6D68();
            break;
        case 7:
            if (D_80117EB4 == 1) {
                D_80114864 = 1;
            } else {
                D_80114864 = 3;
            }
            break;
        }
    }
    func_80098B40();
    func_800A9EC0();
    func_800B04E0();
    flip_frame();
    switch (D_802195CC) {
    case 5:
        func_800A1D24(1);
        for (i = 0; i < D_80219498.nUnits; i++) {
            func_800A8690(i);
            func_800C8EDC(i);
        }
    case 6:
        break;
    case 7:
        func_800A1D24(1);
        switch (D_80114864) {
        case 1: {
            char *popup = func_800E9030(D_80219498.track);

            if (popup != 0) {
                func_800CAA0C(popup, 300.0f);
                D_80114864 = 2;
                D_80219470 = 301.0f;
            } else {
                D_80114864 = 3;
            }
            break;
        }
        case 3:
            if (func_80098F24() != 0) {
                D_80114864 = 5;
            } else {
                func_800CAB44();
                D_80114864 = 4;
            }
            break;
        case 5: {
            s32 a = func_800E8C88(D_80219498.track);
            s32 b;

            if (func_8009D144() != 0) {
                b = func_800E8E34(D_80219498.track);
            } else {
                b = func_800E8F90(D_80117EB4);
            }
            if (a != 0 || b != 0) {
                func_800CAA48(a, b, 145.0f, 0);
                D_80114864 = 6;
                D_80219470 = 146.0f;
            } else {
                D_80114864 = 7;
            }
            break;
        }
        case 7:
            D_802195C8 = 3;
            D_80114864 = 0;
            break;
        case 4:
            if (func_80098250(0)->pressed & 0x9000) {
                func_80098FBC();
                D_80114864++;
                func_800BF798();
                func_800979F4(0x2D);
            }
            break;
        case 2:
        case 6:
            D_80219470 -= D_803A5948;
            if (D_80219470 < 0.0f) {
                D_80114864++;
                func_800BF798();
            } else if (func_80098250(0)->pressed & 0x9000) {
                D_80114864++;
                func_800BF798();
                func_800979F4(0x2D);
            }
            break;
        }
        break;
    default:
        if (D_80117EB4 == 10) {
            u16 r = func_800D5508();

            if (r != 0) {
                func_80097B20(10);
                switch (D_80121CE0) {
                case 0:
                    if (r == 3) {
                        do {
                            func_8009C31C();
                        } while (func_800E9424()->type != 0);
                    } else {
                        func_8009C31C();
                    }
                    break;
                case 1:
                    D_802195D8 = 0;
                    D_802195C8 = 0;
                    break;
                case 2:
                default:
                    if (D_80121CE1 != 0 && r == 1) {
                        D_80117EB4 = 10;
                        func_800D4DE0();
                    } else {
                        D_802195D8 = 0;
                        D_802195C8 = 2;
                    }
                    break;
                }
                D_80219460[0][0] = 0;
                D_80219460[0][1] = 0;
                D_80219460[0][2] = 0;
                D_80219460[0][3] = 0xFF;
                func_800998E8();
                return;
            }
        }
        func_800A1D24(0);
        for (i = 0; i < D_80219498.nUnits; i++) {
            func_800A8690(i);
        }
        break;
    }
    switch (D_802195CC) {
    case 5:
    case 7:
    case 8:
        break;
    case 3: {
        s32 res = func_8009B694();

        switch (res) {
        case 1: {
            u16 j;

            func_80097B20(10);
            D_802195C8 = 6;
            func_800F6578();
            if (func_8009D144() != 0) {
                func_80097D14((D_80235F00[0].status == res) ? 0x16 : 9, 0);
            }
            for (j = 0; j < D_80219498.nUnits; j++) {
            }
            break;
        }
        case 2:
            D_802195C8 = 4;
            break;
        case 0:
            break;
        }
        break;
    }
    case 4:
        if (D_802195C4 >= 60) {
            u16 j;

            D_802195C8 = 6;
            func_80097B20(10);
            func_8009C098();
            if (func_8009D144() != 0) {
                func_80097D14((D_80235F00[0].status == 1) ? 0x16 : 9, 0);
            }
            for (j = 0; j < D_80219498.nUnits; j++) {
            }
        }
        break;
    case 6:
        if (D_802195C4 >= 60) {
            if (func_8009D144() != 0) {
                if (any_unit_done()) {
                    if (D_80219458 == 0) {
                        flip_frame();
                        if (D_80219498.nHuman == 1) {
                            func_800A9A98(&D_80235F00[0], func_800E98F8());
                            func_800CE610(D_80235F00[0].deaths, D_80235F00[0].kills,
                                          D_80235F00[0].info->icon, D_80235F00[0].info->color,
                                          func_800E918C(D_80219498.track), D_8021945C,
                                          D_80235F00[0].info->f12, D_80235F00[0].info->f16,
                                          D_80235F00[0].info->score + func_800A977C(&D_80235F00[0]));
                        } else {
                            func_800A9A98(&D_80235F00[0], func_800E98F8());
                            func_800A9A98(&D_80235F00[1], func_800E98F8());
                            func_800CE814(D_80235F00[0].deaths, D_80235F00[0].kills,
                                          D_80235F00[1].deaths, D_80235F00[1].kills,
                                          D_80235F00[0].f210, D_80235F00[1].f210,
                                          D_80235F00[0].f212, D_80235F00[1].f212,
                                          func_800E918C(D_80219498.track), D_8021945C,
                                          D_80235F00[0].info->f12, D_80235F00[0].info->f16,
                                          D_80235F00[0].info->score + func_800A977C(&D_80235F00[0])
                                              + func_800A977C(&D_80235F00[1]));
                        }
                        D_80219458 = 1;
                    }
                } else if (D_80219458 == 0) {
                    flip_frame();
                    if (D_80219498.nHuman == 1) {
                        func_800CE77C(D_80235F00[0].deaths, D_80235F00[0].kills,
                                      D_80235F00[0].info->icon, D_80235F00[0].info->color,
                                      func_800E918C(D_80219498.track), D_8021945C);
                    } else {
                        func_800CE9A0(D_80235F00[0].deaths, D_80235F00[0].kills,
                                      D_80235F00[1].deaths, D_80235F00[1].kills,
                                      D_80235F00[0].f210, D_80235F00[1].f210,
                                      D_80235F00[1].f212, D_80235F00[1].f212,
                                      func_800E918C(D_80219498.track), D_8021945C);
                    }
                    D_80219458 = 1;
                }
            } else if (D_80219458 == 0) {
                flip_frame();
                func_800BF798();
                for (i = 0; i < D_80219498.nHuman; i++) {
                    Unit *u = get_unit(i);

                    func_800CEA50(i, u->deaths, u->kills, u->info->icon, u->info->color,
                                  func_800E918C(D_80219498.track), D_8021945C);
                }
                D_80219458 = 1;
            }
        } else {
            func_80098BF8();
            D_80219458 = 0;
            for (i = 0; i < D_80219498.nPlayers; i++) {
                D_80219460[i][0] = 0;
                D_80219460[i][1] = 0;
                D_80219460[i][2] = 0;
                D_80219460[i][3] = 0x80;
            }
        }
        break;
    }
    func_80098B2C();
    func_8009B0F0();
    if (D_80117EB4 == 10) {
        func_800D56FC();
    } else {
        func_800BFAEC();
    }
    func_800998E8();
    func_80099FE8();
}
