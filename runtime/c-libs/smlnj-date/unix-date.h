/*! \file unix-date.h
 *
 * COPYRIGHT (c) 2019 The Fellowship of SML/NJ (https://smlnj.org)
 * All rights reserved.
 *
 * Common definitions for UNIX versions of the Date functions.
 */

#ifndef _UNIX_DATE_H_
#define _UNIX_DATE_H_

#include <time.h>

/* convert time_t value (in seconds) to 64-bit unsigned nanoseconds */
STATIC_INLINE Unsigned64_t time_to_ns (time_t t)
{
    return NS_PER_SEC * (Unsigned64_t)t;
}

/* convert a 64-bit nanosecond count to a time_t value (in seconds).
 *
 * NOTE: although the value arrives from the ML side as a `Word64.word`, it is
 * the two's-complement encoding of a *signed* nanosecond count (`Time.time` is
 * signed and covers roughly +/- 292 years around the epoch), so the division
 * must be a signed one.  Dividing it as unsigned turns every pre-1970 time
 * into a nonsensical far-future one.
 */
STATIC_INLINE time_t ns_to_time (Unsigned64_t ns)
{
    return (time_t)((Int64_t)ns / (Int64_t)NS_PER_SEC);
}

/* allocate a 9-tuple for a `struct tm` value */
ml_val_t _ml_alloc_tm (ml_state_t *msp, const struct tm *tm);

#endif /* _UNIX_DATE_H_ */
