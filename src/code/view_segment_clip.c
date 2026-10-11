/* SPAN 0x800AB4DC */
/* RODATA_VRAM 0x80072DC8 */
typedef unsigned char u8;
typedef short s16;

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

extern View D_802194B4[];

#define IA ((-z1 * e2 + z2 * e1) / (-e2 + e1 + z1 - z2))
#define IB ((z1 * e2 - z2 * e1) / (e2 - e1 + z1 - z2))
#define CLIP_BOTH() \
    dep0 = IA; \
    if (dep0 < 0.0f) { \
        return 0; \
    } \
    dep1 = IB; \
    sx0 = 0.0f; \
    sx1 = 99.0f
#define CLIP_BOTH2() \
    dep0 = IA; \
    dep1 = IB; \
    sx0 = 0.0f; \
    sx1 = 99.0f
#define RIGHT_VIS() \
    sx0 = 0.0f; \
    sx1 = e2 * 100.0f / 2.0f / z2 + 50.0f; \
    dep0 = IA; \
    dep1 = z2
#define LEFT_VIS() \
    sx0 = e2 * 100.0f / 2.0f / z2 + 50.0f; \
    dep0 = z2; \
    sx1 = 99.0f; \
    dep1 = (z1 * e2 - dep0 * e1) / (e2 - e1 + z1 - dep0)

int func_800AAEA0(s16 a, s16 b, s16 c, s16 d, int view, int *x0, float *d0, int *x1, float *d1) {
    View *v = &D_802194B4[view];
    float px1;
    float py1;
    float px2;
    float py2;
    float e1;
    float e2;
    float z1;
    float z2;
    float sx0;
    float sx1;
    float dep0;
    float dep1;
    float t;
    u8 f1 = 0;
    u8 f2 = 0;

    py1 = b + v->oy;
    px1 = a + v->ox;
    z1 = v->ax * py1 + v->ay * px1;
    py2 = d + v->oy;
    px2 = c + v->ox;
    z2 = v->ax * py2 + v->ay * px2;
    if (0.0f < z1) f1 = 1;
    if (0.0f < z2) f2 = 1;
    if ((u8)(f1 | f2) == 0) return 0;
    e1 = v->bx * px1 - v->by * py1;
    e2 = v->bx * px2 - v->by * py2;
    if (e1 < z1) f1 |= 4;
    if (e2 < z2) f2 |= 4;
    if (((f1 | f2) & 4) == 0) return 0;
    if (-e1 < z1) f1 |= 2;
    if (-e2 < z2) f2 |= 2;
    if (((f1 | f2) & 2) == 0) return 0;
    switch (f1) {
    case 7:
        switch (f2) {
        case 7:
            sx0 = e1 * 100.0f / 2.0f / z1 + 50.0f;
            sx1 = e2 * 100.0f / 2.0f / z2 + 50.0f;
            if (sx0 < sx1) {
                dep0 = z1;
                dep1 = z2;
            } else {
                t = sx0;
                sx0 = sx1;
                sx1 = t;
                dep1 = z1;
                dep0 = z2;
            }
            break;
        case 4:
        case 5:
            sx0 = 0.0f;
            sx1 = e1 * 100.0f / 2.0f / z1 + 50.0f;
            dep0 = (-z1 * e2 + z2 * e1) / (-e2 + e1 + z1 - z2);
            dep1 = z1;
            break;
        case 0:
            dep0 = IA;
            if (0.0f < dep0) {
                sx1 = e1 * 100.0f / 2.0f / z1 + 50.0f;
                sx0 = 0.0f;
                dep1 = z1;
            } else {
                sx0 = e1 * 100.0f / 2.0f / z1 + 50.0f;
                dep0 = z1;
                sx1 = 99.0f;
                dep1 = (dep0 * e2 - z2 * e1) / (e2 - e1 + dep0 - z2);
            }
            break;
        case 2:
        case 3:
            sx0 = e1 * 100.0f / 2.0f / z1 + 50.0f;
            dep0 = z1;
            sx1 = 99.0f;
            dep1 = (dep0 * e2 - z2 * e1) / (e2 - e1 + dep0 - z2);
            break;
        default:
            return 0;
        }
        break;
    case 5:
        switch (f2) {
        case 3: CLIP_BOTH2(); break;
        case 7: RIGHT_VIS(); break;
        case 2: CLIP_BOTH(); break;
        default: return 0;
        }
        break;
    case 4:
        switch (f2) {
        case 7: RIGHT_VIS(); break;
        case 3: CLIP_BOTH(); break;
        default: return 0;
        }
        break;
    case 0:
        if (f2 != 7) return 0;
        dep0 = IA;
        if (0.0f < dep0) {
            sx1 = e2 * 100.0f / 2.0f / z2 + 50.0f;
            sx0 = 0.0f;
            dep1 = z2;
        } else {
            sx0 = e2 * 100.0f / 2.0f / z2 + 50.0f;
            dep0 = z2;
            sx1 = 99.0f;
            dep1 = (z1 * e2 - z2 * e1) / (e2 - e1 + z1 - dep0);
        }
        break;
    case 2:
        switch (f2) {
        case 7: LEFT_VIS(); break;
        case 5: CLIP_BOTH(); break;
        default: return 0;
        }
        break;
    case 3:
        switch (f2) {
        case 7: LEFT_VIS(); break;
        case 5: CLIP_BOTH2(); break;
        case 4: CLIP_BOTH(); break;
        default: return 0;
        }
        break;
    default:
        return 0;
    }
    *x0 = sx0;
    *x1 = sx1;
    *d0 = dep0;
    *d1 = dep1;
    return 1;
}
