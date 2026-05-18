
add_library(smlnj-sock STATIC
    # NetDB
    gethostname.c
    getnetbyname.c
    getnetbyaddr.c
    gethostbyname.c
    gethostbyaddr.c
    getprotbyname.c
    getprotbynum.c
    getservbyname.c
    getservbyport.c

    # Ctl
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

    # UnixSock
    from-unixaddr.c
    to-unixaddr.c
    socketpair.c

    # SockObjs
    accept.c
    bind.c
    close.c
    connect.c
    listen.c
    socket.c
    shutdown.c

    # IOObjs
    recv.c
    recvbuf.c
    recvfrom.c
    recvbuffrom.c
    sendbuf.c
    sendbufto.c

    # Misc
    list-addr-families.c
    list-sock-types.c
    getaddrfamily.c
    inetany.c
    from-inetaddr.c
    to-inetaddr.c

    # Unix
    util-mkhostent.c
    util-mknetent.c
    util-mkservent.c
    util-sockopt.c
    tbl-addr-family.c
    tbl-sock-type.c

    smlnj-sock-lib.c
)
target_link_libraries(smlnj-sock PRIVATE runtime-common clibs-common)
