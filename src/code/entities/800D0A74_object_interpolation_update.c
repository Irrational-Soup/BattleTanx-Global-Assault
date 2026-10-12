typedef unsigned char u8;
typedef unsigned short u16;
typedef short s16;
typedef int s32;

typedef struct Obj {
    s32 unk0;
    s16 x, y, unk8, unkA;
    s16 targetX, targetY;
    u8 r, g, b, a;
    u8 targetR, targetG, targetB, targetA;
    float posTimer;
    float colorTimer;
    float repeatTimer;
    float fracX, fracY;
    float fracR, fracG, fracB, fracA;
    float unk3C;
    float repeatStep;
    float unk44, unk48;
    u8 pad4C[2];
    u16 repeats;
} Obj;

extern float D_80219488;

void func_800D0A74(Obj *o) {
    if (o->posTimer > 0.0f) {
        o->posTimer -= D_80219488;
        if ((double)o->posTimer <= 0.0) {
            o->posTimer = 0.0f;
            o->x = o->targetX;
            o->y = o->targetY;
        } else {
            float ratio;
            ratio = D_80219488 / (o->posTimer + D_80219488);
            o->fracX += ratio * (o->targetX - o->x);
            o->fracY += ratio * (o->targetY - o->y);
            o->x += (s16)o->fracX;
            o->y += (s16)o->fracY;
            o->fracX -= (s16)o->fracX;
            o->fracY -= (s16)o->fracY;
        }
    }

    if (o->colorTimer > 0.0f) {
        o->colorTimer -= D_80219488;
        if ((double)o->colorTimer <= 0.0) {
            o->colorTimer = 0.0f;
            o->r = o->targetR;
            o->g = o->targetG;
            o->b = o->targetB;
            o->a = o->targetA;
        } else {
            float ratio;
            ratio = D_80219488 / (o->colorTimer + D_80219488);
            o->fracR += ratio * (o->targetR - o->r);
            o->fracG += ratio * (o->targetG - o->g);
            o->fracB += ratio * (o->targetB - o->b);
            o->fracA += ratio * (o->targetA - o->a);
            o->r += (s16)o->fracR;
            o->g += (s16)o->fracG;
            o->b += (s16)o->fracB;
            o->a += (s16)o->fracA;
            o->fracR -= (s16)o->fracR;
            o->fracG -= (s16)o->fracG;
            o->fracB -= (s16)o->fracB;
            o->fracA -= (s16)o->fracA;
        }
    }

    if (o->repeatTimer > 0.0f) {
        o->repeatTimer -= D_80219488;
        if ((double)o->repeatTimer <= 0.0) {
            float timer;
            do {
                timer = o->repeatTimer;
                timer += o->repeatStep;
                o->repeats++;
                o->repeatTimer = timer;
            } while ((double)timer <= 0.0);
        }
    }
}
