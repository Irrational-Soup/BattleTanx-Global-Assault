/* Test a segment against one grid node footprint (rotated box) and return the contacted face. */
/* SPAN 0x800B4294 */
/* RODATA_VRAM 0x80073078 */
typedef short s16;
typedef unsigned short u16;

typedef struct { float x, y, z; } Vec3f;
typedef struct { float x, y, z; } Normal;
typedef struct { float x, y; } Vec2;
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
float func_8009D4B0(u16 a);
float func_8009D510(u16 a);
u16 func_800B2890(s16 x, s16 z, u16 id);

u16 func_800B3B60(Vec3f *a, Vec3f *b, s16 id, Vec3f *pt, Normal *nrm) {
    GridNode *node;
    Vec2 d, la, lb, dir;
    float s, c, t, v;

    d.x = b->x - a->x;
    d.y = b->y - a->y;
    if (d.x == 0.0f && d.y == 0.0f) {
        if (func_800B2890((s16)a->x, (s16)a->y, (u16)id)) {
            pt->x = a->x;
            pt->y = a->y;
            nrm->x = 0.0f;
            nrm->y = 1.0f;
            return 7;
        }
        return 0;
    }
    node = &D_803978E0[id];
    if (node->angle == 0) {
        s = 0.0f;
        c = 1.0f;
        la.x = a->x - node->x;
        la.y = a->y - node->z;
        dir.x = d.x;
        dir.y = d.y;
        lb.x = b->x - node->x;
        lb.y = b->y - node->z;
    } else {
        s = func_8009D4B0(node->angle);
        c = func_8009D510(node->angle);
        la.x = c * (a->x - node->x) + -s * (a->y - node->z);
        la.y = s * (a->x - node->x) + c * (a->y - node->z);
        dir.x = c * d.x + -s * d.y;
        dir.y = s * d.x + c * d.y;
        lb.x = la.x + dir.x;
        lb.y = la.y + dir.y;
    }
    if (la.x < node->dx0) {
        if (lb.x < node->dx0) return 0;
        if (la.y < node->dz0) {
            if (lb.y < node->dz0) return 0;
            t = (node->dz0 - la.y) / dir.y;
            v = la.x + t * dir.x;
            if (node->dx0 <= v && v <= node->dx1) {
                pt->x = a->x + t * d.x;
                pt->y = a->y + t * d.y;
                nrm->x = -s;
                nrm->y = -c;
                return 2;
            }
        } else if (node->dz1 < la.y) {
            if (node->dz1 < lb.y) return 0;
            t = (node->dz1 - la.y) / dir.y;
            v = la.x + t * dir.x;
            if (node->dx0 <= v && v <= node->dx1) {
                pt->x = a->x + t * d.x;
                pt->y = a->y + t * d.y;
                nrm->x = s;
                nrm->y = c;
                return 1;
            }
        }
        t = (node->dx0 - la.x) / dir.x;
        v = la.y + t * dir.y;
        if (!(node->dz0 <= v)) return 0;
        if (!(v <= node->dz1)) return 0;
        pt->x = a->x + t * d.x;
        pt->y = a->y + t * d.y;
        nrm->x = -c;
        nrm->y = s;
        return 4;
    } else if (node->dx1 < la.x) {
        if (node->dx1 < lb.x) return 0;
        if (la.y < node->dz0) {
            if (lb.y < node->dz0) return 0;
            t = (node->dz0 - la.y) / dir.y;
            v = la.x + t * dir.x;
            if (node->dx0 <= v && v <= node->dx1) {
                pt->x = a->x + t * d.x;
                pt->y = a->y + t * d.y;
                nrm->x = -s;
                nrm->y = -c;
                return 2;
            }
        } else if (node->dz1 < la.y) {
            if (node->dz1 < lb.y) return 0;
            t = (node->dz1 - la.y) / dir.y;
            v = la.x + t * dir.x;
            if (node->dx0 <= v && v <= node->dx1) {
                pt->x = a->x + t * d.x;
                pt->y = a->y + t * d.y;
                nrm->x = s;
                nrm->y = c;
                return 1;
            }
        }
        t = (node->dx1 - la.x) / dir.x;
        v = la.y + t * dir.y;
        if (!(node->dz0 <= v)) return 0;
        if (!(v <= node->dz1)) return 0;
        pt->x = a->x + t * d.x;
        pt->y = a->y + t * d.y;
        nrm->x = c;
        nrm->y = -s;
        return 3;
    } else {
        if (la.y < node->dz0) {
            if (lb.y < node->dz0) return 0;
            t = (node->dz0 - la.y) / dir.y;
            v = la.x + t * dir.x;
            if (node->dx0 <= v && v <= node->dx1) {
                pt->x = a->x + t * d.x;
                pt->y = a->y + t * d.y;
                nrm->x = -s;
                nrm->y = -c;
                return 2;
            }
            return 0;
        } else if (node->dz1 < la.y) {
            if (node->dz1 < lb.y) return 0;
            t = (node->dz1 - la.y) / dir.y;
            v = la.x + t * dir.x;
            if (node->dx0 <= v && v <= node->dx1) {
                pt->x = a->x + t * d.x;
                pt->y = a->y + t * d.y;
                nrm->x = s;
                nrm->y = c;
                return 1;
            }
            return 0;
        } else {
            pt->x = a->x;
            pt->y = a->y;
            nrm->x = 0.0f;
            nrm->y = 1.0f;
            return 7;
        }
    }
}
