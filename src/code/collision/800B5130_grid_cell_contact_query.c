/* SPAN 0x800B5130..0x800B5728 */
typedef unsigned char u8;
typedef short s16;
typedef unsigned short u16;
typedef unsigned int u32;
typedef struct
{
  int unk0;
  int unk4;
  u16 link[4];
  s16 x;
  s16 z;
  s16 y;
  s16 dx0;
  s16 dx1;
  s16 dz0;
  s16 dz1;
  u16 unk1E;
  u16 unk20;
  s16 radius;
  u16 unk24;
  u16 grid;
} GridNode;
typedef struct
{
  s16 x0;
  s16 z0;
  u16 w;
  u16 h;
  u16 cw;
  u16 ch;
  u16 *cells;
  float scale;
  void *tbl;
} Grid;
typedef struct
{
  float x;
  float y;
} Vec2;
typedef struct
{
  int data;
  u16 id;
  float x;
  float z;
  float y;
  Vec2 push;
  float unk1C;
  s16 side;
} Contact;
extern GridNode D_803978E0[];
extern Grid D_803977F0[];
extern u16 D_801166F0;
extern u16 D_80397658[];
extern u16 D_801166E0[4];
extern u16 D_801166E8[4];
u16 func_800B2890(s16 x, s16 z, u16 id);
inline extern void func_800B0B8C(u16 id)
{
  GridNode *n = &D_803978E0[id];
  n->grid |= 0x1000;
  D_80397658[D_801166F0] = id;
  D_801166F0++;
}

inline extern void func_800B0BE0(void)
{
  u16 i;
  for (i = 0; i < D_801166F0; i++)
  {
    (&D_803978E0[(&D_80397658[i])[0]])->grid &= ~0x1000;
  }

  D_801166F0 = 0;
}

inline static int collect(Vec2 *p, int layer, u16 head, u16 dir, int mask, Contact *out, u16 base, u16 single)
{
  GridNode *n;
  Contact *c;
  u16 count = 0;
  u16 i;
  u16 current = head;
  int targetLayer;
  if (current != 0xFFFF)
  {
    do
    {
      n = &D_803978E0[current];
      targetLayer = layer & 0xFFFF;
      if ((targetLayer == n->grid) && (n->unk0 & mask))
      {
        if (func_800B2890((s16) p->x, (s16) p->y, current))
        {
          c = out;
          for (i = 0; i < (base + count); i++, c++)
          {
            if (current == c->id)
            {
              break;
            }
          }

          if (i >= (base + count))
          {
            c->data = n->unk4;
            c->id = current;
            count++;
            if (single)
            {
              break;
            }
            if ((base + count) >= 32)
            {
              break;
            }
          }
        }
        if (dir != 3)
        {
          func_800B0B8C(current);
        }
      }
      current = n->link[dir];
      if (current == 0xFFFF)
      {
        break;
      }
    }
    while (1);
  }
  return count;
}

u16 func_800B5130(Vec2 *point, int mask, int layer, Contact *out, u16 single)
{
  Grid *g = &D_803977F0[layer & 0xFFFF];
  Vec2 local;
  u16 count;
  u16 found;
  int i;
  Contact *list;
  local.x = point->x - g->x0;
  local.y = point->y - g->z0;
  list = out;
  count = collect(&local, layer, g->cells[0], 0, mask, list, 0, single);
  if (single && count)
  {
    func_800B0BE0();
    return count;
  }
  for (i = 0; ((u16) i) < 4; i++)
  {
    u16 dir = i;
    Contact *c;
    __typeof__(dir) au13 = dir;
    found = 0;
    {
      GridNode *n;
      u16 got = 0;
      u16 k;
      u16 current = g->cells[1 + ((u16) ((((s16) (local.x + D_801166E0[dir])) >> 10) + (((((s16) (local.y + D_801166E8[dir])) >> 10) + (i * g->ch)) * g->cw)))];
      int targetLayer = layer & 0xFFFF;
      if (current != 0xFFFF)
      {
        do
        {
          n = &D_803978E0[current];
          if ((targetLayer == n->grid) && (n->unk0 & mask))
          {
            if (func_800B2890((s16) point->x, (s16) point->y, current))
            {
              c = list;
              for (k = 0; k < (count + got); k++, c++)
              {
                if (current == c->id)
                {
                  break;
                }
              }

              if (k >= (count + got))
              {
                c->data = n->unk4;
                c->id = current;
                got++;
                if (single)
                {
                  break;
                }
                if ((count + got) >= 32)
                {
                  break;
                }
              }
            }
            if (au13 != 3)
            {
              func_800B0B8C(current);
            }
          }
          current = n->link[au13];
          if (current == 0xFFFF)
          {
            break;
          }
        }
        while (1);
      }
      found = got;
    }
    if (found)
    {
      count += found;
      if (single || (count >= 32))
      {
        func_800B0BE0();
        return count;
      }
    }
  }

  func_800B0BE0();
  return count;
}
