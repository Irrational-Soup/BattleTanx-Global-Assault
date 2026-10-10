/* SPAN 0x8009FF1C */
typedef unsigned short u16;
typedef float f32;

typedef struct { f32 x, y, z; } Vec3;
typedef struct { f32 m[4][4]; } Mtx;

f32 func_8009D4B0(u16 a);
f32 func_8009D510(u16 a);

void func_8009FCCC(Mtx *m, Vec3 *ofs, Vec3 *pos, u16 rz, u16 ry, u16 rx) {
    f32 cx, sx, sy, cy, sz, cz;
    Vec3 t;

    m->m[0][3] = 0.0f;
    m->m[1][3] = 0.0f;
    m->m[2][3] = 0.0f;
    m->m[3][0] = pos->x;
    m->m[3][1] = pos->z;
    m->m[3][2] = pos->y;
    sx = func_8009D4B0(rx);
    cx = func_8009D510(rx);
    sy = func_8009D4B0(ry);
    cy = func_8009D510(ry);
    sz = func_8009D4B0(rz);
    cz = func_8009D510(rz);
    m->m[0][0] = cy * cz;
    m->m[0][1] = cy * sz;
    m->m[0][2] = -sy;
    m->m[1][0] = sx * sy * cz - cx * sz;
    m->m[1][1] = sx * sy * sz + cx * cz;
    m->m[1][2] = sx * cy;
    m->m[2][0] = cx * sy * cz + sx * sz;
    m->m[2][1] = cx * sy * sz - sx * cz;
    m->m[2][2] = cx * cy;
    t.x = ofs->x * m->m[0][0] + ofs->z * m->m[1][0] + ofs->y * m->m[2][0] + m->m[3][0];
    t.z = ofs->x * m->m[0][1] + ofs->z * m->m[1][1] + ofs->y * m->m[2][1] + m->m[3][1];
    t.y = ofs->x * m->m[0][2] + ofs->z * m->m[1][2] + ofs->y * m->m[2][2] + m->m[3][2];
    m->m[3][0] = t.x;
    m->m[3][1] = t.z;
    m->m[3][2] = t.y;
}
