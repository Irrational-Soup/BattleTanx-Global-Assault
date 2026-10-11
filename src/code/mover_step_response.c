typedef unsigned short u16;

typedef struct {
    float x;
    float y;
} Vec2;

typedef struct {
    float velocityX;
    float velocityY;
    float speed;
    float acceleration;
    float drag;
    float scale;
    u16 unk18;
    float unk1C;
    short unk20;
    float unk24;
    float unk28;
    float unk2C;
    float unk30;
    int unk34;
    float multiplier;
} Mover;

extern float D_8007314C;
extern float D_80219488;

float func_8009D4B0(u16 angle);
float func_8009D510(u16 angle);
float func_8009E948(float *vector);
void func_800B66E0(Mover *mover, Vec2 *point);

static inline void mover_reduce_speed(Mover *mover, float amount) {
    float reduction;

    if (mover->speed <= 0.0) {
        return;
    }
    reduction = (mover->scale + amount) * D_80219488;
    if (reduction <= 0.0f) {
        return;
    }
    mover->speed -= reduction;
    if (mover->speed < 0.0) {
        mover->speed = 0.0f;
    }
}

static inline void mover_apply_force(Mover *mover, float amount, u16 angle) {
    Vec2 delta;
    Vec2 direction;
    float limit;
    float oldSpeed;
    float magnitude;

    if (mover->multiplier == D_8007314C) {
        limit = mover->acceleration * amount;
    } else {
        limit = mover->acceleration * mover->multiplier * amount;
    }
    if (limit == 0.0) {
        return;
    }
    oldSpeed = mover->speed;
    direction.x = func_8009D4B0(angle);
    direction.y = func_8009D510(angle);
    if (limit < 0.0f) {
        limit = -limit;
        direction.y = -direction.y;
        direction.x = -direction.x;
    }
    magnitude = mover->drag * D_80219488;
    delta.x = magnitude * direction.x;
    delta.y = magnitude * direction.y;
    mover->velocityX *= mover->speed;
    mover->velocityY *= mover->speed;
    mover->velocityX += delta.x;
    mover->velocityY += delta.y;
    mover->speed = func_8009E948(&mover->velocityX);
    if (oldSpeed <= limit && limit < mover->speed) {
        mover->speed = limit;
    } else if (limit < oldSpeed && oldSpeed < mover->speed) {
        mover->speed = oldSpeed;
    }
}

void func_800B8100(Mover *mover, float amount, u16 angle, Vec2 *point) {
    mover_reduce_speed(mover, 0.0f);
    mover_apply_force(mover, amount, angle);
    func_800B66E0(mover, point);
}
