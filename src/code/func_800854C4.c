/* RODATA_VRAM 0x8007135C */
typedef struct { float x, y; } Pt;
typedef struct { Pt pos; Pt dir; float spread; } Leader;
typedef struct { unsigned int state; Pt home; Pt target; char p14[4]; float speed; int timer; } Ai;
typedef struct Tank {
    char p0[8]; Pt pos; char p10[0x90 - 0x10]; Leader *leader; char p94[0xA8 - 0x94]; int seen; int seenBy;
    char pb0[0x170 - 0xB0]; Ai ai; char p190[0x1D0 - 0x190]; struct { char p[0x10]; int team; } *owner;
} Tank;
extern int D_8021945C;
void func_80086208(Tank *, int);
Tank *func_80084CC8(Tank *, int);
int func_800848E8(Tank *);
float func_8009D8A0(float);
void func_8009DB0C(Pt *, float);
void func_8009DA44(Pt *, Leader *, Pt *);
void func_8009E044(Pt *, void *);

void func_800854C4(Tank *e) {
    Leader *l;
    Tank *t;
    float dot;
    Ai *ai;
    int idle = 2;

    if (e->leader == 0) {
        func_80086208(e, 4);
        return;
    }
    ai = &e->ai;
    switch (ai->state) {
    case 1:
        e->ai.state = idle;
        break;
    case 2:
        if (D_8021945C >= ai->timer) {
            Tank *s;
            ai->timer = D_8021945C + 10;
            s = func_80084CC8(e, e->seenBy);
            if (s == 0) s = func_80084CC8(e, e->seen);
            if (s != 0) {
                if (s->owner->team == e->owner->team) {
                    e->ai.state = 3;
                } else {
                    e->ai.state = 4;
                }
                break;
            }
        }
        ai->speed = e->seen != 0 ? 1.0f : 0.2f;
        if (func_800848E8(e) == 0) break;
        l = e->leader;
        if (l != 0) {
{{
            Pt v;

            v.x = l->dir.x;
            v.y = l->dir.y;
            func_8009DB0C(&v, func_8009D8A0(l->spread));
            e->ai.target.x = l->pos.x;
            e->ai.target.y = l->pos.y;
            func_8009E044(&e->ai.target, &v);
}}
        }
        func_800848E8(e);
        break;
    case 3:
        t = func_80084CC8(e, e->seenBy);
        t = t != 0 ? t : func_80084CC8(e, e->seen);
        if (t == 0 || t->owner->team != e->owner->team) {
            e->ai.state = idle;
            break;
        }
        {
        {
        Pt d[2];

        l = e->leader;
        func_8009DA44(&d[0], l, &t->pos);
        dot = d[0].x * l->dir.x + d[0].y * l->dir.y;
        func_8009DA44(&d[1], l, &e->pos);
        if (dot < d[1].x * l->dir.x + d[1].y * l->dir.y) {
            e->ai.target.x = e->ai.home.x;
            e->ai.target.y = e->ai.home.y;
        } else {
            e->ai.target.x = l->pos.x;
            e->ai.target.y = l->pos.y;
        }
        }
        }
        func_800848E8(e);
        break;
    case 4:
        t = func_80084CC8(e, e->seenBy);
        t = t != 0 ? t : func_80084CC8(e, e->seen);
        if (t == 0 || t->owner->team == e->owner->team) {
            e->ai.state = idle;
            break;
        }
        {
#define object e
#define input t
            Pt first;
            Pt second;
            Leader *transform = object->leader;
            float dot;

            func_8009DA44(&first, transform, &input->pos);
            dot = first.x * transform->dir.x + first.y * transform->dir.y;
            func_8009DA44(&second, transform, &object->pos);
            object->ai.target.x = transform->dir.x;
            object->ai.target.y = transform->dir.y;
            func_8009DB0C(&object->ai.target, dot);
            func_8009E044(&object->ai.target, transform);
#undef object
#undef input
        }
        func_800848E8(e);
        break;
    }
}
