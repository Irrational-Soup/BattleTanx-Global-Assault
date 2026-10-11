typedef unsigned short u16;
typedef short s16;

typedef struct {
    unsigned int kind;
    int unk04;
    u16 links[4];
    s16 x;
    s16 z;
    s16 y;
    s16 dx0;
    s16 dx1;
    s16 dz0;
    s16 dz1;
    s16 height0;
    s16 height1;
    s16 radius;
    u16 angle;
    u16 grid;
} GridNode;

typedef struct {
    float x;
    float y;
} Vec2;

extern GridNode D_803978E0[];
float func_8009D4B0(u16 angle);
float func_8009D510(u16 angle);

static inline int node_index(u16 id) {
    return id;
}

int func_800B5728(int id, int side, int margin, Vec2 *a, Vec2 *b) {
    GridNode *node;
    float points[4];
    float sine;
    float cosine;
    u16 index = node_index(id);

    id = (u16)id >= 1400;
    if (id) {
        return 1;
    }
    node = &D_803978E0[(u16)index];
    switch ((u16)side) {
    case 1:
        points[0] = node->dx0 - (u16)margin;
        points[1] = node->dz1 + (u16)margin;
        points[2] = node->dx1 + (u16)margin;
        points[3] = points[1];
        break;
    case 2:
        points[0] = node->dx1 + (u16)margin;
        points[1] = node->dz0 - (u16)margin;
        points[2] = node->dx0 - (u16)margin;
        points[3] = points[1];
        break;
    case 4:
        points[0] = node->dx0 - (u16)margin;
        points[1] = node->dz0 - (u16)margin;
        points[2] = points[0];
        points[3] = node->dz1 + (u16)margin;
        break;
    case 3:
        points[0] = node->dx1 + (u16)margin;
        points[1] = node->dz1 + (u16)margin;
        points[2] = points[0];
        points[3] = node->dz0 - (u16)margin;
        break;
    default:
        return 1;
    }

    if (node->angle == 0) {
        a->x = points[0] + node->x;
        a->y = points[1] + node->z;
        b->x = points[2] + node->x;
        b->y = points[3] + node->z;
        return 0;
    }
    sine = func_8009D4B0(node->angle);
    cosine = func_8009D510(node->angle);
    a->x = cosine * points[0] + sine * points[1] + node->x;
    a->y = -sine * points[0] + cosine * points[1] + node->z;
    b->x = cosine * points[2] + sine * points[3] + node->x;
    b->y = -sine * points[2] + cosine * points[3] + node->z;
    return 0;
}
