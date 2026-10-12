typedef short s16;
typedef unsigned short u16;

typedef struct {
    float x;
    float y;
} Vec2;

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
    void *data;
    u16 id;
    char pad06[0x24 - 6];
} Contact;

extern GridNode D_803978E0[];

void func_800B2364(Vec2 *input, u16 angle, Vec2 *output);
u16 func_800B5130(Vec2 *point, int mask, u16 grid, Contact *out, u16 single);
float func_800B83A8(u16 id, Vec2 *point);
int abs(int value);

static inline float sloped_height(u16 id, Vec2 *point) {
    GridNode *node = &D_803978E0[id];
    Vec2 delta;
    Vec2 rotated;

    delta.x = point->x - node->x;
    delta.y = point->y - node->z;
    func_800B2364(&delta, node->angle, &rotated);
    return (node->height0 + node->y) +
        (float)(node->height1 - node->height0) *
        (rotated.y - node->dz0) / (node->dz1 - node->dz0);
}

static inline float flat_height(u16 id) {
    GridNode *node = &D_803978E0[id];

    if (abs(node->height0) > abs(node->height1)) {
        return node->height0 + node->y;
    }
    return node->height1 + node->y;
}

typedef struct {
    char pad00[0x28];
    float base;
    char pad2C[0x44 - 0x2C];
    float corner[4];
    int cornerState[4];
    u16 flags;
} GroundObj;

extern u16 D_80397650;
u16 func_800B3748(u16 id, int mask, Contact *out, u16 grow, u16 single);
void func_800B2BE4(GridNode *node, Vec2 *corners);
u16 func_800B2890(s16 x, s16 y, u16 id);

void func_800B9094(GroundObj *obj, u16 id) {
    Vec2 corners[4];
    Contact hits[32];
    float base;
    float h;
    u16 count;
    u16 loaded;
    u16 c;
    u16 k;
    GridNode *node;

    D_80397650 = 0;
    count = func_800B3748(id, 0xE0, hits, 0, 0);
    loaded = 0;
    base = obj->base;
    obj->flags &= 0xFFF0;
    for (c = 0; c < 4; c++) {
        h = base;
        for (k = 0; k < count; k++) {
            if (!loaded) {
                func_800B2BE4(&D_803978E0[id], corners);
                loaded = 1;
            }
            if (func_800B2890(corners[c].x, corners[c].y, hits[k].id)) {
                node = &D_803978E0[hits[k].id];
                switch (node->kind & 0xE0) {
                case 0x40:
                    h = func_800B83A8(hits[k].id, &corners[c]);
                    break;
                case 0x80:
                    h = sloped_height(hits[k].id, &corners[c]);
                    break;
                case 0x20:
                    h = flat_height(hits[k].id);
                    break;
                }
                break;
            }
        }
        if (h < base) {
            if (h < 0.0f) {
                h += base;
            } else {
                h = base;
            }
        }
        obj->corner[c] = h;
        obj->cornerState[c] = 0;
    }
}
