/* RODATA_VRAM 0x80072F04 */
#include "model_draw_internal.h"

typedef struct { u8 pad[0xA8]; u8 f168[0x250 - 0xA8]; } ModelDrawPlayer;
typedef struct { float m[16]; int x; } ModelDrawMatrix;

extern ModelDrawPlayer D_80235F00[];
void *func_8007B0E4(void *commands, int count, void *part);
int func_8009FFB8(void *player, void *a, void *b, u16 angle, float scale,
                  float unit, ModelDrawMatrix *out);

static const ModelDrawMatrix D_80072F04 = {
    { 1.0f, 0.0f, 0.0f, 0.0f,
      0.0f, 1.0f, 0.0f, 0.0f,
      0.0f, 0.0f, 1.0f, 0.0f,
      0.0f, 0.0f, 0.0f, 1.0f },
    0
};

float sqrtf(float);

inline void func_800AE8EC(int view, ModelDrawModel *model, void *unused, float *pos,
                   float *axis, int arg5, float width, float height, int arg8,
                   void *commands, int commandCount) {
    ModelDrawMatrix mt = D_80072F04;
    ModelDrawPlayer *pl;
    float d[3];
    float c[3];
    float len;
    ModelDrawVec2 position;
    ModelDrawLod *lod;
    ModelDrawObjectTransform *obj;

    if (view == 127) {
        pl = 0;
    } else {
        pl = &D_80235F00[view];
    }
    d[0] = *(float *)&pl->f168[0] - pos[0];
    d[2] = *(float *)&pl->f168[8] - pos[2];
    d[1] = *(float *)&pl->f168[4] - pos[1];
    c[0] = axis[2] * d[1] - axis[1] * d[2];
    c[2] = axis[1] * d[0] - axis[0] * d[1];
    c[1] = axis[0] * d[2] - axis[2] * d[0];
    len = sqrtf(c[0] * c[0] + c[2] * c[2] + c[1] * c[1]);
    if (len == 0.0) {
        return;
    }
    c[0] /= len;
    c[2] /= len;
    c[1] /= len;
    mt.m[0] = c[0] * width;
    mt.m[1] = c[2] * width;
    mt.m[2] = c[1] * width;
    mt.m[4] = axis[0] * height;
    mt.m[5] = axis[2] * height;
    mt.m[6] = axis[1] * height;
    mt.m[12] = pos[0];
    mt.m[13] = pos[2];
    mt.m[14] = pos[1];
    if (commands == 0) {
        obj = (ModelDrawObjectTransform *)&mt;
        if (model == 0) {
            return;
        }
        position.x = mt.m[12];
        position.y = mt.m[14];
        lod = &model->lods[model_draw_select_lod(&D_80219498.views[view].pos,
                                                 &position, model->lodMode)];
        {
        int i;

        for (i = 0; i < lod->count; i++) {
            ModelDrawPart *part = &lod->parts[i];

            func_8007B1F0(part->a, part->c, part->b, 0, arg8,
                          obj, 0, view, arg5, 0);
        }
        }
    } else {
        ModelDrawLod *lod2 = model->lods;
        {
        int i;

        for (i = 0; i < lod2->count; i++) {
            ModelDrawPart *part = &lod2->parts[i];

            func_8007B1F0(part->a, func_8007B0E4(commands, commandCount,
                                                 part->c),
                          part->b, 0, arg8, (ModelDrawObjectTransform *)&mt, 0,
                          view, arg5, 1);
        }
        }
    }
}

void func_800AECF0(ModelDrawModel *model, void *unused, float *pos,
                   float *axis, int arg5, float width, float height, int arg8,
                   void *commands, int commandCount, u8 mask) {
    int playerCount = D_80219498.nPlayers;
    int view;

    for (view = 0; view < playerCount; view++) {
        if ((mask >> view) & 1) {
            func_800AE8EC(view, model, unused, pos, axis, arg5, width, height,
                          arg8, commands, commandCount);
        }
    }
}

void func_800AF13C(ModelDrawModel *model, void *a, void *b, float scale,
                   u16 angle, int arg5, int arg6, void *commands,
                   int commandCount, u8 mask) {
    int playerCount = D_80219498.nPlayers;
    int done = 0;
    int view;
    ModelDrawMatrix mt;
    void *relocated[32];
    ModelDrawLod *lod;
    ModelDrawPlayer *pl;
    int i;

    for (view = 0; view < playerCount; view++) {
        if (!((mask >> view) & 1)) {
            continue;
        }
        pl = (view == 127) ? 0 : &D_80235F00[view];
        if (!func_8009FFB8(pl->f168, a, b, angle, scale, 1.0f, &mt)) {
            continue;
        }
        mt.x = 0;
        lod = model->lods;
        if (!done) {
            if (commandCount != 0) {
                for (i = 0; i < lod->count; i++) {
                    relocated[i] = func_8007B0E4(commands, commandCount,
                                                 lod->parts[i].c);
                }
            } else {
                for (i = 0; i < lod->count; i++) {
                    relocated[i] = lod->parts[i].c;
                }
            }
            done = 1;
        }
        for (i = 0; i < lod->count; i++) {
            ModelDrawPart *part = &lod->parts[i];

            func_8007B1F0(part->a, relocated[i], part->b, 0,
                          arg6, (ModelDrawObjectTransform *)&mt, 0, view,
                          arg5, 1);
        }
    }
}
