(* barrier.sml
 *
 * COPYRIGHT (c) 2011 The Fellowship of SML/NJ (https://smlnj.org)
 * All rights reserved.
 *)

structure Barrier :> BARRIER =
  struct

    structure S = Scheduler

    type 'a cont = 'a SMLofNJ.Cont.cont
    val callcc = SMLofNJ.Cont.callcc
    val throw = SMLofNJ.Cont.throw

    datatype 'a result = RAISE of exn | VALUE of 'a

    datatype 'a barrier = BAR of {
	state : 'a ref,
	update : 'a -> 'a,
	nEnrolled : int ref,
	nWaiting : int ref,
	waiting : (S.thread_id * 'a result cont) list ref
      }

    datatype status = ENROLLED | WAITING | RESIGNED

    datatype 'a enrollment = ENROLL of {
	bar : 'a barrier,
	sts : status ref	(* current status of this enrollment *)
      }

  (* create a new barrier.  The first argument is the update function that
   * is applied to the global state whenever a barrier synchronization occurs.
   * The second argument is the initial global state.
   *)
    fun barrier update init = BAR{
	    state = ref init,
	    update = update,
	    nEnrolled = ref 0,
	    nWaiting = ref 0,
	    waiting = ref []
	  }

  (* enroll in a barrier *)
    fun enroll (bar as BAR{nEnrolled, ...}) = (
	  S.atomicBegin();
	  nEnrolled := !nEnrolled + 1;
	  S.atomicEnd();
	  ENROLL{bar = bar, sts = ref ENROLLED})

    fun wakeupThd result (tid, resumeK) =
	  S.enqueueThread(
	    tid, callcc(fn k => (callcc(fn k' => throw k k'); throw resumeK result)))

    fun return (RAISE exn) = raise exn
      | return (VALUE x) = x

  (* release the threads that are waiting at a barrier and update the global
   * state.  This function must be called from inside an atomic region and
   * assumes that every enrolled thread is waiting (i.e., that
   * !nWaiting = !nEnrolled).  It returns the new state (or the exception
   * raised by the update function).
   *)
    fun release (BAR{state, update, nWaiting, waiting, ...}) = let
	  val result = let
		val x = update(!state)
		in
		  state := x;
		  VALUE x
		end handle exn => RAISE exn
	  in
	    List.app (wakeupThd result) (!waiting);
	    nWaiting := 0;
	    waiting := [];
	    result
	  end

  (* synchronize on a barrier *)
    fun wait (ENROLL{bar as BAR{nEnrolled, nWaiting, waiting, ...}, sts}) = (
	  S.atomicBegin();
	  case !sts
	   of ENROLLED => (
		sts := WAITING;
		nWaiting := !nWaiting+1;
		if (!nWaiting = !nEnrolled)
		  then let (* all threads are at the barrier, so we can proceed *)
		    val result = release bar
		    in
		      S.atomicEnd ();
		    (* the enrollment is reusable for the next round *)
		      sts := ENROLLED;
		      return result
		    end
		  else let
		    val result = callcc (fn resumeK => (
			  waiting := (S.getCurThread(), resumeK) :: !waiting;
			  S.atomicDispatch()))
		    in
		    (* the enrollment is reusable for the next round *)
		      sts := ENROLLED;
		      return result
		    end)
	    | WAITING => (S.atomicEnd(); raise Fail "multiple barrier waits")
	    | RESIGNED => (S.atomicEnd(); raise Fail "barrier wait after resignation")
	  (* end case *))

  (* resign from an enrolled barrier *)
    fun resign (ENROLL{bar as BAR{nEnrolled, nWaiting, ...}, sts}) = (
	  S.atomicBegin();
	  case !sts
	   of RESIGNED => S.atomicEnd() (* ignore multiple resignations *)
	    | WAITING => (S.atomicEnd(); raise Fail "resign while waiting")
	    | ENROLLED => (
		sts := RESIGNED;
		nEnrolled := !nEnrolled - 1;
	      (* resigning may be what leaves the remaining enrolled threads all
	       * waiting at the barrier.
	       *)
		if (!nEnrolled > 0) andalso (!nWaiting = !nEnrolled)
		  then ignore (release bar)
		  else ();
		S.atomicEnd())
	  (* end case *))

  (* get the current state of the barrier *)
    fun value (ENROLL{bar=BAR{state, ...}, ...}) = !state

  end
