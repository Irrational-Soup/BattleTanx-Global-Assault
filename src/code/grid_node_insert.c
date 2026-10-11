typedef short s16;
typedef unsigned short u16;

typedef struct {
    int unk0;
    int unk4;
    u16 links[4];
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
    u16 width;
    u16 height;
    u16 cellWidth;
    u16 cellHeight;
    u16 *cells;
    float scale;
    void *table;
} Grid;

extern GridNode D_803978E0[];
extern Grid D_803977F0[];
extern u16 D_801166E0[4];
extern u16 D_801166E8[4];

void func_800B0E38(u16 id) {
    GridNode *node = &D_803978E0[id];
    GridNode *source = node;
    GridNode *write;
    Grid *grid = &D_803977F0[node->grid];
    u16 *cell;
    int dx;
    int dz;
    u16 i;
    u16 *xOffsets;
    u16 *zOffsets;

    if (node->radius > 1024) {
        cell = grid->cells;
        node->links[0] = *cell;
        *cell = id;
        return;
    }
    dx = source->x - grid->x0;
    dz = source->z - grid->z0;
    write = source;
    xOffsets = D_801166E0;
    zOffsets = D_801166E8;
    for (i = 0; i < 4; i++) {
        cell = (&grid->cells[
                    (((((dz + zOffsets[i]) >> 10) +
                       (i * grid->cellHeight)) * grid->cellWidth) +
                     ((dx + xOffsets[i]) >> 10)) & 0xFFFF]) + 1;
        write->links[i] = *cell;
        *cell = id;
    }
}
