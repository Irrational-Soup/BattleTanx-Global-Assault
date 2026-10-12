/* SPAN 0x800B739C */
/* RODATA_VRAM 0x80073118 */
typedef short s16;
typedef unsigned short u16;
typedef unsigned int u32;

typedef struct { float x, y; } Vec2;

typedef struct {
    int value;
    u16 node;
    char pad06[0x1A];
    u16 feature;
    char pad22[2];
} Contact;

typedef struct {
    char pad00[0x68];
    u32 mode;
} Object;

#define ABSF(x) ((x) > 0.0f ? (x) : -(x))

float func_8009E948(Vec2 *v);
void func_800B2488(s16 x, s16 y, u16 node, Vec2 *out);
float func_800B6CC4(Object *o, u16 moving, u16 fixed, Vec2 *dir, Vec2 *point);
float sqrtf(float x);

extern double D_80073120;
extern float D_80073128;

int func_800B6F40(Object *o, u16 moving, Vec2 *from, Vec2 *to,
                  Contact *contacts, u16 count, int *selected,
                  Vec2 *point, u16 *feature)
{
    Vec2 hit;
    Vec2 delta;
    Vec2 average;
    Vec2 normals[10];
    float length;
    float best;
    float push;
    u16 normal_count;
    u16 i;
    u16 j;
    Contact *rec = contacts;

    delta.x = to->x - from->x;
    delta.y = to->y - from->y;
    length = func_8009E948(&delta);
    normal_count = 0;

    if (o->mode == 0) {
        for (i = 0; i < count; i++, rec++) {
            u16 node = rec->node;
            float tx = to->x;
            Vec2 *normal = &normals[normal_count];

            func_800B2488((s16)tx, (s16)to->y, node, normal);
            for (j = 0; j < normal_count; j++) {
                if (normals[normal_count].x == normals[j].x && normals[normal_count].y == normals[j].y) {
                    break;
                }
                if (ABSF(normals[normal_count].x + normals[j].x) < 0.001f &&
                    ABSF(normals[normal_count].y + normals[j].y) < 0.001f)
                    return 1;
            }
            if (j < normal_count)
                continue;
            normal_count++;
            if (normal_count >= 10)
                return 1;
        }

        {
            float zero = 0.0f;
            average.y = zero;
            average.x = zero;
        }
        for (i = 0; i < normal_count; i++) {
            average.x += normals[i].x;
            average.y += normals[i].y;
        }
        if (normal_count >= 2)
            func_8009E948(&average);
        if (((double)length <= D_80073120) | (normal_count >= 2)) {
            delta.x = average.x;
            delta.y = average.y;
        } else if ((average.x * delta.x + average.y * delta.y) < 0.0f) {
            delta.x = average.x;
            delta.y = average.y;
        }
    }

    *selected = 0;
    best = 0.0f;
    rec = contacts;
    for (i = 0; i < count; rec++, i++) {
        float d = func_800B6CC4(o, moving, rec->node, &delta, &hit);
        if (best < d) {
            *selected = rec->value;
            point->x = hit.x;
            point->y = hit.y;
            best = d;
            *feature = rec->feature;
        }
    }
    if (best == 0.0f)
        return 0;

    best = sqrtf(best);
    best += D_80073128;
    from->x += best * delta.x;
    from->y += best * delta.y;
    point->x += best * delta.x;
    point->y += best * delta.y;
    return 0;
}
