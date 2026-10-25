/*! \file utime.c
 *
 * COPYRIGHT (c) 2019 The Fellowship of SML/NJ (https://smlnj.org)
 * All rights reserved.
 */

#include "ml-unixdep.h"
#include <sys/types.h>
#include <sys/time.h>
#include "ml-base.h"
#include "ml-values.h"
#include "ml-objects.h"
#include "ml-c.h"
#include "cfun-proto-list.h"

/* FIXME: utimensat is the newest way to implement this mechanism */

/* convert a nanosecond count to a struct timeval.  The count is the
 * two's-complement encoding of a signed value (times before the epoch
 * are negative), so we must use signed arithmetic and make sure that
 * the microseconds field is non-negative.
 */
STATIC_INLINE void ns_to_timeval (Unsigned64_t ns, struct timeval *tv)
{
    Int64_t us = (Int64_t)ns / 1000;		/* convert to microseconds */
    Int64_t usec = us % 1000000;

    if (usec < 0) {
	usec += 1000000;
	us -= 1000000;
    }
    tv->tv_sec = us / 1000000;
    tv->tv_usec = usec;
}

/* _ml_P_FileSys_utime : (string * Word64.word * Word64.word) -> unit
 *                        name     actime(ns)    modtime(ns)
 *
 * Sets file access and modification times. If
 * actime = -1, then set both to current time.
 */
ml_val_t _ml_P_FileSys_utime (ml_state_t *msp, ml_val_t arg)
{
    ml_val_t		path = REC_SEL(arg, 0);
    Unsigned64_t	actime = WORD64_MLtoC(REC_SEL(arg, 1));
    Unsigned64_t	modtime = WORD64_MLtoC(REC_SEL(arg, 2));
    int			sts;

    if (actime == 0xffffffffffffffff) {
	sts = utimes (STR_MLtoC(path), NIL(struct timeval *));
    }
    else {
        struct timeval	times[2];
	ns_to_timeval (actime, &times[0]);
	ns_to_timeval (modtime, &times[1]);
	sts = utimes (STR_MLtoC(path), times);
    }

    CHK_RETURN_UNIT(msp, sts)

} /* end of _ml_P_FileSys_utime */
