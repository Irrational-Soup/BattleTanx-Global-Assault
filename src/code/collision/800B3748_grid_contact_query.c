/* SPAN 0x800B3748 */
typedef unsigned short u16;

typedef struct GridNode {
    int unk0;
    int unk4;
    u16 link[4];
    short x;
    short z;
    short y;
    short dx0;
    short dx1;
    short dz0;
    short dz1;
    u16 unk1E;
    u16 unk20;
    short radius;
    u16 unk24;
    u16 grid;
} GridNode;

typedef struct Grid {
    short x0;
    short z0;
    u16 w;
    u16 h;
    u16 cw;
    u16 ch;
    u16 *cells;
    float scale;
    void *tbl;
} Grid;

typedef struct Vec2 {
    float x;
    float y;
} Vec2;

typedef struct Contact {
    int data;
    short x0;
    short z0;
    short x1;
    short z1;
    u16 id;
    u16 padE;
    Vec2 push;
    float unk18;
    float unk1C;
    short side;
    u16 pad22;
} Contact;

extern GridNode D_803978E0[];
extern Grid D_803977F0[];
extern u16 D_801166E0[4];
extern u16 D_801166E8[4];
extern u16 D_801166F0;
extern u16 D_80397658[];

u16 func_800B3504(u16, u16, u16, int, Contact *, u16, u16);

static inline void func_800B0BE0(void) {
    u16 i;

    for (i = 0; i < D_801166F0; i++) {
        (&D_803978E0[(&D_80397658[i])[0]])->grid &= ~0x1000;
    }
    D_801166F0 = 0;
}

static inline u16 query_done(GridNode *n, u16 grow, u16 count) {
    if (grow != 0) {
        n->dx1 -= grow;
        n->dx0 += grow;
        n->dz0 += grow;
        n->dx1 -= grow;
    }
    func_800B0BE0();
    return count;
}

u16 func_800B3748(u16 id, int mask, Contact *out, u16 grow, u16 single) {
    GridNode *n = &D_803978E0[id];
    Grid *grid = &D_803977F0[n->grid];
    int px = n->x - grid->x0;
    int pz = n->z - grid->z0;
    u16 count;
    u16 added;
    u16 side;
    int row;
    int col;
    u16 index;
    u16 savedGrow;

    if (grow != 0) {
        n->dx1 += grow;
        n->dx0 -= grow;
        n->dz0 -= grow;
        n->dx1 += grow;
    }

    count = func_800B3504(id, grid->cells[0], 0, mask, out, 0, single);
    savedGrow = grow;
    if (single && count) {
        return query_done(n, savedGrow, count);
    }

    for (side = 0; side < 4; side++) {
        row = ((pz + D_801166E8[side]) >> 10) + side * grid->ch;
        col = (px + D_801166E0[side]) >> 10;
        index = row * grid->cw + col;
        added = func_800B3504(id, grid->cells[index + 1], side,
                              mask, out, count, single);
        if (added != 0) {
            count += added;
            if (single || count >= 32) {
                return query_done(n, savedGrow, count);
            }
        }
    }

    return query_done(n, savedGrow, count);
}
