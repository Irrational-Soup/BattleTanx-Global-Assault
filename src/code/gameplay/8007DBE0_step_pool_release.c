
typedef signed char s8;
typedef unsigned char u8;
typedef signed short s16;
typedef unsigned short u16;
typedef signed int s32;
typedef unsigned int u32;
typedef signed long long s64;
typedef unsigned long long u64;
typedef float f32;
typedef double f64;
typedef char static_assert_s8[((sizeof(s8)) == 1) ? (1) : (-1)];
typedef char static_assert_s16[((sizeof(s16)) == 2) ? (1) : (-1)];
typedef char static_assert_s32[((sizeof(s32)) == 4) ? (1) : (-1)];
typedef char static_assert_s64[((sizeof(s64)) == 8) ? (1) : (-1)];
typedef struct StepDBE0 StepDBE0;
struct StepDBE0
{
  u8 kind;
  u8 pad1;
  u16 child;
  StepDBE0 *next_free;
  u16 index;
  u16 padA;
  u16 link_c;
  u16 link_e;
  u8 pad10[6];
  u16 link_16;
};
typedef struct 
{
  StepDBE0 nodes[0x800];
  StepDBE0 *freelist;
} PoolDBE0;
extern PoolDBE0 *D_80114680;
inline static s32 kind_below_limit(s32 value, s32 limit)
{
  return value < limit;
}

s32 func_8007DBE0(u16 *head)
{
  StepDBE0 *step;
  StepDBE0 *pool;
  u16 index;
  u16 next;
  s32 done;
  s32 count;
  s32 kind_three;
  s32 kind_two;
  s32 kind_limit;
  s32 free_kind;
  u8 kind;
  index = *head;
  count = 0;
  if (index == 0)
  {
    return 0;
  }
  kind_three = 3;
  kind_two = 2;
  kind_limit = 4;
  *head = 0;
  step = &D_80114680->nodes[index];
  step->child = 0;
  free_kind = 1;
  find_leaf:
  done = 0;

  pool = D_80114680->nodes;
  do
  {
    kind = step->kind;
    if (kind == kind_three)
    {
      goto kind_three_case;
    }
    if (!kind_below_limit(kind, kind_limit))
    {
      goto stop_walk;
    }
    if (kind == kind_two)
    {
      goto kind_two_case;
    }
    goto stop_walk;
    stop_walk:
    done = 1;

    goto walk_bottom;
    kind_three_case:
    next = step->link_16;

    goto check_next;
    kind_two_case:
    next = step->link_e;

    if (next == 0)
    {
      next = step->link_c;
    }
    else
    {
      index = next;
      step = &pool[next];
      goto walk_bottom;
    }
    check_next:
    if (next != 0)
    {
      index = next;
      step = &pool[next];
    }
    else
    {
      done = 1;
    }

    walk_bottom:
    ;

  }
  while (done == 0);
  release_leaf:
  next = step->child;

  if (index == 0)
  {
    step = 0;
  }
  else
  {
    step = &D_80114680->nodes[index];
  }
  step->next_free = D_80114680->freelist;
  D_80114680->freelist = step;
  step->index = index;
  step->kind = free_kind;
  count++;
  if (next != 0)
  {
    step = &D_80114680->nodes[next];
    if (step->kind == kind_three)
    {
      index = next;
      goto release_leaf;
    }
    if (step->link_e == index)
    {
      step->link_e = 0;
    }
    else
    {
      step->link_c = 0;
    }
    index = next;
  }
  if (next != 0)
  {
    goto find_leaf;
  }
  return (u16) count;
}

