/* RODATA_VRAM 0x800718EC */
typedef unsigned short u16;
typedef struct { char p0[0x14]; short x0; short x1; short y0; short y1; char p1c[0xB8 - 0x1C]; u16 radius; u16 inner; char pbc[0xD0 - 0xBC]; } Zone;
extern Zone D_80122E28[];
void func_800873D0(void);
void func_80089610(void);
float sqrtf(float);
int abs(int);

#define ABS(x) ((x) < 0 ? -(x) : (x))
#define MAX(a, b) ((a) < (b) ? (b) : (a))
#define MIN(a, b) ((a) > (b) ? (b) : (a))

void func_8008A1A4(void) {
    u16 i;

    func_800873D0();
    func_80089610();
    for (i = 0; i < 15; i++) {
        Zone *z = &D_80122E28[i];
        float w, h;
        {
            int p = z->x1;
            int q = z->x0;
            int r = abs(p);
            q = abs(q);
            if (r < q) r = q;
            w = r;
        }
        {
            int p = z->y1;
            int q = z->y0;
            int r = abs(p);
            q = abs(q);
            if (r < q) r = q;
            h = r;
            z->radius = sqrtf(w * w + h * h);
        }
        {
            int q = abs(z->y0);
            int p = z->y1;
            int r = abs(p);
            int s, t, u;
            if (q < r) r = q;
            t = z->x1;
            u = z->x0;
            s = abs(t);
            u = abs(u);
            if (u < s) s = u;
            if (r < s) s = r;
            z->inner = s;
        }
    }
}
