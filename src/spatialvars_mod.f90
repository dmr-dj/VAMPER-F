!-----|--1----+----2----+----3----+----4----+----5----+----6----+----7----+----8----+----9----+----0----+----1----+----2----+----3-|

!   Copyright 2024 Didier M. Roche (a.k.a. dmr)

!   Licensed under the Apache License, Version 2.0 (the "License");
!   you may not use this file except in compliance with the License.
!   You may obtain a copy of the License at

!       http://www.apache.org/licenses/LICENSE-2.0

!   Unless required by applicable law or agreed to in writing, software
!   distributed under the License is distributed on an "AS IS" BASIS,
!   WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
!   See the License for the specific language governing permissions and
!   limitations under the License.

!-----|--1----+----2----+----3----+----4----+----5----+----6----+----7----+----8----+----9----+----0----+----1----+----2----+----3-|

    MODULE spatialvars_mod

#include "constant.h"
#define OFFLINE_RUN 1

    IMPLICIT NONE

    PRIVATE


            ! SPATIAL GLOBAL VARIABLES

     real, dimension(:,:),allocatable, PUBLIC :: Temp      & !dmr [SPAT_VAR], soil temperature over the vertical // prognostic
                                                ,Kp        & !dmr [CNTST]     heat conductivity constant over the depth, current value is 2
                                                ,n         & !dmr [SPAT_VAR], porosity on the vertical
                                                ,Cp        & !dmr [SPAT_VAR]  specific heat capacity
                                                ,pori      & !dmr [???  TBC]
                                                ,porf        !dmr [???  TBC]

     real, dimension(:), allocatable, PUBLIC :: GeoHFlux   &
                                               ,Tinit_SV


     integer, dimension(:), allocatable, PUBLIC :: orgalayer_indx

            ! CLIMATE FORCING VARIABLES
     REAL, DIMENSION(:,:), ALLOCATABLE :: forcing_surface_temp ! two dimensions / spatial and time in that order
            ! could add swe_f_t, snw_dp_t,rho_snow_t,T_snw
     REAL, DIMENSION(:,:), ALLOCATABLE :: restart_temperature  ! VERT/SPAT


#if ( CARBON == 1 )
     real,dimension(:,:)  , allocatable, PUBLIC :: deepSOM_a & !dmr [TBD]
                                                 , deepSOM_s & !dmr [TBD]
                                                 , deepSOM_p   !dmr [TBD]
     real, dimension(:)   , allocatable, PUBLIC :: clay_SV
     real,dimension(:,:,:), allocatable, PUBLIC :: fc_SV       !dmr [TBD]
#endif



     PUBLIC:: spatialvars_allocate, spatialvars_init

     CONTAINS


!-----|--1----+----2----+----3----+----4----+----5----+----6----+----7----+----8----+----9----+----0----+----1----+----2----+----3-|
! dmr   Allocation of two dimensional variables (VERTCL, SPAT_VAR)
!-----|--1----+----2----+----3----+----4----+----5----+----6----+----7----+----8----+----9----+----0----+----1----+----2----+----3-|

     SUBROUTINE spatialvars_allocate ! VERTCL, SPAT_VAR

       use parameter_mod, only: gridNoMax, timFNoMax, z_num
       use carbon       , only: ncarb

!-----|--1----+----2----+----3----+----4----+----5----+----6----+----7----+----8----+----9----+----0----+----1----+----2----+----3-|
!       BY REFERENCE VARIABLES
!-----|--1----+----2----+----3----+----4----+----5----+----6----+----7----+----8----+----9----+----0----+----1----+----2----+----3-|


!-----|--1----+----2----+----3----+----4----+----5----+----6----+----7----+----8----+----9----+----0----+----1----+----2----+----3-|
!       LOCAL VARIABLES
!-----|--1----+----2----+----3----+----4----+----5----+----6----+----7----+----8----+----9----+----0----+----1----+----2----+----3-|

!-----|--1----+----2----+----3----+----4----+----5----+----6----+----7----+----8----+----9----+----0----+----1----+----2----+----3-|
!       MAIN BODY OF THE ROUTINE
!-----|--1----+----2----+----3----+----4----+----5----+----6----+----7----+----8----+----9----+----0----+----1----+----2----+----3-|


       allocate(Temp(1:z_num,1:gridNoMax)) !dmr SPAT_VAR
       allocate(Kp(1:z_num-1,1:gridNoMax)) !dmr SPAT_VAR
       allocate(n(1:z_num,1:gridNoMax))    !dmr SPAT_VAR
       allocate(Cp(1:z_num,1:gridNoMax))   !dmr SPAT_VAR
       allocate(pori(1:z_num,1:gridNoMax)) !dmr SPAT_VAR
       allocate(porf(1:z_num,1:gridNoMax)) !dmr SPAT_VAR

       allocate(GeoHFlux(1:gridNoMax))
       allocate(Tinit_SV(1:gridNoMax))


       allocate(orgalayer_indx(1:gridNoMax))

#if ( CARBON == 1 )
                        !nb and mbv Carbon cycle
       allocate(deepSOM_a(1:z_num,1:gridNoMax))
       allocate(deepSOM_s(1:z_num,1:gridNoMax))
       allocate(deepSOM_p(1:z_num,1:gridNoMax))
       allocate(fc_SV(1:ncarb,1:ncarb,1:gridNoMax))
       allocate(clay_SV(1:gridNoMax))
#endif

       allocate(forcing_surface_temp(1:gridNoMax,1:timFNoMax))
       allocate(restart_temperature(1:z_num,1:gridNoMax)) ! contains the restart temperature at init


     END SUBROUTINE spatialvars_allocate


!-----|--1----+----2----+----3----+----4----+----5----+----6----+----7----+----8----+----9----+----0----+----1----+----2----+----3-|
! dmr   Allocation of two dimensional variables (VERTCL, SPAT_VAR)
!-----|--1----+----2----+----3----+----4----+----5----+----6----+----7----+----8----+----9----+----0----+----1----+----2----+----3-|

     SUBROUTINE spatialvars_init ! VERTCL, SPAT_VAR

       use parameter_mod,  only: gridNoMax, z_num
       use vertclvars_mod, only: vertclvars_init

           ! Temporary addendum [2025-04-16]
       use parameter_mod,  only: Gfx, T_init
       use parameter_mod,  only: forc_tas_file, name_tas_variable

#if ( CARBON == 1 )
       use carbon        , only: carbon_init
#endif

!-----|--1----+----2----+----3----+----4----+----5----+----6----+----7----+----8----+----9----+----0----+----1----+----2----+----3-|
!       BY REFERENCE VARIABLES
!-----|--1----+----2----+----3----+----4----+----5----+----6----+----7----+----8----+----9----+----0----+----1----+----2----+----3-|


!-----|--1----+----2----+----3----+----4----+----5----+----6----+----7----+----8----+----9----+----0----+----1----+----2----+----3-|
!       LOCAL VARIABLES
!-----|--1----+----2----+----3----+----4----+----5----+----6----+----7----+----8----+----9----+----0----+----1----+----2----+----3-|
       integer :: gridp
!-----|--1----+----2----+----3----+----4----+----5----+----6----+----7----+----8----+----9----+----0----+----1----+----2----+----3-|
!       MAIN BODY OF THE ROUTINE
!-----|--1----+----2----+----3----+----4----+----5----+----6----+----7----+----8----+----9----+----0----+----1----+----2----+----3-|

            !dmr [NOTA] For now, dummy init of spatial variables based on constants
        GeoHFlux(:) = Gfx
        Tinit_SV(:) = T_init

            !dmr Initialization of all columns, one by one
        do gridp = 1, gridNoMax
          call vertclvars_init(GeoHFlux(gridp), Tinit_SV(gridp), Kp(:,gridp),Cp(:,gridp), orgalayer_indx(gridp), n(:,gridp) &
                             , Temp(:,gridp))

#if ( CARBON == 1 )
            !dmr Initialization of all columns, one by one
          call carbon_init(deepSOM_a(:,gridp), deepSOM_s(:,gridp), deepSOM_p(:,gridp), fc_SV(:,:,gridp), clay_SV(gridp))
#endif
        enddo

#if (OFFLINE_RUN == 1)
        call get_clim_forcing(forc_tas_file, name_tas_variable,forcing_surface_temp)
#endif

     END SUBROUTINE spatialvars_init

     SUBROUTINE get_clim_forcing(forc_surf_file, name_surf_variable, forcing_surface_var)

        use netcdf
        use parameter_mod, only: str_len

!-----|--1----+----2----+----3----+----4----+----5----+----6----+----7----+----8----+----9----+----0----+----1----+----2----+----3-|
!       BY REFERENCE VARIABLES
!-----|--1----+----2----+----3----+----4----+----5----+----6----+----7----+----8----+----9----+----0----+----1----+----2----+----3-|

        CHARACTER(len=str_len), intent(in) :: forc_surf_file, name_surf_variable

        REAL, DIMENSION(:,:),   intent(out):: forcing_surface_var ! two dimensions / spatial and time in that order

!-----|--1----+----2----+----3----+----4----+----5----+----6----+----7----+----8----+----9----+----0----+----1----+----2----+----3-|
!       LOCAL VARIABLES
!-----|--1----+----2----+----3----+----4----+----5----+----6----+----7----+----8----+----9----+----0----+----1----+----2----+----3-|

        INTEGER :: ncid, ret_stat, nDims, nvars, nGlobalAtts, unlimdimid
        INTEGER :: d,v,a, i, j

        CHARACTER(len=NF90_MAX_NAME), DIMENSION(:),   ALLOCATABLE :: dimNAMES
        INTEGER                     , DIMENSION(:),   ALLOCATABLE :: dimLEN

        CHARACTER(len=NF90_MAX_NAME), DIMENSION(:),   ALLOCATABLE :: varNAMES
        INTEGER                     , DIMENSION(:),   ALLOCATABLE :: varXTYPE, varNDIMS, varNATTS
        INTEGER                     , DIMENSION(:,:), ALLOCATABLE :: varDIMIDS

        CHARACTER(len=NF90_MAX_NAME), DIMENSION(:),   ALLOCATABLE :: attNAMES

        LOGICAL                     , DIMENSION(:),   ALLOCATABLE :: varisDIM

        INTEGER :: maskVarID=0, dim1, dim2, dim3, varunmasked

        REAL                      , DIMENSION(:,:,:), ALLOCATABLE :: varDATA
        REAL                                                      :: var_undef = 0.0

!-----|--1----+----2----+----3----+----4----+----5----+----6----+----7----+----8----+----9----+----0----+----1----+----2----+----3-|
!       MAIN BODY OF THE ROUTINE
!-----|--1----+----2----+----3----+----4----+----5----+----6----+----7----+----8----+----9----+----0----+----1----+----2----+----3-|

!      dmr GETTING THE VARIABLE NEEDED

      ret_stat = nf90_open(forc_surf_file, nf90_nowrite, ncid)
      ret_stat = nf90_inquire(ncid, nDims, nVars, nGlobalAtts, unlimdimid)

      ! I look forward to get a grid with one spatial variable and two dimensions for now
      ! Hence I should get nDims = 3, nVars = 4 at least (could be more if more variables), unlimited with time, hence unlimdimid != -1

      if ( (nDims.EQ.3).AND.(nVars.GE.4).AND.(unlimdimid.NE.-1) ) then ! valid file

       ALLOCATE(dimNAMES(nDims))
       ALLOCATE(dimLEN(nDims))

       DO d=1,nDims
         ret_stat = nf90_inquire_dimension(ncid, d, dimNAMES(d), dimLEN(d))
!~          WRITE(*,*) "Found dimensions ::", dimNAMES(d), d
       ENDDO

       ! really only need the length of the unlimited (time) variable

       ret_stat = nf90_inq_varid(ncid,name_surf_variable,v)

       ALLOCATE(varNAMES(nVars))
       ALLOCATE(varXTYPE(nVars))
       ALLOCATE(varNDIMS(nVars))
       ALLOCATE(varDIMIDS(nVars,nDims))
       ALLOCATE(varNATTS(nVars))
       ALLOCATE(varisDIM(nVars))

       ret_stat = nf90_inquire_variable(ncid, v, varNAMES(v), varXTYPE(v), varNDIMS(v), varDIMIDS(v,:), varNATTS(v))

      else
         WRITE(*,*) "netCDF file for VAR does not match expectations", name_surf_variable
         STOP
      endif

      if (v.NE.0) then ! I have found my variable to read, I have enough to define it

      if (varNDIMS(v).NE.3) then
         WRITE(*,*) "Current version only support 3D var file"
         STOP
      else
         ! Get the actual values of the thing

         dim1 = dimLEN(varDIMIDS(v,1))
         dim2 = dimLEN(varDIMIDS(v,2))
         dim3 = dimLEN(varDIMIDS(v,3))

         ALLOCATE(varDATA(dim1,dim2,dim3))

         ret_stat = NF90_GET_VAR(ncid,v,varDATA)

!~          WRITE(*,*) "DIMS", dim1, dim2, dim3 ! lon lat time is getting out ... correct? (somehow netCDF reads backward)


         ALLOCATE(attNAMES(varNATTS(v)))

         do a=1,varNATTS(v)
           ret_stat = NF90_INQ_ATTNAME(ncid, v, a, attNAMES(a))
           if ((INDEX(attNAMES(a), "missing_value").GT.0) .OR. (INDEX(attNAMES(a), "_FillValue").GT.0) ) then
               ret_stat = NF90_GET_ATT(ncid, v, attNAMES(a), var_undef)
           endif
         enddo

!~          ! Get the missing value of the thing if exists ...
!~          WRITE(*,*) "Value for undef :: ", var_undef
      endif

      ! variable is read in ... now need to check where I have an actual value (not masked)


      varunmasked = 0

      DO j=1, dim2
      DO i=1, dim1
         if (varDATA(i,j,1).NE.var_undef) then
             ! count it in !
            varunmasked = varunmasked + 1
            forcing_surface_var(varunmasked,:) = varDATA(i,j,:)
         endif
      ENDDO
      ENDDO

      else
        WRITE(*,*) "var id is zero", v
      endif


      DEALLOCATE(dimNAMES)
      DEALLOCATE(dimLEN)
      DEALLOCATE(varNAMES)
      DEALLOCATE(varXTYPE)
      DEALLOCATE(varNDIMS)
      DEALLOCATE(varDIMIDS)
      DEALLOCATE(varNATTS)
      DEALLOCATE(varisDIM)
      DEALLOCATE(varDATA)

     END SUBROUTINE get_clim_forcing


    END MODULE spatialvars_mod
