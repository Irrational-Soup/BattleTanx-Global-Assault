/* RODATA_VRAM 0x80072F64 */
#include "model_draw_internal.h"

typedef short s16;

typedef struct {
    char pad00[0x18];
    s16 x;
    u16 xf;
    s16 y;
    u16 yf;
    char pad20[0x40 - 0x20];
    s16 x0, y0, x1, y1;
    ModelDrawModel *model;
    u8 type;
    u8 mask;
    u8 flags;
    u8 pad4F;
} WorldObj;

typedef struct {
    char pad00[0x10];
    int count;
    WorldObj *objs;
    char pad18[0x20 - 0x18];
} Area;

typedef struct {
    int pad00;
    Area areas[1];
} World;

extern int D_8023A060;
void func_800AB980(s16 x0, s16 y0, s16 x1, s16 y1, int layer,
                   int index, int view, int maxEdge, int maxDist2);
int func_800AC538(s16 x0, s16 y0, s16 x1, s16 y1, int layer, int view,
                  int maxEdge, int maxDist2);
int func_800ABE6C(int *list, int view);
void *func_800AA058(u8 area, float *pos);

void func_800AF978(u8 areaIndex, int view) {
    int count;
    int n;
    Area *area;
    int range;
    int range2;
    int high;
    int visible[256];
    float pos[3];
    ModelDrawVec2 p2;
    WorldObj *o;
    void *arg1;
    int i;

    area = &((World *)D_80219498.world)->areas[areaIndex];
    range = D_8023A060;
    count = area->count;
    range2 = range * range;
    high = D_80219498.views[view].high;
    for (i = 0; i < count; i++) {
        o = &area->objs[i];
        if (!(o->flags & 0x80)) {
            continue;
        }
        if (high && (o->flags & ~0x80) < 2) {
            continue;
        }
        if (!((o->mask >> (view + 4)) & 1)) {
            continue;
        }
        if (o->type == 2) {
            o->mask &= ~(1 << (view + 4));
        }
        func_800AB980(o->x0, o->y0, o->x1, o->y1, o->flags & ~0x80,
                      i, view, range, range2);
    }
    n = func_800ABE6C(visible, view);
    for (i = 0; i < n; i++) {
        o = &area->objs[visible[i]];
        if (o->type == 2) {
            o->mask |= 1 << (view + 4);
            continue;
        }
        pos[0] = o->x;
        pos[2] = o->xf;
        pos[1] = o->y;
        arg1 = func_800AA058(areaIndex, pos);
        {
            int flag = (o->type == 1) << 2;
            int m = o->mask & 0xF;
            ModelDrawModel *model = o->model;
            ModelDrawLod *lod;
            int k;

            if (model != 0) {
                p2.x = ((ModelDrawFixedTransform *)o)->x / 65536.0f;
                p2.y = ((ModelDrawFixedTransform *)o)->y / 65536.0f;
                lod = &model->lods[model_draw_select_lod(
                    &D_80219498.views[view].pos, &p2, model->lodMode)];
                for (k = 0; k < lod->count; k++) {
                    ModelDrawPart *part = &lod->parts[k];

                    func_8007B1F0(part->a, part->c, part->b, arg1, m, 0,
                                  (ModelDrawFixedTransform *)o, view, flag, 0);
                }
            }
        }
    }
    for (i = 0; i < count; i++) {
        o = &area->objs[i];
        if (o->flags & 0x80) {
            if (!high || (o->flags & 0x7F) != 1) {
                continue;
            }
        }
        if (!((o->mask >> (view + 4)) & 1)) {
            continue;
        }
        if (o->type == 2) {
            o->mask &= ~(1 << (view + 4));
        }
        if (!func_800AC538(o->x0, o->y0, o->x1, o->y1,
                           o->flags & 0x7F, view, range, range2)) {
            continue;
        }
        if (o->type == 2) {
            o->mask |= 1 << (view + 4);
            continue;
        }
        pos[0] = o->x;
        pos[2] = o->xf;
        pos[1] = o->y;
        arg1 = func_800AA058(areaIndex, pos);
        switch (o->type) {
        case 0:
            model_draw_object_for_view(o->model, arg1, 0,
                (ModelDrawFixedTransform *)o, 0, o->mask & 0xF, view);
            break;
        case 1:
            model_draw_object_for_view(o->model, arg1, 0,
                (ModelDrawFixedTransform *)o, 4, o->mask & 0xF, view);
            break;
        case 3:
            func_8007B1F0(o->model->lods[0].parts[0].a,
                          o->model->lods[0].parts[0].c,
                          o->model->lods[0].parts[0].b, arg1, 0, 0,
                          (ModelDrawFixedTransform *)o, view, 0, 0);
            func_8007B1F0(o->model->lods[0].parts[1].a,
                          o->model->lods[0].parts[1].c,
                          o->model->lods[0].parts[1].b, arg1, 0, 0,
                          (ModelDrawFixedTransform *)o, view, 2, 0);
            break;
        case 4:
            func_8007B1F0(o->model->lods[0].parts[0].a,
                          o->model->lods[0].parts[0].c,
                          o->model->lods[0].parts[0].b, arg1, 0, 0,
                          (ModelDrawFixedTransform *)o, view, 4, 0);
            func_8007B1F0(o->model->lods[0].parts[1].a,
                          o->model->lods[0].parts[1].c,
                          o->model->lods[0].parts[1].b, arg1, 0, 0,
                          (ModelDrawFixedTransform *)o, view, 5, 0);
            break;
        }
    }
}
