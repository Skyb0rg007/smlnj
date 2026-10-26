/* from-unixaddr.c
 *
 * COPYRIGHT (c) 1996 AT&T Research.
 */

#include <stddef.h>
#include <string.h>
#include "ml-unixdep.h"
#include "sockets-osdep.h"
#include INCLUDE_TYPES_H
#include INCLUDE_SOCKET_H
#include INCLUDE_UN_H
#include "ml-base.h"
#include "ml-values.h"
#include "ml-objects.h"
#include "cfun-proto-list.h"


/* _ml_Sock_fromunixaddr : addr -> string
 *
 * Given a UNIX-domain socket address, return the string.
 */
ml_val_t _ml_Sock_fromunixaddr (ml_state_t *msp, ml_val_t arg)
{
    struct sockaddr_un	*addr = GET_SEQ_DATAPTR(struct sockaddr_un, arg);
    int			len = GET_SEQ_LEN(arg) - offsetof(struct sockaddr_un, sun_path);
    char		path[sizeof(addr->sun_path) + 1];

    ASSERT(addr->sun_family == AF_UNIX);

  /* the path need not be 0 terminated, and it is missing altogether from
   * the address of an unnamed socket, so we use the length of the address.
   */
    if (len < 0)
	len = 0;
    else if (len > sizeof(addr->sun_path))
	len = sizeof(addr->sun_path);
    memcpy (path, addr->sun_path, len);
    path[len] = '\0';

    return ML_CString(msp, path);

} /* end of _ml_Sock_fromunixaddr */

