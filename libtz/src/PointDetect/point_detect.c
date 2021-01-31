#include "point_detect.h"

#include <stdbool.h>

bool is_point_in_rect_16(const point16_t p, const rect16_t *r)
{
    return (p.x <= r->max.x) && (p.x >= r->min.x) && (p.y <= r->max.y) && (p.y >= r->min.y);
}

bool is_point_in_poly_16(const point16_t p, int count, point16_t *pp)
{
    bool result = false;

    point16_t *p1 = pp;
    point16_t *p2 = pp + 1;

    for (int i = 1; i < count; ++i) {
        if ( (p2->y <= p.y) && (p.y < p1->y) || (p1->y <= p.y) && (p.y < p2->y) ) {
            if ( p.x > p2->x + (p1->x - p2->x) * (p.y - p2->y) / (double)(p1->y - p2->y) ) {
                result = !result;
            }
        }
        p1 = p2++;
    }

    return result;
}

/*****************************************************************************/

bool is_point_in_rect_32(const point32_t p, const rect32_t *r)
{
    return (p.x <= r->max.x) && (p.x >= r->min.x) && (p.y <= r->max.y) && (p.y >= r->min.y);
}

bool is_point_in_poly_32(const point32_t p, int count, point32_t *pp)
{
    bool result = false;

    point32_t *p1 = pp;
    point32_t *p2 = pp + 1;

    for (int i = 1; i < count; ++i) {
        if ( (p2->y <= p.y) && (p.y < p1->y) || (p1->y <= p.y) && (p.y < p2->y) ) {
            if ( p.x > p2->x + (p1->x - p2->x) * (p.y - p2->y) / (double)(p1->y - p2->y) ) {
                result = !result;
            }
        }
        p1 = p2++;
    }

    return result;
}
