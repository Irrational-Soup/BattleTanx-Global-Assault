/* SPAN 0x800A0744 */
/* RODATA_VRAM 0x80072660 */
#include "types.h"

typedef struct Vec3 { f32 x, y, z; } Vec3;
typedef struct Plane { f32 x, y, z, w; } Plane;
typedef f32 Mat4[4][4];

extern f32 sqrtf(f32);
extern f32 func_8009EC0C(f32 *);
extern void func_8009EB68(Plane *, Vec3 *, Vec3 *, Vec3 *);
extern void guRotateF(Mat4, f32, f32, f32, f32);

extern Vec3 D_8021C4C0;
extern Vec3 D_8021C4F0;

static __inline__ f32 vec_distance(Vec3 *a, Vec3 *b) {
    f32 x = a->x - b->x;
    f32 z = a->z - b->z;
    f32 y = a->y - b->y;
    return sqrtf(x * x + z * z + y * y);
}

s32 func_8009FFB8(Vec3 *player, Vec3 *start, Vec3 *end, u16 angle,
                  f32 radius, f32 divisor, Mat4 out) {
    Mat4 rotation;
    Mat4 local;
    Vec3 center;
    Vec3 half;
    Vec3 first;
    Vec3 second;
    Vec3 relative;
    Vec3 cross;
    Vec3 side;
    Vec3 direction;
    Vec3 plane_point;
    Vec3 work;
    Plane plane;
    f32 length;
    f32 first_side;
    f32 second_side;
    f32 center_side;
    f32 scale = radius;
    s32 clipped = 0;
    s32 short_segment = 0;
    s32 first_negative;
    s32 second_negative;
    s32 row;
    s32 column;
    Vec3 *p;
    f32 (*rotp)[4];
    f32 (*locp)[4];

    half.x = start->x - end->x;
    half.z = start->z - end->z;
    half.y = start->y - end->y;
    length = sqrtf(half.x * half.x + half.z * half.z + half.y * half.y);
    if (radius * divisor < length && 0.0001 < (f64)length) {
        direction.x = half.x / length;
        direction.z = half.z / length;
        direction.y = half.y / length;
        half.x /= 2.0f;
        half.z /= 2.0f;
        half.y /= 2.0f;
        center.x = start->x - half.x;
        center.z = start->z - half.z;
        center.y = start->y - half.y;
    } else {
        direction.x = 0.0f;
        direction.y = 0.0f;
        direction.z = 1.0f;
        center.x = start->x;
        center.y = start->y;
        center.z = start->z;
        short_segment = 1;
    }

    p = player;
    relative.x = p->x - center.x;
    relative.z = p->z - center.z;
    relative.y = p->y - center.y;
    if (func_8009EC0C(&relative.x) < 16.0f) {
        return 0;
    }

    if (short_segment) goto build_side;
    {
        plane.x = relative.x;
        plane.y = relative.y;
        plane.z = relative.z;
        plane.x = -plane.x;
        plane.y = -plane.y;
        plane.z = -plane.z;
        plane_point.x = p->x + plane.x * 16.0f;
        plane_point.z = p->z + plane.z * 16.0f;
        plane_point.y = p->y + plane.y * 16.0f;
        plane.w = -(plane_point.x * plane.x + plane_point.z * plane.z +
                    plane_point.y * plane.y);

        work.x = start->x - plane_point.x;
        work.z = start->z - plane_point.z;
        work.y = start->y - plane_point.y;
        first_side = work.x * plane.x + work.z * plane.z + work.y * plane.y;

        work.x = end->x - plane_point.x;
        work.z = end->z - plane_point.z;
        work.y = end->y - plane_point.y;
        second_side = work.x * plane.x + work.z * plane.z + work.y * plane.y;

        work.x = center.x - plane_point.x;
        work.z = center.z - plane_point.z;
        work.y = center.y - plane_point.y;
        center_side = work.x * plane.x + work.z * plane.z + work.y * plane.y;

        D_8021C4C0.x = plane_point.x;
        D_8021C4C0.y = plane_point.y;
        D_8021C4C0.z = plane_point.z;
        D_8021C4F0.x = p->x;
        D_8021C4F0.y = p->y;
        D_8021C4F0.z = p->z;

        if (center_side < 0.0f) goto build_side;
        {
            first = *start;
            second = *end;
            first_negative = 1;
            if (!(first_side < 0.0f)) {
                first_negative = 0;
            }
            second_negative = 1;
            if (!(second_side < 0.0f)) {
                second_negative = 0;
            }
            if (!(first_negative & second_negative)) {
                if (first_side < 0.0f) {
                    func_8009EB68(&plane, &first, &second, &first);
                    clipped |= 1;
                } else if (second_side < 0.0f) {
                    func_8009EB68(&plane, &first, &second, &second);
                    clipped |= 2;
                }
                plane.x = relative.x;
                plane.y = relative.y;
                plane.z = relative.z;
                plane.w = -(center.x * relative.x + center.z * relative.z +
                            center.y * relative.y);
                if (!(clipped & 1)) {
                    func_8009EB68(&plane, p, &first, &first);
                }
                if (!(clipped & 2)) {
                    func_8009EB68(&plane, p, &second, &second);
                }
                scale = vec_distance(&first, &second) / divisor;
                if (scale < radius) {
                    scale = radius;
                } else {
                    center.x = first.x + second.x;
                    center.z = first.z + second.z;
                    center.y = first.y + second.y;
                    center.x /= 2.0f;
                    center.z /= 2.0f;
                    center.y /= 2.0f;
                }
            }
        }
    }

build_side:
    side.x = relative.z * direction.y - direction.z * relative.y;
    side.z = relative.y * direction.x - direction.y * relative.x;
    side.y = relative.x * direction.z - direction.x * relative.z;
    func_8009EC0C(&side.x);

    cross.x = relative.z * side.y - side.z * relative.y;
    cross.z = relative.y * side.x - side.y * relative.x;
    cross.y = relative.x * side.z - side.x * relative.z;

    local[0][0] = side.x * radius;
    local[0][1] = side.z * radius;
    local[0][2] = side.y * radius;
    local[0][3] = 0.0f;
    local[1][0] = cross.x * scale;
    local[1][1] = cross.z * scale;
    local[1][2] = cross.y * scale;
    local[1][3] = 0.0f;
    local[2][0] = relative.x * radius;
    local[2][1] = relative.z * radius;
    local[2][2] = relative.y * radius;
    local[2][3] = 0.0f;
    local[3][0] = center.x;
    local[3][1] = center.z;
    local[3][2] = center.y;
    local[3][3] = 1.0f;

    guRotateF(rotation, (f32)angle * 0.0054931640625f, 0.0f, 0.0f, 1.0f);
    rotp = rotation;
    locp = local;
    for (row = 0; row < 4; row++) {
        for (column = 0; column < 4; column++) {
            out[column][row] = rotp[column][0] * locp[0][row] +
                               rotp[column][1] * locp[1][row] +
                               rotp[column][2] * locp[2][row] +
                               rotp[column][3] * locp[3][row];
        }
    }
    return 1;
}
