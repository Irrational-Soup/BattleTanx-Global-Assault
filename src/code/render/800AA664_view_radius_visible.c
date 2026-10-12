/* SPAN 0x800AA8A8 */
/* RODATA_VRAM 0x80072DA0 */
typedef unsigned char u8;

typedef struct {
    float x, y;
    float ax, ay;
    float bx, by;
    float ox, oy;
    char p20[4];
    u8 active;
    u8 kind;
    char p26[2];
} View;

extern int D_8023A060;

#define ABS(x) ((x) > 0.0f ? (x) : -(x))
#define MAX(a, b) ((a) > (b) ? (a) : (b))
#define MIN(a, b) ((a) < (b) ? (a) : (b))
#define DIST(dx, dy) (MAX(ABS(dx), ABS(dy)) + MIN(ABS(dx), ABS(dy)) * 3.0f / 8.0f)

int func_800AA664(float x, float y, float r, u8 kind, View *v) {
    float dx;
    float dy;
    float lim;
    float dist;
    float ext;
    double rr;
    float px;
    float py;

    if (v->kind != kind) {
        return 0;
    }
    if (v->active != 0) {
        return 1;
    }
    dx = v->x - x;
    dy = v->y - y;
    if (DIST(dx, dy) > D_8023A060 + r) {
        return 0;
    }
    rr = r * 1.5;
    py = y + v->oy;
    px = x + v->ox;
    dist = v->ax * py + v->ay * px;
    ext = v->bx * px - v->by * py;
    if (dist + rr <= 0.0) {
        return 0;
    }
    if (ext > 0.0f) {
        if (ext - rr < dist) {
            return 1;
        }
    } else {
        if (-ext - rr < dist) {
            return 1;
        }
    }
    return 0;
}
