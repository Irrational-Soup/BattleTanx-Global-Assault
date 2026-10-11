/* RODATA_VRAM 0x800725DC */

typedef struct {
    float x;
    float y;
} Vec2;

#define ABS(x) ((x) > 0.0f ? (x) : -(x))
#define MAX(a, b) ((a) > (b) ? (a) : (b))
#define MIN(a, b) ((a) < (b) ? (a) : (b))
#define DIST(dx, dy) \
    (MAX(ABS(dx), ABS(dy)) + MIN(ABS(dx), ABS(dy)) * 3.0f / 8.0f)

int func_8009DB2C(Vec2 *v, float len) {
    float s;
    float d = DIST(v->x, v->y);

    if (d > 0.0f) {
        s = len / DIST(v->x, v->y);
        v->x *= s;
        v->y *= s;
        return 1;
    }
    return 0;
}
