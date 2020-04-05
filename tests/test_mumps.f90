
use, intrinsic:: iso_fortran_env, only: output_unit, error_unit
use mpi, only: mpi_init, mpi_comm_world

implicit none (external)

external :: mpi_finalize, dmumps

include 'dmumps_struc.h'  ! per MUMPS manual
type(DMUMPS_STRUC) :: mumps_par

integer :: ierr

call mpi_init(ierr)
if (ierr /= 0) error stop 'MPI init error'

mumps_par%COMM = mpi_comm_world

mumps_par%JOB = -1
mumps_par%SYM = 0
mumps_par%PAR = 1

call DMUMPS(mumps_par)

! must set ICNTL after initialization Job= -1 above

mumps_par%icntl(1) = error_unit  ! error messages
mumps_par%icntl(2) = output_unit !  diagnosic, statistics, and warning messages
mumps_par%icntl(3) = output_unit ! global info, for the host (myid==0)
mumps_par%icntl(4) = 1           ! default is 2, this reduces verbosity

if (.not. all(mumps_par%icntl(:4) == [error_unit, output_unit, output_unit, 1])) then
  error stop 'MUMPS parameters not correctly set'
endif

call mpi_finalize(ierr)
if (ierr /= 0) error stop 'MPI finalize error'

print *, 'MUMPS OK'

end program
