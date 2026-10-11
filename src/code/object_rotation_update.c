/* SPAN 0x800B6CC4 */
/* RODATA_VRAM 0x800730F8 */

typedef unsigned short u16;
typedef signed short s16;
typedef signed int s32;
typedef unsigned int u32;
typedef float f32;
s16 func_8009D850(s32, s32, u16 *);
extern f32 D_80219488;
void func_800B69F4(void *arg0, f32 arg1, s32 arg2, s32 arg3)
{
  u16 sp10;
  f32 temp_f2;
  f32 temp_f2_2;
  f32 temp_f2_3;
  f32 temp_f2_4;
  s32 var_t0;
  s32 var_v1;
  s32 var_v1_2;
  s32 var_v1_3;
  unsigned int temp_v0;
  u16 temp_v1;
  u16 temp_v1_2;
  u16 temp_v1_3;
  u16 temp_v1_4;
  u16 temp_v1_5;
  u32 temp_a0;
  u32 temp_a0_2;
  if ((*((s32 *) (((char *) arg0) + 0x68))) != 0)
  {
    temp_v1 = *((u16 *) (((char *) arg0) + 0x42));
    temp_a0 = temp_v1 & 0xFFFF;
    *((u16 *) (((char *) arg0) + 0x40)) = 0U;
    if (temp_a0 > 0x8000U)
    {
      *((u16 *) (((char *) arg0) + 0x42)) = (u16) (temp_v1 + 0x3C);
    }
    else
      if (!(temp_a0 < 0x3DU))
    {
      *((u16 *) (((char *) arg0) + 0x42)) = (u16) (temp_v1 - 0x3C);
    }
    else
    {
      *((u16 *) (((char *) arg0) + 0x42)) = 0U;
    }
    temp_f2 = (-(arg1 - (*((f32 *) (((char *) arg0) + 0x34))))) * 728.0f;
    if (!(2147483648.0f <= temp_f2))
    {
      var_v1 = (s32) temp_f2;
    }
    else
    {
      var_v1 = ((s32) (temp_f2 - 2147483648.0f)) | 0x80000000;
    }
    *((f32 *) (((char *) arg0) + 0x34)) = arg1;
    *((u16 *) (((char *) arg0) + 0x42)) = (u16) ((*((u16 *) (((char *) arg0) + 0x42))) + var_v1);
    return;
  }
  temp_v1_2 = *((u16 *) (((char *) arg0) + 0x42));
  if (temp_v1_2 != 0)
  {
    if (temp_v1_2 > 0x8000U)
    {
      temp_f2_2 = D_80219488 * 728.0f;
      if (!(2147483648.0f <= temp_f2_2))
      {
        var_v1_2 = (s32) temp_f2_2;
      }
      else
      {
        var_v1_2 = ((s32) (temp_f2_2 - 2147483648.0f)) | 0x80000000;
      }
      temp_v0 = (*((u16 *) (((char *) arg0) + 0x42))) + var_v1_2;
      *((u16 *) (((char *) arg0) + 0x42)) = temp_v0;
      if (!((temp_v0 >> 0xF) & 1))
      {
        *((u16 *) (((char *) arg0) + 0x42)) = 0U;
      }
    }
    else
    {
      temp_f2_3 = D_80219488 * 728.0f;
      if (!(2147483648.0f <= temp_f2_3))
      {
        var_t0 = (s32) temp_f2_3;
      }
      else
      {
        var_t0 = (s32) (temp_f2_3 - 2147483648.0f);
        var_t0 |= 0x80000000;
      }
      temp_v1_3 = (*((u16 *) (((char *) arg0) + 0x42))) - var_t0;
      *((u16 *) (((char *) arg0) + 0x42)) = temp_v1_3;
      if (((u32) (temp_v1_3 & 0xFFFF)) > 0x8000U)
      {
        *((u16 *) (((char *) arg0) + 0x42)) = 0U;
        goto block_29;
      }
    }
  }
  else
  {
    block_29:

  }
  if (func_8009D850(arg2 & 0xFFFF, arg3 & 0xFFFF, &sp10) < 0)
  {
    *((u16 *) (((char *) arg0) + 0x42)) =
        *((u16 *) (((char *) arg0) + 0x42)) - sp10;
  }
  else
  {
    *((u16 *) (((char *) arg0) + 0x42)) =
        *((u16 *) (((char *) arg0) + 0x42)) + sp10;
  }
  temp_v1_4 = *((u16 *) (((char *) arg0) + 0x42));
  if (temp_v1_4 > 0x8000U)
  {
    if (temp_v1_4 <= 0xFB04U)
      *((u16 *) (((char *) arg0) + 0x42)) = 0xFB05U;
  }
  else if (temp_v1_4 >= 0x71DU)
  {
    *((u16 *) (((char *) arg0) + 0x42)) = 0x71CU;
  }
  temp_v1_5 = *((u16 *) (((char *) arg0) + 0x40));
  {
    __typeof__(temp_v1_5) ct4 = temp_v1_5;
    temp_a0_2 = ct4 & 0xFFFF;
  }
  if (temp_a0_2 > 0x8000U)
  {
    *((u16 *) (((char *) arg0) + 0x40)) = (u16) (temp_v1_5 + 0x3C);
  }
  else
    if (!(temp_a0_2 < 0x3DU))
  {
    *((u16 *) (((char *) arg0) + 0x40)) = (u16) (temp_v1_5 - 0x3C);
  }
  else
  {
    *((u16 *) (((char *) arg0) + 0x40)) = 0U;
  }
  temp_f2_4 = (-(arg1 - (*((f32 *) (((char *) arg0) + 0x34))))) * 728.0f;
  if (!(2147483648.0f <= temp_f2_4))
  {
    var_v1_3 = (s32) temp_f2_4;
  }
  else
  {
    var_v1_3 = ((s32) (temp_f2_4 - 2147483648.0f)) | 0x80000000;
  }
  *((f32 *) (((char *) arg0) + 0x34)) = arg1;
  *((u16 *) (((char *) arg0) + 0x40)) = (u16) ((*((u16 *) (((char *) arg0) + 0x40))) + var_v1_3);
}
