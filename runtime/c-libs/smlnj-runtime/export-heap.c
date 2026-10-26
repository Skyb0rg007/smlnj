/* export-heap.c
 *
 * COPYRIGHT (c) 1995 by AT&T Bell Laboratories.
 */

#include "ml-osdep.h"
#include <stdio.h>
#include <string.h>
#include "ml-base.h"
#include "machine-id.h"
#include "ml-values.h"
#include "ml-state.h"
#include "heap-io.h"
#include "ml-c.h"
#include "cfun-proto-list.h"


/* _ml_RunT_export_heap : string -> bool
 *
 * Export the world to the given file and return false (the exported version
 * returns true).
 */
ml_val_t _ml_RunT_export_heap (ml_state_t *msp, ml_val_t arg)
{
    char	*fname;
    FILE	*file;
    int		sts;

  /* allocate space for the name plus the image suffix that might be added */
    fname = MALLOC(strlen(STR_MLtoC(arg)) + sizeof("." MACHINE_ID "-" OPSYS_ID));
    if (fname == NIL(char *))
	return RAISE_ERROR(msp, "no malloc memory");
    QualifyImageName (strcpy(fname, STR_MLtoC(arg)));

    file = fopen(fname, "wb");
    FREE (fname);
    if (file == NULL)
	return RAISE_ERROR(msp, "unable to open file for writing");

    msp->ml_arg = ML_true;
    sts = ExportHeapImage (msp, file);
    fclose (file);

    if (sts == SUCCESS)
	return ML_false;
    else
	return RAISE_ERROR(msp, "export failed");

} /* end of _ml_RunT_export_heap */

