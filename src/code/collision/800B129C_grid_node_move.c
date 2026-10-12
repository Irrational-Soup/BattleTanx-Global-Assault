/* Move a spatial-grid node and relink each of its four cell memberships. */
#include "types.h"

typedef struct {
    s32 unk0;
    s32 unk4;
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
    u16 width;
    u16 height;
    u16 cell_width;
    u16 cell_height;
    u16 *cells;
    f32 scale;
    void *table;
} Grid;

extern GridNode D_803978E0[];
extern Grid D_803977F0[];
extern u16 D_801166E0[4];
extern u16 D_801166E8[4];
extern s32 func_800B0D70(u32 target, u16 *head, u16 direction);

void func_800B129C(u16 id, s16 x, s16 z) {
    GridNode *node = &D_803978E0[id];
    Grid *grid = &D_803977F0[node->grid];
    s32 dx;
    s32 dz;
    s32 nx;
    s32 nz;
    s32 old_x;
    s32 old_z;
    s32 new_x;
    s32 new_z;
    u16 *cell;
    s32 i;

    if (node->radius > 1024) {
        node->x = x;
    } else {
        u32 index = id;
        GridNode *write;

        dx = node->x - grid->x0;
        dz = node->z - grid->z0;
        nx = x - grid->x0;
        nz = z - grid->z0;
        write = node;
        for (i = 0; (u16)i < 4; i++) {
            old_x = (dx + D_801166E0[(u16)i]) >> 10;
            old_z = (dz + D_801166E8[(u16)i]) >> 10;
            new_x = (nx + D_801166E0[(u16)i]) >> 10;
            new_z = (nz + D_801166E8[(u16)i]) >> 10;
            if ((old_x != new_x) | (old_z != new_z)) {
                func_800B0D70(
                    index,
                    &grid->cells[
                        (((old_z + i * grid->cell_height) * grid->cell_width) +
                         old_x) & 0xFFFF] + 1,
                    i);
                cell = &grid->cells[
                    (((new_z + i * grid->cell_height) * grid->cell_width) +
                     new_x) & 0xFFFF] + 1;
                write->link[(u16)i] = *cell;
                *cell = id;
            }
        }
        node->x = x;
    }
    node->z = z;
}
