typedef short s16;
typedef unsigned short u16;

typedef struct {
    int unk0;
    int unk4;
    u16 link[4];
    s16 x;
    s16 z;
    s16 y;
    s16 dx0;
    s16 dx1;
    s16 dz0;
    s16 dz1;
    u16 unk1E;
    u16 unk20;
    s16 radius;
    u16 unk24;
    u16 grid;
} GridNode;

typedef struct {
    s16 x0;
    s16 z0;
    u16 w;
    u16 h;
    u16 cw;
    u16 ch;
    u16 *cells;
    float scale;
    void *table;
} Grid;

extern GridNode D_803978E0[];
extern Grid D_803977F0[];
extern u16 D_803977E8;

void func_800A2DFC(void);
void func_800B0E38(int id);
void func_800B14A8(int id, s16 x, s16 z);
int func_8009D6DC(u16 first, u16 second);

static inline u16 grid_node_allocate(void) {
    u16 head = D_803977E8;
    u16 id;
    GridNode *node;
    u16 i;

    if (head == 0xFFFF) {
        func_800A2DFC();
        if (D_803977E8 == head) {
            return 0xFFFF;
        }
    }
    id = D_803977E8;
    node = &D_803978E0[id];
    D_803977E8 = node->link[0];
    for (i = 0; i < 4; i++) {
        node->link[i] = 0xFFFF;
    }
    node->unk4 = 0;
    return id;
}

u16 func_800B1898(int data, s16 x, s16 z, s16 y, s16 dx0, s16 dx1,
                  s16 dz0, s16 dz1, u16 a8, u16 a9, u16 angle, int kind,
                  u16 grid) {
    int id = grid_node_allocate();
    GridNode *node;
    Grid *map;
    u16 dx;
    u16 dz;
    s16 swap;
    int px;
    int pz;

    if (id == 0xFFFF) {
        return 0xFFFF;
    }
    node = &D_803978E0[id];
    node->unk0 = kind;
    node->unk4 = data;
    if (kind & 0x039BEF67) {
        if (kind == 0x800) {
            angle = 0;
        }
        switch (angle) {
        case 0:
        case 0x4000:
        case 0x8000:
        case 0xC000:
            break;
        default:
            if ((u16)func_8009D6DC(0, angle) <= 0x1000) {
                angle = 0;
            } else if ((u16)func_8009D6DC(0x4000, angle) <= 0x1000) {
                angle = 0x4000;
            } else if ((u16)func_8009D6DC(0x8000, angle) <= 0x1000) {
                angle = 0x8000;
            } else if ((u16)func_8009D6DC(0xC000, angle) <= 0x1000) {
                angle = 0xC000;
            }
            break;
        }

        switch (angle) {
        case 0:
            break;
        case 0x4000:
            swap = dz0;
            dz0 = -dx1;
            dx1 = dz1;
            dz1 = -dx0;
            dx0 = swap;
            angle = 0;
            break;
        case 0x8000:
            swap = dx0;
            dx0 = -dx1;
            dx1 = -swap;
            swap = dz0;
            dz0 = -dz1;
            dz1 = -swap;
            angle = 0;
            break;
        case 0xC000:
            swap = dz0;
            dz0 = dx0;
            dx0 = -dz1;
            dz1 = dx1;
            dx1 = -swap;
            angle = 0;
            break;
        }
    }

    node->x = x;
    node->z = z;
    node->y = y;
    node->dx0 = dx0;
    node->dx1 = dx1;
    node->dz0 = dz0;
    node->dz1 = dz1;
    node->unk1E = a8;
    node->unk20 = a9;
    node->unk24 = angle;
    node->grid = grid;
    dx = ((dx0 > 0 ? dx0 : -dx0) > (dx1 > 0 ? dx1 : -dx1))
             ? (dx0 > 0 ? dx0 : -dx0)
             : (dx1 > 0 ? dx1 : -dx1);
    dz = ((dz0 > 0 ? dz0 : -dz0) > (dz1 > 0 ? dz1 : -dz1))
             ? (dz0 > 0 ? dz0 : -dz0)
             : (dz1 > 0 ? dz1 : -dz1);
    node->radius = (((dx > 0 ? dx : -dx) > (dz > 0 ? dz : -dz))
                        ? (dx > 0 ? dx : -dx)
                        : (dz > 0 ? dz : -dz))
                 + ((((dx > 0 ? dx : -dx) < (dz > 0 ? dz : -dz))
                         ? (dx > 0 ? dx : -dx)
                         : (dz > 0 ? dz : -dz)) * 3) / 8;
    map = &D_803977F0[grid];
    px = x - map->x0;
    pz = z - map->z0;
    if ((px < 0) | (pz < 0) || px >= (map->cw << 10) ||
        pz >= (map->ch << 10)) {
        if (px + dx1 < 0 || pz + dz1 < 0 ||
            px + dx0 >= (map->cw << 10) || pz + dz0 >= (map->ch << 10)) {
            node->link[0] = D_803977E8;
            D_803977E8 = id;
            node->unk4 = 0;
            node->grid = 0xFFFF;
            return 0xFFFF;
        }
        func_800B14A8(id, x, z);
        return id;
    }
    func_800B0E38(id);
    return id;
}
