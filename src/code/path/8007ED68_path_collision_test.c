/* SPAN 0x8007ED68 */
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
typedef s32 M2C_UNK;
typedef s8 M2C_UNK8;
typedef s16 M2C_UNK16;
typedef s32 M2C_UNK32;
typedef s64 M2C_UNK64;
M2C_UNK func_8007D500(M2C_UNK *, u8, void *);
M2C_UNK func_8007D558(void *, s32 **);
s32 func_8007D588(M2C_UNK *, M2C_UNK *);
M2C_UNK func_8007D5B0(M2C_UNK *, f32, M2C_UNK *, M2C_UNK *);
s32 func_8007D628(M2C_UNK *, void *, M2C_UNK *);
s32 func_8007D69C(void *, M2C_UNK);
s16 func_8007D884(void **, M2C_UNK);
void *func_8007DA5C(u16);
M2C_UNK func_8007DBE0(void *);
M2C_UNK func_8007E118(void *, M2C_UNK *);
M2C_UNK func_8009E068(void *, M2C_UNK *, f32);
s32 func_800B49E0(f32 *, M2C_UNK *, M2C_UNK, u8, s32, s32, s32 **);
extern f32 D_80071120;
extern s16 D_80397650;
typedef struct
{
  f32 x;
  f32 y;
} Pt;
typedef struct
{
  void *p;
  u32 pad;
} PtrBox;
typedef struct
{
  void *obj;
  u32 pad04;
  f32 x;
  f32 y;
  char p10[0x20 - 0x10];
  u16 code;
  char p22[6];
} Hit;
typedef struct {
  Pt sp20;
  Pt sp28;
  Pt sp30;
  PtrBox sp38;
  Pt sp40;
  Hit hit;
  Pt tail;
} PathWork;
static inline void *node_pos(void *base, void *node)
{
  for (;;)
  {
    if (node == 0) return base + 0x110;
    if (*((u8 *)node) == 3) return node + 4;
    node = func_8007DA5C(*((u16 *) (((s8 *)node) + 2)));
  }
}
s32 func_8007ED68(void *arg0, s16 arg1, s32 arg2)
{
  PathWork work;
#define sp20 work.sp20
#define sp28 work.sp28
#define sp30 work.sp30
#define sp38 work.sp38
#define sp40 work.sp40
#define hit work.hit
#define sp70 work.tail.x
#define sp74 work.tail.y
  M2C_UNK *var_a0_3;
  M2C_UNK *var_s2_2;
  M2C_UNK *var_s4;
  s16 temp_s7;
  s32 temp_a2;
  s32 temp_s6;
  s32 temp_v1;
  s32 var_s2;
  s32 keep_s5;
  s16 var_s5;
  s32 var_v0;
  s32 var_v0_2;
  s8 var_v0_3;
  u8 temp_s0_2;
  u16 probe_type;
  s32 probe_flags;
  u8 var_v0_4;
  void *temp_s0;
  void *temp_s3;
  void *temp_v0;
  void *temp_v0_2;
  void *var_a0;
  void *var_a0_2;
  void *tail_node;
  temp_a2 = arg2 == 1;
  temp_s6 = temp_a2 | (arg2 == 0x11);
  temp_s3 = arg0 + 0xF0;
  temp_s7 = func_8007D884(&sp38, 3);
  if (sp38.p == 0)
  {
    return 0;
  }
  temp_v0 = func_8007DA5C(arg1 & 0xFFFF);
  var_s4 = node_pos(arg0, temp_v0);
  func_8007E118(temp_v0, &sp20);
  func_8007D5B0(&sp20, *((f32 *) (((s8 *) temp_s3) + 0x34)), &sp28, &sp30);
  if ((*((u8 *) (((s8 *) temp_v0) + 0))) == 2)
  {
    if (temp_s6 != 0)
    {
      *((s16 *) (((s8 *) temp_v0) + 0xC)) = temp_s7;
    }
    else
    {
      *((s16 *) (((s8 *) temp_v0) + 0xE)) = temp_s7;
    }
    *((s16 *) (((s8 *) sp38.p) + 2)) = arg1;
    keep_s5 = 1;
    *((u16 *) (((s8 *) temp_s3) + 6)) = (u16) ((*((u16 *) (((s8 *) temp_s3) + 6))) + 1);
  }
  else
  {
    { void *created = sp38.p;
    *((s16 *) (((s8 *) temp_v0) + 0x16)) = temp_s7;
    *((s16 *) (((s8 *) created) + 2)) = arg1; }
    *((u16 *) (((s8 *) temp_s3) + 6)) = (u16) ((*((u16 *) (((s8 *) temp_s3) + 6))) + 1);
    temp_v0_2 = func_8007DA5C(*((u16 *) (((s8 *) temp_v0) + 2)));
    func_8007E118(temp_v0_2, &sp40);
    var_a0_2 = temp_v0_2;
    if (func_8007D588(&sp20, &sp40) != 0)
    {
      var_a0_3 = node_pos(arg0, var_a0_2);

      temp_s0 = temp_s3 + 0x28;
      if (temp_s6 != 0)
      {
        var_s2 = func_8007D628(var_a0_3, temp_s0, var_s4) == 2;
        var_v0_2 = func_8007D628(var_s4, temp_s0, &sp30) == 1;
      }
      else
      {
        var_s2 = func_8007D628(var_a0_3, temp_s0, var_s4) == 1;
        var_v0_2 = func_8007D628(var_s4, temp_s0, &sp28) == 2;
      }
      var_s5 = (var_s2 & var_v0_2) == 0;
      keep_s5 = var_s5;
    }
    else
    {
      var_s5 = 1;
      keep_s5 = var_s5;
    }
  }
  var_s2_2 = temp_s3 + 0x28;
  if (keep_s5 != 0)
  {
    var_s2_2 = &sp30;
    if (temp_s6 == 0)
    {
      var_s2_2 = &sp28;
    }
  }
  { f32 x = *((f32 *) (((s8 *) var_s4) + 0)); f32 y = *((f32 *) (((s8 *) var_s4) + 4)); sp70 = x; sp74 = y; }
  temp_s0_2 = *((u8 *) (((s8 *) arg0) + 0x94));
  probe_type = func_8007D69C(arg0, 0);
  probe_flags = *((s32 *)arg0);
  D_80397650 = 0;
  if ((func_800B49E0(&sp70, var_s2_2, 0x87007, temp_s0_2, probe_type, probe_flags, (s32 **) (&hit)) & 0xFFFF) && ((((temp_v1 = *((s32 *) (((s8 *) temp_s3) + 0x30)), temp_v1 == 0)) || (hit.obj == 0)) || (temp_v1 != (*((s32 *) hit.obj)))))
  {
    if (hit.code == 7)
    {
      *((s32 *) (((s8 *) temp_s3) + 0x1C)) = 1;
      *((s16 *) (((s8 *) arg0) + 0x132)) = 0;
      func_8007DBE0(arg0 + 0xF4);
      *((s16 *) (((s8 *) arg0) + 0xF6)) = 0;
      *((s32 *) (((s8 *) arg0) + 0xF0)) = 0;
      *((s16 *) (((s8 *) arg0) + 0xFA)) = 0;
      *((s16 *) (((s8 *) arg0) + 0x104)) = 0;
      *((s16 *) (((s8 *) arg0) + 0x106)) = 0;
      *((s32 *) (((s8 *) arg0) + 0x108)) = 0;
      return 0;
    }
    { void *hit_node = sp38.p;
    *((f32 *) (((s8 *) hit_node) + 4)) = hit.x;
    *((f32 *) (((s8 *) hit_node) + 8)) = hit.y; }
    func_8009E068(sp38.p + 4, var_s4, ((*((f32 *) (((s8 *) temp_s3) + 0x34))) + D_80071120) - ((f32) (func_8007D69C(arg0, 0) & 0xFFFF)));
    func_8007D558(sp38.p + 0xC, (s32 **) (&hit));
    var_v0 = temp_s7 & 0xFFFF;
    if (keep_s5 != 0)
    {
      tail_node = sp38.p;
      var_v0_3 = 0x11;
      if (temp_s6 == 0)
      {
        var_v0_3 = 0x12;
      }
      goto block_43;
    }
    goto return_id;
  }
  tail_node = sp38.p;
  temp_v0 = tail_node;
  *((f32 *) (((s8 *) temp_v0) + 4)) = (f32) (*((f32 *) (((s8 *) var_s2_2) + 0)));
  *((f32 *) (((s8 *) temp_v0) + 8)) = (f32) (*((f32 *) (((s8 *) var_s2_2) + 4)));
  if (keep_s5 != 0)
  {
    var_v0_4 = 1;
    if (temp_s6 == 0)
    {
      var_v0_4 = 2;
    }
    *((u8 *) (((s8 *) temp_v0) + 0x14)) = var_v0_4;
    func_8007D500(&sp20, *((u8 *) (((s8 *) sp38.p) + 0x14)), sp38.p + 0xC);
    goto return_id;
  }
  var_v0_3 = 3;
  block_43:
  *((s8 *) (((s8 *) tail_node) + 0x14)) = var_v0_3;

return_id:
  var_v0 = temp_s7 & 0xFFFF;
  return var_v0;
}
