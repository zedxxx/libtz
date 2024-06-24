#include <stdint.h>
#include <stdbool.h>

#ifdef SMALL_INT
typedef int16_t POINT_INT;
#else
typedef int32_t POINT_INT;
#endif

typedef struct {
    POINT_INT x, y;
} point_t;

typedef struct {
    point_t min, max;
} rect_t;

#ifdef SMALL_INT
bool is_point_in_rect_16(const point_t p, const rect_t *r)
#else
bool is_point_in_rect_32(const point_t p, const rect_t *r)
#endif
{
    return (p.x <= r->max.x) && (p.x >= r->min.x) && (p.y <= r->max.y) && (p.y >= r->min.y);
}

#ifdef SMALL_INT
bool is_point_in_poly_16(const point_t p, const int count, const point_t *pp)
#else
bool is_point_in_poly_32(const point_t p, const int count, const point_t *pp)
#endif
{
    bool result = false;

    const point_t *p1 = pp;
    const point_t *p2 = pp + 1;

    for (int i = 1; i < count; ++i) {
        if ( ((p2->y <= p.y) && (p.y < p1->y)) || ((p1->y <= p.y) && (p.y < p2->y)) ) {
            if ( p.x > p2->x + (p1->x - p2->x) * (p.y - p2->y) / (double)(p1->y - p2->y) ) {
                result = !result;
            }
        }
        p1 = p2++;
    }

    return result;
}
