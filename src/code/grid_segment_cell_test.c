/* Test a segment against one grid cell and return the contacted face. */
typedef short s16;
typedef unsigned short u16;
typedef int s32;

typedef struct { float x, y, z; } Vec3f;
typedef struct { float x, y, z; } Normal;
typedef struct {
    int unk0;
    int unk4;
    u16 link[4];
    s16 x, z, y;
    s16 dx0, dx1;
    s16 dz0, dz1;
    s16 low, high;
    s16 radius;
    u16 angle;
    u16 grid;
} GridNode;

extern GridNode D_803978E0[];
u16 func_800B2890(s16 x, s16 z, u16 id, s16 y);
u16 func_800B3B60(Vec3f *a, Vec3f *b, s16 id, Vec3f *pt, Normal *nrm);

u16 func_800B4294(Vec3f *a, Vec3f *b, s16 id, Vec3f *pt, Normal *nrm) {
    GridNode *node;
    float dx = a->x - b->x;
    float dy = a->y - b->y;
    float dz = a->z - b->z;
    float top, bottom;
    float y, x, z, t, f;
    float normal;
    u16 contact;
    u16 result;
    s16 node_id;

    if ((dx == 0.0f) & (dy == 0.0f)) {
        if (dz == 0.0f) {
            u16 hit;
            s32 ix = (s32)a->x;
            s32 iy = (s32)a->y;
            s32 iz = (s32)a->z;
            GridNode *g = &D_803978E0[(u16)id];
            if ((s16)iz >= g->y + g->low &&
                g->y + g->high >= (s16)iz) {
                hit = func_800B2890((s16)ix, (s16)iy, (u16)id, g->y);
            } else {
                hit = 0;
            }
            if (hit) {
                nrm->x = 0.0f;
                nrm->y = 0.0f;
                nrm->z = 1.0f;
                pt->x = a->x;
                pt->y = a->y;
                pt->z = a->z;
                return 7;
            }
            return 0;
        } else {
            node_id = id;
        }
    } else {
        node_id = id;
    }

    node = &D_803978E0[node_id];
    nrm->z = 0.0f;
    top = node->y + node->high;
    bottom = node->y + node->low;
    if (!((top < a->z && top < b->z) || (a->z < bottom && b->z < bottom))) {
        contact = func_800B3B60(a, b, id, pt, nrm);
        if (contact) {
            if (dx == 0.0f) {
                z = a->z;
            } else {
                f = (pt->x - a->x) / dx;
                z = a->z + f * dz;
            }
            if ((bottom <= z) & (z <= top)) {
                pt->z = z;
                return contact;
            }
            y = (top < z) ? top : bottom;
            if (dz == 0.0f) {
                x = a->z;
                t = a->y;
            } else {
                f = (y - a->z) / dz;
                x = a->x + f * dx;
                t = a->y + f * dy;
            }
            if ((float)(node->x + node->dx0) < x &&
                x < (float)(node->x + node->dx1) &&
                (float)(node->z + node->dz0) < t &&
                t < (float)(node->z + node->dz1)) {
                pt->x = x;
                pt->y = t;
                pt->z = z;
                if (y == top) {
                    float zero1 = 0.0f;
                    nrm->y = zero1;
                    nrm->x = zero1;
                    nrm->z = 1.0f;
                    return 5;
                } else {
                    float zero2 = 0.0f;
                    nrm->y = zero2;
                    nrm->x = zero2;
                    nrm->z = -1.0f;
                    return 6;
                }
            }
        }
    }
    return 0;
}
