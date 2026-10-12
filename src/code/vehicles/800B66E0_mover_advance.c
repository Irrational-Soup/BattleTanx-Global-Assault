typedef unsigned char u8;
typedef unsigned short u16;

typedef struct Vec2 {
    float x;
    float y;
} Vec2;

typedef struct Segment {
    float x;
    float y;
    float dx;
    float dy;
    float length;
} Segment;

typedef struct Mover {
    float direction_x;
    float direction_y;
    float speed;
    float speed_scale;
    float unk10;
    float unk14;
    u16 unk18;
    float unk1C;
    short unk20;
    float unk24;
    float unk28;
    float unk2C;
    float unk30;
    int unk34;
    float unk38;
    short unk3C;
    short unk3E;
    char pad40[4];
    int unk44[4];
    int unk54[4];
    short unk64;
    Segment *segment;
} Mover;

extern float D_80219488;
extern int func_80097FB4(int, float, float, float, u8);

static inline void reflect_from_segment(Mover *mover) {
    float dot;

    if (mover->direction_x == mover->segment->dx &&
        mover->direction_y == mover->segment->dy) {
        return;
    }
    dot = mover->direction_x * mover->segment->dx +
          mover->direction_y * mover->segment->dy;
    if (dot < 0.0f) {
        mover->speed *= -dot;
        mover->direction_x = -mover->segment->dx;
        mover->direction_y = -mover->segment->dy;
    } else {
        mover->speed *= dot;
        mover->direction_x = mover->segment->dx;
        mover->direction_y = mover->segment->dy;
    }
}

static inline u16 clamp_to_segment_endpoint(Mover *mover, Vec2 *point) {
    Vec2 endpoints[2];
    float radius_squared;
    float distance0;
    float distance1;
    float dx;
    float dy;

    endpoints[0].x = mover->segment->x;
    endpoints[0].y = mover->segment->y;
    endpoints[1].x = endpoints[0].x +
                     mover->segment->dx * mover->segment->length;
    endpoints[1].y = endpoints[0].y +
                     mover->segment->dy * mover->segment->length;
    radius_squared = mover->segment->length;
    radius_squared *= radius_squared;
    dx = point->x - endpoints[0].x;
    dy = point->y - endpoints[0].y;
    distance0 = dx * dx + dy * dy;
    dx = point->x - endpoints[1].x;
    dy = point->y - endpoints[1].y;
    distance1 = dx * dx + dy * dy;
    if (radius_squared < distance0) {
        point->x = endpoints[1].x;
        point->y = endpoints[1].y;
        return 1;
    }
    if (radius_squared < distance1) {
        point->x = endpoints[0].x;
        point->y = endpoints[0].y;
        return 1;
    }
    return 0;
}

static inline void scale_and_normalize_speed(Mover *mover, float amount) {
    mover->speed *= amount;
    if (mover->speed < 0.0f) {
        mover->direction_x = -mover->direction_x;
        mover->direction_y = -mover->direction_y;
        mover->speed = -mover->speed;
    }
}

void func_800B66E0(Mover *mover, Vec2 *point) {
    float amount;

    if (mover->segment != 0) {
        reflect_from_segment(mover);
    }
    amount = mover->speed * D_80219488;
    point->x += mover->direction_x * amount;
    point->y += mover->direction_y * amount;
    if (mover->segment != 0 && clamp_to_segment_endpoint(mover, point)) {
        func_80097FB4(14, point->x, point->y,
                      mover->speed / mover->speed_scale, 0);
        scale_and_normalize_speed(mover, -1.0f);
    }
}
