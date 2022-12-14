!>@file   t_rayleigh_restart_IO.f90
!!@brief  module t_rayleigh_restart_IO
!!
!!@author H. Matsui
!!@date   Programmed  H. Matsui in 2004
!
!>@brief  Structure of Rayleigh paramters
!!
!!@verbatim
!!      subroutine alloc_rayleigh_radial_grid(ra_rst)
!!      subroutine dealloc_rayleigh_radial_grid(ra_rst)
!!        type(rayleigh_restart), intent(inout) :: ra_rst
!!
!!      subroutine check_rayleigh_rst_params(id_file, ra_rst)
!!        type(rayleigh_restart), intent(in) :: ra_rst
!!
!!      subroutine read_rayleigh_restart_params(dir, i_step, ra_rst)
!!        type(rayleigh_restart), intent(inout) :: ra_rst
!!      subroutine write_rayleigh_restart_params(dir, i_step, ra_rst)
!!        type(rayleigh_restart), intent(inout) :: ra_rst
!!
!!      character(len = kchara) function set_rayleigh_file_name         &
!!     &                               (dir, int_id, postfix)
!!          Version 1.x:  "[dir]/[int_id]/[field_flag]"
!!@endverbatim
!
      module t_rayleigh_restart_IO
!
      use ISO_C_BINDING
      use m_precision
      use m_machine_parameter
      use m_constants
!
      implicit  none
!
      character(len = kchara), parameter :: paramchar = "grid_etc"
!
      character(len = kchara), parameter :: wchar = "W"
      character(len = kchara), parameter :: zchar = "Z"
      character(len = kchara), parameter :: pchar = "P"
      character(len = kchara), parameter :: tchar = "T"
!
      character(len = kchara), parameter :: cchar = "C"
      character(len = kchara), parameter :: achar = "A"
!
      character(len = kchara), parameter :: wabchar = "WAB"
      character(len = kchara), parameter :: zabchar = "ZAB"
      character(len = kchara), parameter :: pabchar = "PAB"
      character(len = kchara), parameter :: tabchar = "TAB"
!
      character(len = kchara), parameter :: cabchar = "CAB"
      character(len = kchara), parameter :: aabchar = "AAB"
!
!>      Structure for Rayleigh restart data
      type rayleigh_restart
!>        Version ID
        integer :: i_version = 0
!>        Minor version ID
        integer :: i_minor = 0
!>        Endian swap flag
        logical :: flag_swap = .FALSE.
!
!>        truncation degree
        integer :: i_version_from_file
!>        truncation degree
        integer :: ltr_org
!
!>        Radial grid type
        integer :: iflag_rtype
!>        Number of radial grid
        integer :: nri_org
!>        radial
        real(kind = kreal), allocatable :: r_org(:)
!
!>        forward transform matrix
        real(kind = kreal), allocatable :: Cheby_fwd(:,:)
!
!>        Original delta t
        real(kind = kreal) :: dt_org
!>        Original time
        real(kind = kreal) :: time_org
!>        new delta t
        real(kind = kreal) :: dt_new
!>        new original delta t
        real(kind = kreal) :: new_dt_org
!>        time step
        integer(kind = kint) :: i_step_org
      end type rayleigh_restart
!
!-----------------------------------------------------------------------
      interface
        integer(C_int) function cmkdir(dir_name, length)                &
     &                         BIND(C, name = 'cmkdir_')
        use ISO_C_BINDING
        integer(C_int), value :: length
        character(C_char), intent(in) :: dir_name(*)
        end function cmkdir
      end interface
!-----------------------------------------------------------------------
!
      contains
!
!-----------------------------------------------------------------------
!
      subroutine link_text_buffer_for_C_ptr(len_buf, textbuf, buf_p)
!
      integer, intent(in) :: len_buf
      character(len=1), target, intent(in) :: textbuf(len_buf)
      character(C_char), pointer :: buf_p(:)
!
      buf_p => textbuf
!
      end subroutine link_text_buffer_for_C_ptr
!
!  ---------------------------------------------------------------------
!
      subroutine cmkdir_f(dir_name)
!
      character(len = kchara), intent(in) :: dir_name
!
      character(len=kchara) :: dir_w_null
      character(C_char), pointer :: buf_p(:)
!
      integer(C_int) :: ierr
!
      write(dir_w_null,'(a,a1)') trim(dir_name), char(0)
      call link_text_buffer_for_C_ptr(kchara, dir_w_null, buf_p)
      ierr = cmkdir(buf_p, len_trim(dir_w_null))
      nullify(buf_p)
!
      end subroutine cmkdir_f
!
!------------------------------------------------------------------
!
      subroutine alloc_rayleigh_radial_grid(ra_rst)
!
      type(rayleigh_restart), intent(inout) :: ra_rst
!
      allocate(ra_rst%r_org(ra_rst%nri_org))
      if(ra_rst%nri_org .gt. 0) ra_rst%r_org = 0.0d0
!
      end subroutine alloc_rayleigh_radial_grid
!
!-----------------------------------------------------------------------
!
      subroutine dealloc_rayleigh_radial_grid(ra_rst)
!
      type(rayleigh_restart), intent(inout) :: ra_rst
!
      deallocate(ra_rst%r_org)
!
      end subroutine dealloc_rayleigh_radial_grid
!
!-----------------------------------------------------------------------
!
      logical function check_file_exist(file_name)
!
      character(len=kchara), intent(in) :: file_name
      integer(kind = kint), parameter :: id_file = 255
!
!
      open (id_file, file=file_name, status='old', err=99)
      close(id_file)
!
      check_file_exist = .TRUE.
      return
!
  99  continue
      check_file_exist = .FALSE.
      return
!
      end function check_file_exist
!
!  ---------------------------------------------------------------------
!
      subroutine check_rayleigh_rst_params(id_file, ra_rst)
!
      integer, intent(in) :: id_file
      type(rayleigh_restart), intent(in) :: ra_rst
!
      integer(kind = kint) :: i
!
!
      write(id_file,*) 'flag_swap', ra_rst%flag_swap
      write(id_file,*) 'version ID', ra_rst%i_version_from_file
      write(id_file,*) 'ltr_org',  ra_rst%ltr_org
!
      write(id_file,*) 'iflag_rtype',  ra_rst%iflag_rtype
      write(id_file,*) 'nri_org',  ra_rst%nri_org
      do i = 1,  ra_rst%nri_org
        write(id_file,*) i,  ra_rst%r_org(i)
      end do
!
      write(id_file,*) 'time_org', ra_rst%time_org
      write(id_file,*) 'dt_org',  ra_rst%dt_org
      write(id_file,*) 'dt_new',  ra_rst%dt_new,  ra_rst%new_dt_org
!
      end subroutine check_rayleigh_rst_params
!
!-----------------------------------------------------------------------
!-----------------------------------------------------------------------
!
      subroutine read_rayleigh_restart_params(dir, i_step, ra_rst)
!
      use byte_swap_f
!
      integer(kind = kint), intent(in) :: i_step
      character(len = kchara), intent(in) :: dir
!
      type(rayleigh_restart), intent(inout) :: ra_rst
!
      character(len = kchara) :: file_name
      integer :: i4_tmp(1)
      real(kind = kreal) :: r_tmp(1)
      integer(kind = kint_gl) :: l8_byte
!
      integer, parameter :: id_file = 15
      integer, parameter :: iflag_pi = 314
!
!
      file_name =  set_rayleigh_file_name(dir, i_step, paramchar)
      write(*,*) 'read Rayleigh checkpoint paramter file: ',            &
     &          trim(file_name)
      open(id_file, FILE=file_name, STATUS='OLD',                       &
     &     FORM='UNFORMATTED', ACCESS='STREAM')
!
      ra_rst%flag_swap = .FALSE.
      read(id_file) i4_tmp(1)
      if(i4_tmp(1) .ne. iflag_pi) ra_rst%flag_swap = .TRUE.
!
      read(id_file) ra_rst%i_version_from_file
      read(id_file) ra_rst%nri_org
      read(id_file) ra_rst%iflag_rtype
      read(id_file) ra_rst%ltr_org
!
      read(id_file) ra_rst%dt_org
      read(id_file) ra_rst%dt_new
!      read(id_file)ra_rst%new_dt_org
!
      if(ra_rst%flag_swap) then
        l8_byte = 1
        call byte_swap_int4_f(l8_byte, i4_tmp)
        ra_rst%i_version_from_file = i4_tmp(1)
        call byte_swap_int4_f(l8_byte, i4_tmp)
        ra_rst%nri_org = i4_tmp(1)
        call byte_swap_int4_f(l8_byte, i4_tmp)
        ra_rst%iflag_rtype = i4_tmp(1)
        call byte_swap_int4_f(l8_byte, i4_tmp)
        ra_rst%ltr_org = i4_tmp(1)
        call byte_swap_real_f(l8_byte, r_tmp)
        ra_rst%dt_org = r_tmp(1)
        call byte_swap_real_f(l8_byte, r_tmp)
        ra_rst%dt_new = r_tmp(1)
!        call byte_swap_real_f(l8_byte, r_tmp)
!        ra_rst%new_dt_org = r_tmp(1)
      end if
!
      call alloc_rayleigh_radial_grid(ra_rst)
!
      read(id_file) ra_rst%r_org(1:ra_rst%nri_org)
      read(id_file) ra_rst%time_org
      read(id_file) ra_rst%i_step_org
      close(id_file)
!
      if(ra_rst%flag_swap) then
        l8_byte = ra_rst%nri_org
        call byte_swap_real_f(l8_byte, ra_rst%r_org)
        l8_byte = 1
        call byte_swap_real_f(l8_byte, r_tmp)
        ra_rst%time_org = r_tmp(1)
        call byte_swap_int4_f(l8_byte, i4_tmp)
        ra_rst%i_step_org = i4_tmp(1)
      end if
!
      write(*,*) 'ra_rst%time_org', ra_rst%time_org
      write(*,*) 'ra_rst%i_step', ra_rst%i_step_org
!
      end subroutine read_rayleigh_restart_params
!
!-----------------------------------------------------------------------
!
      subroutine write_rayleigh_restart_params(dir, i_step, ra_rst)
!
      integer(kind = kint), intent(in) :: i_step
      character(len = kchara), intent(in) :: dir
!
      type(rayleigh_restart), intent(inout) :: ra_rst
!
      character(len = kchara) :: file_name
      integer :: i4_tmp(1)
      real(kind = kreal) :: r_tmp(1)
      integer(kind = kint_gl) :: l8_byte
!
      integer, parameter :: id_file = 15
      integer, parameter :: iflag_pi = 314
!
!
      write(*,*) 'i_step', i_step
      file_name =  set_rayleigh_file_name(dir, i_step, paramchar)
      write(*,*) 'read Rayleigh checkpoint paramter file: ',            &
     &          trim(file_name)
      open(id_file, FILE=file_name,                                     &
     &     FORM='UNFORMATTED', ACCESS='STREAM')
!
      write(id_file) iflag_pi
!
      write(id_file) ra_rst%i_version_from_file
      write(id_file) ra_rst%nri_org
      write(id_file) ra_rst%iflag_rtype
      write(id_file) ra_rst%ltr_org
!
      write(id_file) ra_rst%dt_org
      write(id_file) ra_rst%dt_new
!
      write(id_file) ra_rst%r_org(1:ra_rst%nri_org)
      write(id_file) ra_rst%time_org
      write(id_file) ra_rst%i_step_org
      close(id_file)
!
      end subroutine write_rayleigh_restart_params
!
!-----------------------------------------------------------------------
!-----------------------------------------------------------------------
!
      character(len = kchara) function set_rayleigh_file_name           &
     &                               (dir, int_id, postfix)
!
      integer(kind = kint), intent(in) :: int_id
      character(len=kchara), intent(in) :: dir, postfix
!
!
      write(set_rayleigh_file_name,1000)                                &
     &                      trim(dir), '/', int_id, '/', trim(postfix)
 1000 format(a,a1,i8.8,a1,a)
!
      end function set_rayleigh_file_name
!
!-----------------------------------------------------------------------
!
      character(len = kchara) function set_rayleigh_folder_name         &
     &                               (dir, int_id)
!
      integer(kind = kint), intent(in) :: int_id
      character(len=kchara), intent(in) :: dir
!
!
      write(set_rayleigh_folder_name,1000) trim(dir), '/', int_id
 1000 format(a,a1,i8.8)
!
      end function set_rayleigh_folder_name
!
!-----------------------------------------------------------------------
!
      end module t_rayleigh_restart_IO
