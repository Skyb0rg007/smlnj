/* record-ops.c
 *
 * COPYRIGHT (c) 1998 Bell Labs, Lucent Technologies.
 *
 * Some (type unsafe) operations on records.
 */


#include "ml-base.h"
#include "ml-values.h"
#include "ml-state.h"
#include "ml-objects.h"
#include "ml-limits.h"
#include "arena-id.h"
#include "heap.h"
#include "gc.h"


/* GetLen:
 *
 * Check that we really have a record object, and return its length.
 */
PVT int GetLen (ml_val_t r)
{
    ml_val_t	d;
    int		t;

    if (! isBOXED(r))
	return -1;

    switch (EXTRACT_OBJC(ADDR_TO_PAGEID(BIBOP, r))) {
      case OBJC_new:
	d = OBJ_DESC(r);
	t = GET_TAG(d);
	if (t == DTAG_record)
	    return GET_LEN(d);
	else
	    return -1;
      case OBJC_pair: return 2;
      case OBJC_record:
	d = OBJ_DESC(r);
	t = GET_TAG(d);
	if (t == DTAG_record)
	    return GET_LEN(d);
	else
	    return -1;
      default:
	return -1;
    }

}

/* RecordConcat:
 *
 * Concatenate two records; returns unit if either argument is not
 * a record of length at least one.
 */
ml_val_t RecordConcat (ml_state_t *msp, ml_val_t r1, ml_val_t r2)
{
    int		l1 = GetLen(r1);
    int		l2 = GetLen(r2);

    if ((l1 > 0) && (l2 > 0)) {
	int		n = l1+l2;
	int		i;
	ml_val_t	*p, *q, res;
	Word_t		szb = WORD_SZB*(n + 1);

	if (n > SMALL_OBJ_SZW) {
	  /* Since we want to avoid pointers from the 1st generation record space
	   * into the allocation space, we need to do a GC (and preserve r1 and r2)
	   * before allocating the result in the first generation.
	   */
	    arena_t	*ap = msp->ml_heap->gen[0]->arena[RECORD_INDX];
	    int		gcLevel = 0;

	    if (! isACTIVE(ap)
	    || (AVAIL_SPACE(ap) <= szb+msp->ml_heap->allocSzB))
		gcLevel = 1;
	    ap->reqSizeB += szb;
	    InvokeGCWithRoots (msp, gcLevel, &r1, &r2, NIL(ml_val_t *));
	    ap->reqSizeB = 0;
	    ASSERT(ap->nextw == ap->sweep_nextw);
	    *(ap->nextw++) = MAKE_DESC(n, DTAG_record);
	    res = PTR_CtoML(ap->nextw);
	    ap->nextw += n;
	    ap->sweep_nextw = ap->nextw;
	    CNTR_INCR(&msp->ml_heap->numAlloc1, szb);
	}
	else {
	    if (NeedGC (msp, szb))
		InvokeGCWithRoots (msp, 0, &r1, &r2, NIL(ml_val_t *));
	    ML_AllocWrite (msp, 0, MAKE_DESC(n, DTAG_record));
	    res = ML_Alloc(msp, n);
	}

	q = PTR_MLtoC(ml_val_t, res);
	for (i = 0, p = PTR_MLtoC(ml_val_t, r1);  i < l1;  i++) {
	    *q++ = p[i];
	}
	for (i = 0, p = PTR_MLtoC(ml_val_t, r2);  i < l2;  i++) {
	    *q++ = p[i];
	}
	return res;
    }
    else {
	return ML_unit;
    }

} /* end of RecordConcat */

