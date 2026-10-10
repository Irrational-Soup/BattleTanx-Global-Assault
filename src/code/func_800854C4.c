/* RODATA_VRAM 0x8007135C */
typedef struct { float x, y; } Point2;
typedef struct { Point2 position; Point2 direction; float spread; } Leader;
typedef struct {
    unsigned int state;
    Point2 home;
    Point2 target;
    char pad14[4];
    float speed;
    int timer;
} AiState;
typedef struct Tank {
    char pad00[8];
    Point2 position;
    char pad10[0x90 - 0x10];
    Leader *leader;
    char pad94[0xA8 - 0x94];
    int seen;
    int seen_by;
    char padB0[0x170 - 0xB0];
    AiState ai;
    char pad190[0x1D0 - 0x190];
    struct { char pad00[0x10]; int team; } *owner;
} Tank;

extern int D_8021945C;
void func_80086208(Tank *, int);
Tank *func_80084CC8(Tank *, int);
int func_800848E8(Tank *);
float func_8009D8A0(float);
void func_8009DB0C(Point2 *, float);
void func_8009DA44(Point2 *, Leader *, Point2 *);
void func_8009E044(Point2 *, void *);

void func_800854C4(Tank *entity) {
    Point2 vector;
    Point2 delta1;
    Point2 delta2;
    Leader *leader;
    Tank *target;
    float dot;
    AiState *ai;
    int idle = 2;

    if (entity->leader == 0) {
        func_80086208(entity, 4);
        return;
    }
    ai = &entity->ai;
    switch (ai->state) {
    case 1:
        ai->state = idle;
        break;
    case 2:
        if (D_8021945C >= ai->timer) {
            Tank *seen;
            ai->timer = D_8021945C + 10;
            seen = func_80084CC8(entity, entity->seen_by);
            if (seen == 0)
                seen = func_80084CC8(entity, entity->seen);
            if (seen != 0) {
                if (seen->owner->team == entity->owner->team)
                    ai->state = 3;
                else
                    ai->state = 4;
                break;
            }
        }
        ai->speed = (entity->seen != 0) ? 1.0f : 0.2f;
        if (func_800848E8(entity) == 0)
            break;
        leader = entity->leader;
        if (leader != 0) {
            vector.x = leader->direction.x;
            vector.y = leader->direction.y;
            func_8009DB0C(&vector, func_8009D8A0(leader->spread));
            ai->target.x = leader->position.x;
            ai->target.y = leader->position.y;
            func_8009E044(&entity->ai.target, &vector);
        }
        func_800848E8(entity);
        break;
    case 3:
        target = func_80084CC8(entity, entity->seen_by);
        if (target == 0)
            target = func_80084CC8(entity, entity->seen);
        if ((target == 0) || (target->owner->team != entity->owner->team)) {
            ai->state = idle;
            break;
        }
        leader = entity->leader;
        func_8009DA44(&delta1, leader, &target->position);
        dot = (delta1.x * leader->direction.x) +
              (delta1.y * leader->direction.y);
        func_8009DA44(&delta2, leader, &entity->position);
        if (dot < ((delta2.x * leader->direction.x) +
                   (delta2.y * leader->direction.y))) {
            entity->ai.target.x = entity->ai.home.x;
            entity->ai.target.y = entity->ai.home.y;
        } else {
            entity->ai.target.x = leader->position.x;
            entity->ai.target.y = leader->position.y;
        }
        func_800848E8(entity);
        break;
    case 4:
        target = func_80084CC8(entity, entity->seen_by);
        if (target == 0)
            target = func_80084CC8(entity, entity->seen);
        if ((target == 0) || (target->owner->team == entity->owner->team)) {
            ai->state = idle;
            break;
        }
        leader = entity->leader;
        func_8009DA44(&vector, leader, &target->position);
        dot = (vector.x * leader->direction.x) +
              (vector.y * leader->direction.y);
        func_8009DA44(&delta1, leader, &entity->position);
        entity->ai.target.x = leader->direction.x;
        entity->ai.target.y = leader->direction.y;
        func_8009DB0C(&entity->ai.target, dot);
        func_8009E044(&entity->ai.target, leader);
        func_800848E8(entity);
        break;
    }
}
