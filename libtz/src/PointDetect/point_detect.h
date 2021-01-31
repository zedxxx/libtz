#ifndef POINT_DETECT_H
#define POINT_DETECT_H

#include <stdint.h>
#include <stdbool.h>

typedef struct {
    int16_t x, y;
} point16_t;

typedef struct {
    point16_t min, max;
} rect16_t;

typedef struct {
    int x, y;
} point32_t;

typedef struct {
    point32_t min, max;
} rect32_t;

bool is_point_in_rect_16(const point16_t p, const rect16_t *r);
bool is_point_in_poly_16(const point16_t p, int count, point16_t *pp);

bool is_point_in_rect_32(const point32_t p, const rect32_t *r);
bool is_point_in_poly_32(const point32_t p, int count, point32_t *pp);

#endif //POINT_DETECT_H
