/* RODATA_VRAM 0x8007318C */
typedef short s16;
typedef unsigned short u16;

typedef struct {
    float x;
    float y;
} Vec2;

typedef struct {
    unsigned int kind;
    int unk4;
    u16 link[4];
    s16 x;
    s16 z;
    s16 y;
    s16 dx0;
    s16 dx1;
    s16 dz0;
    s16 dz1;
    s16 h0;
    s16 h1;
    s16 radius;
    u16 unk24;
    u16 grid;
} GridNode;

extern GridNode D_803978E0[];

float sqrtf(float x);
u16 func_8009D578(float x);
void func_800B2BE4(GridNode *node, Vec2 *corners);
float func_800B93A4(Vec2 *point, u16 grid);

extern inline u16 func_800B8310(float x, float y)
{
    u16 negative;
    u16 angle;
    u16 result;

    if (x < 0.0f) {
        negative = 1;
        x = -x;
    } else {
        negative = 0;
    }

    angle = func_8009D578(x / sqrtf(x * x + y * y)) >> 1;
    result = angle;
    if (negative) {
        result = angle ^ 0xFFFF;
    }
    return result;
}

float func_800B95C8(u16 id, u16 *angleX, u16 *angleZ)
{
    GridNode *node = &D_803978E0[id];
    GridNode *loopNode;
    Vec2 corners[4];
    float heights[4];
    s16 dimensions[2];
    u16 i;
    float delta;
    Vec2 *cornerBase;

    *angleX = 0;
    *angleZ = 0;
    cornerBase = corners;
    func_800B2BE4(node, cornerBase);
    i = 0;
    loopNode = node;
    for (; i < 4; i++) {
        ((float *)(cornerBase + 4))[i] =
            func_800B93A4(&cornerBase[i], loopNode->grid);
    }

    {
        GridNode *current = &D_803978E0[id];

        dimensions[0] = (current->dx1 - current->dx0 > 0)
                              ? current->dx1 - current->dx0
                              : current->dx0 - current->dx1;
        dimensions[1] = (current->dz1 - current->dz0 > 0)
                              ? current->dz1 - current->dz0
                              : current->dz0 - current->dz1;
    }

    delta = heights[0] - heights[1];
    if (delta != 0.0f) {
        *angleX = func_800B8310(delta, dimensions[1]);
    }
    delta = heights[3] - heights[2];
    if (delta != 0.0f) {
        *angleX += func_800B8310(delta, dimensions[1]);
    }
    delta = heights[3] - heights[0];
    if (delta != 0.0f) {
        *angleZ = func_800B8310(delta, dimensions[0]);
    }
    delta = heights[2] - heights[1];
    if (delta != 0.0f) {
        *angleZ += func_800B8310(delta, dimensions[0]);
    }

    return (heights[0] + heights[1] + heights[2] + heights[3]) / 4.0f;
}
