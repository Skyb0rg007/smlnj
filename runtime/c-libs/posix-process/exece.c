/*! \file exece.c
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

/* _ml_P_Process_exece : string * string list * string list -> 'a
 *
 * Overlay a new process image, using specified environment.
 */
ml_val_t _ml_P_Process_exece (ml_state_t *msp, ml_val_t arg)
{
    int             sts;
    ml_val_t        path = REC_SEL(arg, 0);
    ml_val_t        arglst = REC_SEL(arg, 1);
    ml_val_t        envlst = REC_SEL(arg, 2);
    char            **argv, **envp;
    ml_val_t        p;
    char            **cp;
    int             nArgs, sts_errno;

  /* count the arguments and the environment entries; the array holds both
   * NIL-terminated vectors.  We allocate it with malloc, since allocating it
   * in the heap might cause a GC, which would invalidate path, arglst, and
   * envlst.
   */
    for (nArgs = 0, p = arglst; p != LIST_nil; p = LIST_tl(p)) {
        nArgs++;
    }
    for (p = envlst; p != LIST_nil; p = LIST_tl(p)) {
        nArgs++;
    }

    cp = (char **)MALLOC((nArgs + 2) * sizeof(char *));
    if (cp == NIL(char **)) {
	return RAISE_ERROR(msp, "no malloc memory");
    }
    argv = cp;
    for (p = arglst;  p != LIST_nil;  p = LIST_tl(p)) {
        *cp++ = STR_MLtoC(LIST_hd(p));
    }
    *cp++ = NIL(char *);  /* terminate the argv[] */

    envp = cp;
    for (p = envlst;  p != LIST_nil;  p = LIST_tl(p)) {
        *cp++ = STR_MLtoC(LIST_hd(p));
    }
    *cp++ = NIL(char *);  /* terminate the envp[] */

    sts = execve(STR_MLtoC(path), argv, envp);

    sts_errno = errno;	/* preserve errno across the FREE */
    FREE (argv);
    errno = sts_errno;

    CHK_RETURN (msp, sts)

} /* end of _ml_P_Process_exece */
