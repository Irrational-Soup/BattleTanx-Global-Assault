/* RODATA_VRAM 0x80071EE0 */
/* SPAN 0x80092748 */
typedef signed char s8;
typedef unsigned char u8;
typedef short s16;
typedef unsigned short u16;
typedef int s32;
typedef unsigned int u32;
typedef float f32;

typedef struct { f32 x, y; } Vec2;

typedef struct {
    s8 x;               /* 0x00 */
    s8 y;               /* 0x01 */
    char p2[2];
    s32 held;           /* 0x04 */
    s32 pressed;        /* 0x08 */
} Pad;

typedef struct {
    char p0[0x0B];
    u8 id;              /* 0x0B */
    char p0c[0x110 - 0x0C];
    u8 f110;            /* 0x110 */
    char p111[0x16C - 0x111];
    s32 btnFire;        /* 0x16C */
    s32 btnFire2;       /* 0x170 */
    s32 btnSelect;      /* 0x174 */
    char p178[8];
    s32 btnTurretReset; /* 0x180 */
    s32 btnTurretL;     /* 0x184 */
    s32 btnTurretR;     /* 0x188 */
    char p18c[0x19C - 0x18C];
    s32 btnFwd;         /* 0x19C */
    s32 btnBack;        /* 0x1A0 */
    char p1a4[8];
    s32 btnStrafe;      /* 0x1AC */
    char p1b0[0x1FE - 0x1B0];
    u8 nextWeapon[0x1A];/* 0x1FE */
    s32 f218;           /* 0x218 */
    char p21c[0x250 - 0x21C];
} Player;

typedef struct {
    s32 tex[2];         /* 0x00 */
    char p8[6];
    u16 turnRate;       /* 0x0E */
    char p10[0x2C - 0x10];
    s32 flags;          /* 0x2C */
    char p30[0xD0 - 0x30];
} TankDef;

typedef struct {
    char p0[0x14];
    s16 z;              /* 0x14 */
    char p16[0x24 - 0x16];
    u16 ang;            /* 0x24 */
    char p26[2];
} GridNode;

typedef struct {
    u8 primFrom[4];
    u8 envFrom[4];
    s32 duration;       /* 0x08 */
} ColorFade;

typedef struct { char p[0x38]; } Mover;

typedef struct {
    char p0[8];
    f32 x, y, z;        /* 0x08 */
    f32 px, py, pz;     /* 0x14 */
    u16 ang;            /* 0x20 */
    u16 prevAng;        /* 0x22 */
    u16 turretAng;      /* 0x24 */
    char p26[2];
    Mover mv;           /* 0x28 */
    char p60[0x90 - 0x60];
    s32 f90;            /* 0x90 */
    u8 state;           /* 0x94 */
    u8 pad;             /* 0x95 */
    u8 p96;
    s8 f97;             /* 0x97 */
    s32 kind;           /* 0x98 */
    char p9c[4];
    s32 fA0;            /* 0xA0 */
    char pa4[0x150 - 0xA4];
    f32 aimX, aimY;     /* 0x150 */
    char p158[0x1D0 - 0x158];
    Player *owner;      /* 0x1D0 */
    char p1d4[0xC];
    s32 flags;          /* 0x1E0 */
    f32 shakeX;         /* 0x1E4 */
    f32 shakeVX;        /* 0x1E8 */
    f32 shakeY;         /* 0x1EC */
    f32 shakeVY;        /* 0x1F0 */
    u16 index;          /* 0x1F4 */
    u16 ammo[0x15];     /* 0x1F6 */
    s32 weapon;         /* 0x220 */
    s32 f224;           /* 0x224 */
    char p228[4];
    s32 f22C;           /* 0x22C */
    s32 fadeStart[2];   /* 0x230 */
    ColorFade *fade[2]; /* 0x238 */
    s32 f240;           /* 0x240 */
    s32 f244;           /* 0x244 */
    char p248[8];
    f32 f250;           /* 0x250 */
    char p254[0xC];
    s32 f260;           /* 0x260 */
    char p264[4];
    s32 f268;           /* 0x268 */
    u16 f26C;           /* 0x26C */
    u16 f26E;           /* 0x26E */
    s16 f270;           /* 0x270 */
    char p272[0x290 - 0x272];
    s32 f290, f294, f298; /* 0x290 */
    char p29c[0x4B8 - 0x29C];
    u16 f4B8;           /* 0x4B8 */
    f32 f4BC;           /* 0x4BC */
} Tank;

extern s32 D_8021945C;
extern s32 D_802194A0;
extern s32 D_80117EB4;
extern s32 D_80117F14[];
extern f32 D_80219488;
extern f32 D_80114690;
extern s16 D_80114694;
extern TankDef D_80122E8C[];
extern GridNode D_803978E0[];

void _bzero(void *, s32);
void func_80087C8C(Tank *);
void func_80087F2C(Tank *);
void func_8008B82C(Tank *, s32, s32);
void func_8008BD5C(Tank *, s32, void *, u16);
void func_8008E780(Tank *, s32, s32, s32);
s32 func_8008F874(Tank *);
void func_80090040(Tank *);
void func_800902C0(Tank *);
s32 func_800909CC(Tank *, f32, u16, u16);
void func_80090C4C(Tank *);
void func_80090DCC(Tank *, s16);
void func_80095B90(Tank *, s32);
void func_80095C50(Tank *);
s32 func_80096250(Tank *);
Pad *func_80098250(u8);
s32 func_80098334(u8);
f32 func_8009D4B0(u16);
f32 func_8009D510(u16);
u16 func_8009D6DC(u16, u16);
void func_800A9A44(Player *, s32);
void func_800B129C(u16, s16, s16);
u16 func_800B6934(Mover *);
void func_800C8238(s16, s16, u16, u8, s32, s32);
void func_800C8B74(Tank *, u8, u8);
void func_800C8EDC(u8);
void func_800C924C(u16 *, u8, s32);

static inline s8 lowAmmo(Tank *t) {
    s32 enough;

    switch (t->weapon) {
    case 2:
    case 3:
    case 4:
    case 8:
    case 9:
    case 14:
        enough = t->ammo[t->weapon] < 15;
        break;
    case 6:
    case 15:
        enough = t->ammo[t->weapon] < 60;
        break;
    case 13:
    case 16:
        enough = t->ammo[t->weapon] < 6;
        break;
    case 12:
        enough = t->ammo[t->weapon] < 300;
        break;
    default:
        return 0;
    }
    if (!enough) {
        return 1;
    }
    return 0;
}

void func_80091768(Tank *t) {
    u8 state;
    u32 k;
    Pad *pad;
    f32 speed;
    u16 oldAng;
    u16 steer;
    GridNode *n;
    s16 z;
    u16 idx;
    s16 x, y;

    if (D_8021945C > t->f268 || (D_802194A0 == 1 && t->fA0 != 0)) {
        t->f260 = -1;
        t->flags &= ~0x80;
        t->flags &= ~0x1000;
    }
    if (t->f240 != 0 && t->f240 < D_8021945C) {
        t->f240 = 0;
        t->f244 = D_8021945C;
        t->f97 = 0;
    }
    if (D_80117EB4 != 0xA) {
        t->px = t->x;
        t->py = t->y;
        t->prevAng = t->ang;
    }
    state = t->state;
    for (k = 0; k < 2; k++) {
        if (t->fadeStart[k] >= 0) {
            if (D_8021945C - t->fadeStart[k] >= t->fade[k]->duration) {
                t->fade[k]++;
                if (t->fade[k]->duration == 0) {
                    t->fadeStart[k] = -1000;
                } else {
                    t->fadeStart[k] = D_8021945C;
                }
            }
        }
    }
    if (t->flags & 8) {
        if (func_8008F874(t) < 0) {
            func_8008B82C(t, 0x7F, 2);
        }
        return;
    }
    if (t->flags & 0x10) {
        func_80090040(t);
    } else if (t->flags & 0x20) {
        f32 left = t->f250 - 0.1f;

        t->f250 = left;
        if (left <= 0.0) {
            t->flags &= ~0x20;
        }
    }
    if (D_80117EB4 == 0xA) {
        func_80090C4C(t);
    } else if (t->flags & 2) {
        pad = func_80098250(t->pad);
        if (t->owner->f110 == 0) {
            _bzero(pad, 0x10);
        }
        oldAng = t->ang;
        if (t->f90 != 0) {
            steer = oldAng - 0x4000;
            if (pad->held & t->owner->btnFwd) {
                speed = 1.0f;
            } else {
                speed = 0.0f;
                if (pad->held & t->owner->btnBack) {
                    speed = -1.0f;
                }
            }
            if (D_80122E8C[t->kind].flags & 1) {
                t->turretAng -= (u32)((f32)pad->x * 1024.0f / 80.0f);
            }
        } else {
            if (D_80117F14[t->owner->id] == 2 && (D_80122E8C[t->kind].flags & 1)) {
                f32 d;
                f32 turn;
                u16 ta;
                u16 turnLim;
                u16 turnMax;
                u16 turnAmt;

                turn = (f32)pad->x / 80.0f * 1024.0f * D_80219488;
                speed = (f32)pad->y / 80.0f;
                t->turretAng -= (u32)turn;
                ta = t->turretAng;
                if (ta > 0x8000) {
                    d = (f32)ta - 65536.0f;
                } else {
                    d = (f32)ta;
                }
                if (!(pad->held & t->owner->btnStrafe)) {
                    f32 dd = d * d;

                    if (speed > 0.0f) {
                        turnLim = (u32)(dd * speed * D_80114690);
                    } else {
                        turnLim = (u32)(dd * -speed * D_80114690);
                    }
                    turnMax = (u32)((f32)D_80122E8C[t->kind].turnRate * 1.5f * D_80219488);
                    if ((u16)turnMax > (u16)turnLim) {
                        turnMax = turnLim;
                    }
                    turnAmt = turnMax;
                    if (d < 0.0f) {
                        turnAmt = -turnAmt;
                    }
                    t->ang += turnAmt;
                    t->turretAng = func_8009D6DC(t->turretAng, turnAmt);
                }
            } else {
                speed = (f32)pad->y / 80.0f;
                if (D_80122E8C[t->kind].flags & 1) {
                    if (pad->held & t->owner->btnTurretR) {
                        t->turretAng += (u32)(D_80219488 * 512.0f);
                    } else if (pad->held & t->owner->btnTurretL) {
                        t->turretAng -= (u32)(D_80219488 * 512.0f);
                    }
                }
                t->ang -= (u32)((f32)pad->x / 80.0f * (f32)D_80122E8C[t->kind].turnRate * D_80219488);
            }
            {
                s16 dir;

                if (pad->held & t->owner->btnBack) {
                    dir = -1;
                } else {
                    dir = (pad->held & t->owner->btnFwd) != 0;
                }
                func_80090DCC(t, dir);
            }
            t->ang += func_800B6934(&t->mv);
            steer = t->ang;
        }
        if (t->f240 != 0) {
            speed = 2.0f;
        }
        if (t->state != state) {
            t->px = t->x;
            t->py = t->y;
            t->pz = t->z;
        }
        func_800909CC(t, speed, steer, oldAng);
        if (!(t->flags & 1)) {
            return;
        }
        if (D_80117F14[t->owner->id] == 4) {
            s32 m = t->owner->btnFire | t->owner->btnFire2;

            if (pad->held & m) {
                if (t->weapon != 0) {
                    func_8008E780(t, 1, pad->pressed & m, 0);
                } else {
                    func_8008E780(t, 0, pad->pressed & m, 0);
                }
            }
        } else {
            if (pad->held & t->owner->btnFire) {
                func_8008E780(t, 0, pad->pressed & t->owner->btnFire, 0);
            }
            if (t->flags & 0x800) {
                func_8008E780(t, 1, 1, 0);
            } else if (pad->held & t->owner->btnFire2) {
                s32 how = 0;

                if (pad->held & t->owner->btnSelect) {
                    if (lowAmmo(t)) {
                        how = 3;
                    }
                }
                func_8008E780(t, 1, pad->pressed & t->owner->btnFire2, how);
            }
        }
        if (t->kind == 0xA) {
            if (pad->held & t->owner->btnBack) {
                func_8008E780(t, 0, pad->pressed & t->owner->btnBack, 1);
            }
            if (pad->held & t->owner->btnFwd) {
                func_8008E780(t, 0, pad->pressed & t->owner->btnFwd, 2);
            }
        }
        if (t->kind == 8) {
            if (pad->held & t->owner->btnBack) {
                func_8008E780(t, 0, pad->pressed & 2, 1);
            }
            if (pad->held & t->owner->btnFwd) {
                func_8008E780(t, 0, pad->pressed & 1, 2);
            }
        }
        if ((pad->pressed & t->owner->btnSelect) && !(t->flags & 0x800)
            && (t->f290 == 0 || t->f294 == 0 || t->f298 == 0)) {
            s32 w = t->weapon;

            if (w != 0) {
                if (D_8021945C - t->f22C >= 0x79) {
                    func_800A9A44(t->owner, w);
                }
                do {
                    w = t->owner->nextWeapon[w];
                } while (t->ammo[w] == 0 && w != t->weapon);
                t->weapon = w;
                if (t->flags & 2) {
                    func_800C924C(&t->ammo[w], t->owner->id, w);
                }
                t->f22C = D_8021945C;
            }
        }
        if (t->flags & 8) {
            return;
        }
        if (t->f90 != 0 && (pad->pressed & t->owner->btnTurretReset)) {
            t->f90 = 0;
            if (D_80117F14[t->owner->id] == 1) {
                t->turretAng = 0;
            } else if (D_80117F14[t->owner->id] == 4) {
                t->turretAng = 0;
            }
            func_80095B90(t, 0xD);
        }
        if ((u16)func_80098334(t->pad) && D_8021945C - t->owner->f218 >= 0x3D) {
            D_80114694 = 1;
            func_8008BD5C(t, 10000, 0, 0);
            D_80114694 = 0;
            t->owner->f218 = D_8021945C;
            return;
        }
        t->f270 = (f32)pad->x / 80.0f * 8192.0f;
        func_80087F2C(t);
        if (func_80096250(t) != 0) {
            u16 mode = 1;

            if ((D_802194A0 == 0xB || D_802194A0 == 3 || D_802194A0 == 1) && t->fA0 != 0) {
                mode = 0x8001;
            }
            func_800C8238(t->aimX, t->aimY, t->ang, t->state, t->owner->id, mode);
        }
        if (t->flags & 0x200) {
            func_800C8B74(t, t->owner->id, t->state);
        } else {
            func_800C8EDC(t->owner->id);
        }
    } else {
        if (t->state != state) {
            t->px = t->x;
            t->py = t->y;
            t->pz = t->z;
        }
        func_80087C8C(t);
        if (func_80096250(t) != 0) {
            u16 mode = 0;

            if ((D_802194A0 == 0xB || D_802194A0 == 3 || D_802194A0 == 1) && t->fA0 != 0) {
                mode = 0x8000;
            }
            func_800C8238(t->x, t->y, t->ang, t->state, t->owner->id, mode);
        }
    }
    z = t->z;
    idx = t->index;
    x = t->x;
    y = t->y;
    n = &D_803978E0[idx];
    n->ang = t->ang;
    func_800B129C(idx, x, y);
    n->z = z;
    {
        f32 vx = (t->shakeVX + t->shakeX * -0.6f) * 0.65f;
        f32 vy = (t->shakeVY + t->shakeY * -0.6f) * 0.65f;

        t->shakeVX = vx;
        t->shakeVY = vy;
        t->shakeX += vx;
        t->shakeY += vy;
    }
    if (D_80122E8C[t->kind].flags & 0x10) {
        if (D_8021945C - t->f224 >= 0x1E) {
            if (t->f26E != 0) {
                t->f26E = (t->f26E >= 0xAA) ? t->f26E - 0xAA : 0;
            }
        } else {
            t->f26E = 0x1556;
        }
        t->f26C += t->f26E;
    }
    t->pz = (t->pz + t->z) / 2.0f;
    func_800902C0(t);
    func_80095C50(t);
    if (t->flags & 0x1000) {
        t->f4BC += 5.0f;
        if (t->f4BC > 600.0f) {
            t->f4BC = 600.0f;
        }
        t->aimX = t->x + func_8009D4B0(t->f4B8) * t->f4BC;
        t->aimY = t->y + func_8009D510(t->f4B8) * t->f4BC;
    }
}
