subroutine refresh_trun(tin, rcgtmp)
use matmod
use tmpmatmod
implicit none
include '../include/sizes'
include '../include/common'
!
real*8,     intent(in)    :: tin
complex*16, intent(in)    :: rcgtmp(nrho,*)
integer                   :: nrho2, info, istat, nwork, ni, nj, ncount
real*8,     allocatable   :: rwork(:), tmpval(:)
complex*16, allocatable   :: zwork(:,:)
complex*16, allocatable   :: cmat1(:,:)
logical                   :: lherm
real*8                    :: dtmp1
integer                   :: itimes
data itimes /0/
!
if (.not. ltrun_der) then
   write(6,*)'refresh_trun: error entrance ', ltrun_der
   stop
end if
if (itimes .gt. 0 .and. fixdot) then
   itimes = itimes + 1
   return
end if
itimes = itimes + 1
!
allocate(cmat1(nrho,nrho), STAT=istat)
!
nrho2 = nrho**2
nwork = nrho2**2
!
if (lhf) then 
   call calchs(rcgtmp(1,1))
end if
cmat1(1:nrho,1:nrho) = hs(1:nrho,1:nrho)
call calcdhs(tin, rcgtmp(1,1))
cmat1(1:nrho,1:nrho) = cmat1(1:nrho,1:nrho) + dhs(1:nrho,1:nrho)
!
if (.not. allocated(zmatder)) allocate(zmatder(nrho2,nrho2), STAT=istat)
if (.not. allocated(dvalder)) allocate(dvalder(nrho2), STAT=istat)
!
! diagonalize L
! 
call zhil2liou('l', 'n', nrho, cmat1, nrho, zlmtmp1, nrho2)
call zhil2liou('r', 'n', nrho, cmat1, nrho, zlmtmp2, nrho2)
zmatder(1:nrho2,1:nrho2) = zlmtmp1(1:nrho2,1:nrho2) - zlmtmp2(1:nrho2,1:nrho2)
call checkhermicity(zmatder, nrho2, zlmtmp1, nrho2, lherm, dtmp1)
if (.not. lherm) then
   write(6,*)'refresh_trun: error! L is not Hermitian '
   stop
end if
!
allocate(zwork(nrho2,nrho2), rwork(3*nrho2-2), tmpval(nrho2), STAT=istat)
call zheev('V', 'u', nrho2, zmatder, nrho2, dvalder, zwork(1,1), nwork, rwork, info)
if (info .ne. 0) then
   write(6,*)'refresh_trun: error! diagonalization failed 1 ', info
   stop
end if
!
! sort and screen out eigenvectors with zero eigenvalues
!
zwork = czero
ncount = 0
do ni=1,nrho2
   if (dabs(dvalder(ni)) .le. dpico) cycle
   ncount = ncount + 1
   tmpval(ncount) = dvalder(ni)
   zwork(1:nrho2,ncount) = zmatder(1:nrho2,ni)
end do
!write(6,*)'refresh_trun: ', ncount, ' out of ', nrho2, ' eigenvalues are nonzero '
!call flush(6)
zmatder(1:nrho2,1:nrho2) = czero
zmatder(1:nrho2,1:ncount) = zwork(1:nrho2,1:ncount)
dvalder(1:nrho2) = 0.d0
dvalder(1:ncount) = tmpval(1:ncount)
nnzeig = ncount
!
deallocate(zwork, rwork, tmpval, cmat1, STAT=istat)
return
end subroutine refresh_trun
