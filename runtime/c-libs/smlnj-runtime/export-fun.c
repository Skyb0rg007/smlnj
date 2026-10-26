/*! \file export-fun.c
 *
 * COPYRIGHT (c) 2019 The Fellowship of SML/NJ (https://smlnj.org)
 * All rights reserved.
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


/* _ml_RunT_export_fun : (string * ((string * string list) -> int)) -> unit
 *
 * Export the given ML function.
 */
ml_val_t _ml_RunT_export_fun (ml_state_t *msp, ml_val_t arg)
{
    char	*fname;
    ml_val_t	mlName = REC_SEL(arg, 0);
    ml_val_t	funct = REC_SEL(arg, 1);
    FILE	*file;
    int		sts;

  /* allocate space for the name plus the image suffix that might be added */
    fname = MALLOC(strlen(STR_MLtoC(mlName)) + sizeof("." MACHINE_ID "-" OPSYS_ID));
    if (fname == NIL(char *))
	return RAISE_ERROR(msp, "no malloc memory");
    QualifyImageName (strcpy(fname, STR_MLtoC(mlName)));

    file = fopen(fname, "wb");
    FREE (fname);
    if (file == NULL)
	return RAISE_ERROR(msp, "unable to open file for writing");

    sts = ExportFnImage (msp, funct, file);
    fclose (file);

    if (sts == SUCCESS) {
	Exit (0);
    }
    else {
	Die ("export failed");
    }
/* NOTE: while it would be nice to raise a SysErr exception here, the ML state
 * has been trashed as a side-effect of the export operation.
	return RAISE_ERROR(msp, "export failed");
 */

} /* end of _ml_RunT_export_fun */
