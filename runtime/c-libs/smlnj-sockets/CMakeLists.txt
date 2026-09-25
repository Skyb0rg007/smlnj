# CMake configuration for the smlnj-sockets C function library
#
# COPYRIGHT (c) 2026 The Fellowship of SML/NJ (https://smlnj.org)
# All rights reserved.
#

add_library(smlnj-clib-smlnj-sockets STATIC
  smlnj-sock-lib.c
  gethostname.c
  getnetbyname.c
  getnetbyaddr.c
  gethostbyname.c
  gethostbyaddr.c
  getprotbyname.c
  getprotbynum.c
  getservbyname.c
  getservbyport.c
  ctlBROADCAST.c
  ctlDEBUG.c
  ctlDONTROUTE.c
  ctlKEEPALIVE.c
  ctlLINGER.c
  ctlNODELAY.c
  ctlOOBINLINE.c
  ctlRCVBUF.c
  ctlREUSEADDR.c
  ctlSNDBUF.c
  getERROR.c
  getTYPE.c
  setNBIO.c
  getNREAD.c
  getATMARK.c
  getpeername.c
  getsockname.c
  accept.c
  bind.c
  close.c
  connect.c
  listen.c
  socket.c
  shutdown.c
  list-addr-families.c
  list-sock-types.c
  getaddrfamily.c
  inetany.c
  from-inetaddr.c
  to-inetaddr.c
  recv.c
  recvbuf.c
  recvfrom.c
  recvbuffrom.c
  sendbuf.c
  sendbufto.c
  from-unixaddr.c
  to-unixaddr.c
  socketpair.c
  util-mkhostent.c
  util-mknetent.c
  util-mkservent.c
  util-sockopt.c
  tbl-addr-family.c
  tbl-sock-type.c
)
target_link_libraries(smlnj-clib-smlnj-sockets PRIVATE smlnj-clib-common)
