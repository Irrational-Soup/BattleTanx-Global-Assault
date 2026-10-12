/* Per-mode match-result check: 0 = continue, 1 = result set, 2 = all out. */
/* RODATA_VRAM 0x800724D0 */
/* SPAN 0x8009C098 */
typedef unsigned char u8;
typedef unsigned short u16;

typedef struct {
    u16 score;          /* 0x00 */
    char p2[2];
    u16 flags;          /* 0x04 */
    char p6[2];
    float value;        /* 0x08 */
    char pC[0x18 - 0xC];
    u8 team;            /* 0x18 */
    char p19[0x1C - 0x19];
} TeamInfo;

typedef struct {
    char p0[0xA];
    u8 fA;              /* 0x0A */
    char pb[0x10 - 0xB];
    TeamInfo *info;     /* 0x10 */
    char p14[0x74 - 0x14];
    int state;          /* 0x74 */
    char p78[0x1B0 - 0x78];
    int kills;          /* 0x1B0 */
    char p1B4[0x250 - 0x1B4];
} Unit;

typedef struct {
    char p0[0x68];
    int limit;          /* 0x68 */
} LevelDef;

typedef struct {
    void *world;        /* 0x80219498 */
    int track;          /* 0x8021949C */
    unsigned int mode;  /* 0x802194A0 */
    u8 nHuman;          /* 0x802194A4 */
    u8 nPlayers;        /* 0x802194A5 */
    u8 nTanks;          /* 0x802194A6 */
    u8 nSlots;          /* 0x802194A7 */
    u8 teams[5];        /* 0x802194A8 */
    char pad[3];
    int time;           /* 0x802194B0 */
    char listeners[0xEA - 0x1C];
    u8 inv[5];          /* 0x80219582 */
    u8 order[5];        /* 0x80219587 */
    LevelDef *level;    /* 0x8021958C */
    char p590[0x108 - 0xF8];
    int slotVal[5];     /* 0x802195A0 */
    int f5B4;           /* 0x802195B4 */
} GameState;

extern GameState D_80219498;
extern int D_8021945C;
extern Unit D_80235F00[];
extern TeamInfo D_80236A90[];

void func_800A96B8(Unit *u);

static inline Unit *getUnit(int i) {
    if (i == 127) {
        return 0;
    }
    return &D_80235F00[i];
}

static inline int teamKills(TeamInfo *t) {
    Unit *u;
    int j = 0;
    int sum = 0;

    for (; j < D_80219498.nTanks; j++) {
        u = getUnit(j);
        if (u->info == t) {
            sum += u->kills;
        }
    }
    return sum;
}

/* Same source-family loop as the exact neighbouring func_8009B534. */
static inline int surviving_sides(int strict) {
    Unit *u;
    int i;
    int a = 0;
    int b = 0;

    for (i = 0; i < D_80219498.nTanks; i++) {
        u = getUnit(i);
        func_800A96B8(u);
        if (u->state != 2) {
            if (u->fA & 2) {
                b++;
            } else {
                a++;
            }
        }
    }
    if (b == 0 || ((a == 0) & (strict != 0))) {
        return 2;
    }
    return 0;
}

int func_8009B694(void) {
    Unit *u;
    TeamInfo *t;
    TeamInfo *win;
    TeamInfo *lose;
    int i;
    int sum;
    int best;
    int flag = 0;
    Unit *p;

    switch (D_80219498.mode) {
    case 5:
        best = -1;
        if (D_8021945C > D_80219498.time) {
            for (i = 0; i < D_80219498.nSlots; i++) {
                sum = teamKills(&D_80236A90[i]);
                if (best < sum) {
                    best = sum;
                }
            }
            for (i = 0; i < D_80219498.nTanks; i++) {
                if (teamKills(getUnit(i)->info) == best) {
                    getUnit(i)->state = 1;
                } else {
                    getUnit(i)->state = 2;
                }
            }
            return 1;
        }
        break;
    case 0:
    case 6:
        for (i = 0; i < D_80219498.nSlots; i++) {
            t = &D_80236A90[i];
            if (t->score >= D_80219498.time) {
                return 2;
            }
        }
        return 0;
    case 3:
        for (i = 0; i < D_80219498.nSlots; i++) {
            t = &D_80236A90[i];
            if ((float)D_80219498.time <= t->value) {
                flag = 1;
            }
        }
        if (flag) {
            for (i = 0; i < D_80219498.nTanks; i++) {
                u = getUnit(i);
                if ((float)D_80219498.time <= u->info->value) {
                    u->state = 1;
                } else {
                    u->state = 2;
                }
            }
            return 1;
        }
        return 0;
    case 4:
        win = 0;
        lose = 0;
        for (i = 0; i < D_80219498.nTanks; i++) {
            if (getUnit(i)->state == 1) {
                win = getUnit(i)->info;
            }
            if (getUnit(i)->state == 2) {
                lose = getUnit(i)->info;
            }
        }
        if (win) {
            for (i = 0; i < D_80219498.nTanks; i++) {
                u = getUnit(i);
                if (u->info == win) {
                    u->state = 1;
                } else {
                    u->state = 2;
                }
            }
            return 1;
        }
        if (lose) {
            for (i = 0; i < D_80219498.nTanks; i++) {
                u = getUnit(i);
                if (u->info == lose) {
                    u->state = 2;
                } else {
                    u->state = 1;
                }
            }
            return 1;
        }
        return 0;
    case 1:
    case 2:
    case 11:
    case 13:
        for (i = 0; i < D_80219498.nSlots; i++) {
            t = &D_80236A90[i];
            if (t->flags >= D_80219498.time) {
                flag = 1;
            }
        }
        if (flag) {
            for (i = 0; i < D_80219498.nTanks; i++) {
                u = getUnit(i);
                if (u->info->flags >= D_80219498.time) {
                    u->state = 1;
                } else {
                    u->state = 2;
                }
            }
            return 1;
        }
        {
            int special = (D_80219498.mode == 11) | (D_80219498.mode == 13);
            if (special != 0) {
                flag = 1;
                for (i = 0; i < D_80219498.nTanks; i++) {
                    u = getUnit(i);
                    if (u->fA & 2) {
                        func_800A96B8(u);
                        if (u->state != 2) {
                            flag = 0;
                        }
                    }
                }
                if (flag) {
                    return 2;
                }
            }
        }
        break;
    case 12:
        if (D_80219498.f5B4 != 0) {
            if (D_80219498.level->limit < D_8021945C - D_80219498.f5B4) {
                D_80235F00[0].state = 1;
            }
        } else if (D_80219498.time == 0) {
            D_80219498.f5B4 = D_8021945C;
        }
    case 7:
    case 10:
    case 14:
        p = getUnit(0);
        if (p->state == 1) {
            for (i = 0; i < D_80219498.nTanks; i++) {
                u = getUnit(i);
                if (u->info == p->info) {
                    u->state = 1;
                } else {
                    u->state = 2;
                }
            }
            return 1;
        }
        if (p->state == 2 && (D_80219498.nHuman == 1 || D_80235F00[1].state == p->state)) {
            for (i = 0; i < D_80219498.nTanks; i++) {
                u = getUnit(i);
                if (u->info == p->info) {
                    u->state = 2;
                } else {
                    u->state = 1;
                }
            }
            return 1;
        }
        return surviving_sides(0);
    case 9:
        if (D_8021945C >= D_80219498.time) {
            p = getUnit(0);
            for (i = 0; i < D_80219498.nTanks; i++) {
                u = getUnit(i);
                if (u->info == p->info) {
                    u->state = 1;
                } else {
                    u->state = 2;
                }
            }
            return 1;
        }
        p = getUnit(0);
        if (p->state == 2) {
            for (i = 0; i < D_80219498.nTanks; i++) {
                u = getUnit(i);
                if (u->info == p->info) {
                    u->state = 2;
                } else {
                    u->state = 1;
                }
            }
            return 1;
        }
        return surviving_sides(1);
    case 8:
        return surviving_sides(1);
    }
    return 0;
}
