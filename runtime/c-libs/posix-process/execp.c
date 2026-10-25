/*! \file execp.c
 *
 * COPYRIGHT (c) 2026 The Fellowship of SML/NJ (https://smlnj.org)
 * All rights reserved.
 */

#include "ml-base.h"
#include "ml-values.h"
#include "ml-objects.h"
#include "ml-c.h"
#include "cfun-proto-list.h"
#include <unistd.h>
#include <errno.h>

/* _ml_P_Process_execp : string * string list -> 'a
 *
 * Overlay a new process image; resolve file to pathname using PATH
 */
ml_val_t _ml_P_Process_execp (ml_state_t *msp, ml_val_t arg)
{
    int             sts;
    ml_val_t        file = REC_SEL(arg, 0);
    ml_val_t        arglst = REC_SEL(arg, 1);
    char            **argv;
    ml_val_t        p;
    char            **cp;
    int             nArgs, sts_errno;

    for (nArgs = 0, p = arglst; p != LIST_nil; p = LIST_tl(p)) {
        nArgs++;
    }

  /* we allocate the argument vector with malloc, since allocating it in the
   * heap might cause a GC, which would invalidate the ML values that we hold
   * in C variables.
   */
    cp = (char **)MALLOC((nArgs + 1) * sizeof(char *));
    if (cp == NIL(char **)) {
	return RAISE_ERROR(msp, "no malloc memory");
    }
    argv = cp;
    for (p = arglst;  p != LIST_nil;  p = LIST_tl(p)) {
        *cp++ = STR_MLtoC(LIST_hd(p));
    }
    *cp++ = NIL(char *);  /* terminate the argv[] */

    sts = execvp(STR_MLtoC(file), argv);

    sts_errno = errno;	/* preserve errno across the FREE */
    FREE (argv);
    errno = sts_errno;

    CHK_RETURN (msp, sts)

} /* end of _ml_P_Process_execp */
