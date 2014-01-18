/*******************************************************************************
*   OpenHyperFLOW2D-CUDA                                                       *
*                                                                              *
*   Transient, Density based Effective Explicit Parallel Hybrid Solver         *
*   TDEEPHS (CUDA+MPI)                                                         *
*   Version  1.0.1                                                             *
*   Copyright (C)  1995-2014 by Serge A. Suchkov                               *
*   Copyright policy: LGPL V3                                                  *
*                                                                              *
*   deeps2d_core.cpp: CUDA kernels code.                                       *
*                                                                              *
*  last update: 16/01/2014                                                     *
********************************************************************************/

#ifdef _CUDA_
#define _PARALLEL_ONLY

#include <cuda.h>
#include <cuda_runtime.h>
#include <cuda_runtime_api.h>

#include "libDEEPS2D/deeps2d_core.hpp"

__device__ int floatToOrderedInt( float floatVal ) {

int intVal = __float_as_int( floatVal );

return (intVal >= 0 ) ? intVal : intVal ^ 0x7FFFFFFF;

}

__device__  float orderedIntToFloat( int intVal ) {

return __int_as_float( (intVal >= 0) ? intVal : intVal ^ 0x7FFFFFFF );

}

__device__ float fatomicMin(float *addr, float value) {

        float old = *addr, assumed;

        if(old <= value) return old;

        do {
                assumed = old;
                old = atomicCAS((unsigned int*)addr, __float_as_int(assumed), __float_as_int(value));

        }while(old!=assumed);

        return old;
}

__device__ float fatomicMax(float *addr, float value) {

        float old = *addr, assumed;

        if(old >= value) return old;

        do {
                assumed = old;
                old = atomicCAS((unsigned int*)addr, __float_as_int(assumed), __float_as_int(value));

        }while(old!=assumed);

        return old;
}

void CUDA_BRRIER(char* KernelName) {
    cudaError_t cudaState = cudaDeviceSynchronize();    
    if(cudaState != cudaSuccess) {
        printf("\nError in %s kernel...\n",KernelName);
        if(cudaState == cudaErrorMemoryAllocation) {
           printf("Memory allocation error.\n");
        } else if(cudaState == cudaErrorLaunchTimeout ) {
          printf("Timeout.\n");
        }else if(cudaState == cudaErrorLaunchOutOfResources) {
          printf("Resources temporary insufficient.\n");
        }else if(cudaState ==  cudaErrorInvalidConfiguration ) {
          printf("Resources insufficient for this device\n");
        }else if(cudaState == cudaErrorInvalidValue) {
          printf("Invalid value.\n");
        }else if(cudaState == cudaErrorInvalidHostPointer ) {
          printf("Invalid host pointer.\n");
        }else if(cudaState == cudaErrorInvalidDevicePointer) {
          printf("Invalid device pointer.\n");
        }else if(cudaState == cudaErrorNotReady) {
          printf("Device not ready.\n");
        }else if(cudaState == cudaErrorLaunchFailure) {
          printf("Device illegal address.\n");
        } else {
         printf("Unknown error.\n");
        }
        Exit_OpenHyperFLOW2D();
    }
}

void CopyDeviceToDevice(void* src, void* dst, size_t length) {
    //printf("CopyDeviceToDevice: src=%x dst=%x length=%x\n",src,dst,length);
    cudaError_t cudaState = cudaMemcpyAsync(dst, src, length,cudaMemcpyDeviceToDevice);
    if(cudaState != cudaSuccess) {
     printf("\nError copy device to device...\n");
     if(cudaState == cudaErrorMemoryAllocation) {
        printf("Memory allocation error.\n");
     } else if(cudaState == cudaErrorLaunchTimeout ) {
       printf("Timeout.\n");
     }else if(cudaState == cudaErrorLaunchOutOfResources) {
       printf("Resources temporary insufficient.\n");
     }else if(cudaState ==  cudaErrorInvalidConfiguration ) {
       printf("Resources insufficient for this device\n");
     }else if(cudaState == cudaErrorInvalidValue) {
       printf("Invalid value.\n");
     }else if(cudaState == cudaErrorInvalidHostPointer ) {
       printf("Invalid host pointer.\n");
     }else if(cudaState == cudaErrorInvalidDevicePointer) {
       printf("Invalid device pointer.\n");
     }else if(cudaState == cudaErrorNotReady) {
       printf("Device not ready.\n");
     } else {
      printf("Unknown error.\n");
     }
       Exit_OpenHyperFLOW2D();
    }
}

void CopyHostToDevice(void* src, void* dst, size_t length) {
    cudaError_t cudaState = cudaMemcpyAsync(dst, src, length,cudaMemcpyHostToDevice);
    if(cudaState != cudaSuccess) {
     printf("\nError copy host to device...\n");
     if(cudaState == cudaErrorMemoryAllocation) {
        printf("Memory allocation error.\n");
     } else if(cudaState == cudaErrorLaunchTimeout ) {
       printf("Timeout.\n");
     }else if(cudaState == cudaErrorLaunchOutOfResources) {
       printf("Resources temporary insufficient.\n");
     }else if(cudaState ==  cudaErrorInvalidConfiguration ) {
       printf("Resources insufficient for this device\n");
     }else if(cudaState == cudaErrorInvalidValue) {
       printf("Invalid value.\n");
     }else if(cudaState == cudaErrorInvalidHostPointer ) {
       printf("Invalid host pointer.\n");
     }else if(cudaState == cudaErrorInvalidDevicePointer) {
       printf("Invalid device pointer.\n");
     }else if(cudaState == cudaErrorNotReady) {
       printf("Device not ready.\n");
     } else {
      printf("Unknown error.\n");
     }
       Exit_OpenHyperFLOW2D();
    }
}
     
void CopyDeviceToHost(void* src, void* dst, size_t length) {
    cudaError_t cudaState = cudaMemcpyAsync(dst, src, length,cudaMemcpyDeviceToHost);
    if(cudaState != cudaSuccess) {
     printf("\nError copy device to host...\n");
     if(cudaState == cudaErrorMemoryAllocation) {
        printf("Memory allocation error.\n");
     } else if(cudaState == cudaErrorLaunchTimeout ) {
       printf("Timeout.\n");
     }else if(cudaState == cudaErrorLaunchOutOfResources) {
       printf("Resources temporary insufficient.\n");
     }else if(cudaState ==  cudaErrorInvalidConfiguration ) {
       printf("Resources insufficient for this device\n");
     }else if(cudaState == cudaErrorInvalidValue) {
       printf("Invalid value.\n");
     }else if(cudaState == cudaErrorInvalidHostPointer ) {
       printf("Invalid host pointer.\n");
     }else if(cudaState == cudaErrorInvalidDevicePointer) {
       printf("Invalid device pointer.\n");
     }else if(cudaState == cudaErrorNotReady) {
       printf("Device not ready.\n");
     } else {
      printf("Unknown error.\n");
     }
       Exit_OpenHyperFLOW2D();
    }
}

__global__ void 
cuda_SetInitBoundaryLayer(FlowNode2D<double,NUM_COMPONENTS>* pJ2D,
                          unsigned long int index_limit,
                          int X0, int MAX_Y,
                          double delta,
                          double sig_w, 
                          double sig_f,
                          TurbulenceExtendedModel etm,
                          double _dx, double _dy,
                          double* _Hu,
                          int _isSrcAdd,
                          FlowType _FT) {

    unsigned long int index = threadIdx.x + blockIdx.x * blockDim.x;

    if(index < index_limit) {

              FlowNode2D< double,NUM_COMPONENTS >* CurrentNode=&pJ2D[index];
              
              if(CurrentNode->CT != (ulong)(CT_SOLID_2D | CT_NODE_IS_SET_2D)) {   
                  
                  if(CurrentNode->time == 0. &&  delta > 0.0  &&  CurrentNode->l_min <= delta) {
                     CurrentNode->S[i2d_RoU] = CurrentNode->S[i2d_RoU] * CurrentNode->l_min/delta;
                     CurrentNode->S[i2d_RoV] = CurrentNode->S[i2d_RoV] * CurrentNode->l_min/delta;
                     CurrentNode->FillNode2D(0,1,sig_w,sig_f,etm,delta,_dx,_dy,_Hu,_isSrcAdd,_FT);
                  }
              
               if(CurrentNode->CT != (ulong)(NT_FC_2D)) { 

                  int  i = CurrentNode->ix - X0;
                  int  j = CurrentNode->iy;

                  int  n1 = CurrentNode->idXl; 
                  int  n2 = CurrentNode->idXr;
                  int  n3 = CurrentNode->idYu;
                  int  n4 = CurrentNode->idYd;

                  int  N1 = i - n1;
                  int  N2 = i + n2;
                  int  N3 = j + n3;
                  int  N4 = j - n4;
                  
                  CurrentNode->UpNode    = &pJ2D[i*MAX_Y + N3];
                  CurrentNode->DownNode  = &pJ2D[i*MAX_Y + N4];
                  CurrentNode->RightNode = &pJ2D[N2*MAX_Y + j];
                  CurrentNode->LeftNode  = &pJ2D[N1*MAX_Y + j];
               }
              }
   }
}
                                                                     
__global__ void
cuda_SetMinDistanceToWall2D(FlowNode2D<double,NUM_COMPONENTS>* pJ2D,
                            unsigned long int index_limit,
                            XY<int>* WallNodes2D, 
                            int NumWallNodes2D,
                            double min_l_min,
                            double max_l_min,
                            double _dx, double _dy)   {
          
   unsigned long int index = threadIdx.x + blockIdx.x * blockDim.x;
   
   if(index < index_limit) {
       
       
       FlowNode2D<double,NUM_COMPONENTS>* TmpNode = &pJ2D[index];
       
       if(TmpNode->CT != (ulong)(CT_SOLID_2D | CT_NODE_IS_SET_2D)) {   
          
           TmpNode->l_min = max_l_min;
 #pragma unroll
           for (int ii=0;ii<NumWallNodes2D;ii++) {

              XY<int>*  TmpWallNode = &WallNodes2D[ii]; 

              double L_x   = (TmpWallNode->X - TmpNode->ix)* _dx;
              double L_y   = (TmpWallNode->Y - TmpNode->iy)* _dy;
              double l_min = sqrt(L_x*L_x + L_y*L_y);
              
              TmpNode->l_min = max(min(TmpNode->l_min,l_min),min_l_min);
            }
        }
   }
   //__syncthreads();
}
__global__ void 
cuda_Recalc_y_plus(FlowNode2D<double,NUM_COMPONENTS>* pJ2D,
                   unsigned long int index_limit,
                   XY<int>* WallNodes2D, 
                   int NumWallNodes2D,
                   double min_l_min,
                   double max_l_min,
                   double _dx, 
                   double _dy,
                   int max_y) {
    unsigned long int index = threadIdx.x + blockIdx.x * blockDim.x;

    if(index < index_limit) {

        FlowNode2D<double,NUM_COMPONENTS>* TmpNode = &pJ2D[index];

        if(TmpNode->CT != (ulong)(CT_SOLID_2D | CT_NODE_IS_SET_2D)) {

            int iw=0;
            int jw=0;
#pragma unroll
           for (int ii=0;ii<NumWallNodes2D;ii++) {
               
               XY<int>*  TmpWallNode = &WallNodes2D[ii]; 

               double L_x   = (TmpWallNode->X - TmpNode->ix)* _dx;
               double L_y   = (TmpWallNode->Y - TmpNode->iy)* _dy;
               double l_min = sqrt(L_x*L_x + L_y*L_y);

               if(l_min  == TmpNode->l_min) {
                  iw = TmpWallNode->X;
                  jw = TmpWallNode->Y;
               }
           }
           
          //__syncthreads();

           unsigned long int wall_index = iw*max_y + jw;

           if(wall_index < index_limit) {
               
               FlowNode2D<double,NUM_COMPONENTS>* WallNode = &pJ2D[wall_index];   // x*nY + y

               double tau_w = (fabs(WallNode->dUdy) +                           
                               fabs(WallNode->dVdx)) * WallNode->mu;  

               double U_w   = sqrt(tau_w/WallNode->S[i2d_Ro]);

               TmpNode->y_plus = U_w*TmpNode->l_min*TmpNode->S[i2d_Ro]/TmpNode->mu;
           }
        }
     }  
  //__syncthreads(); 
}

__global__  void  
cuda_DEEPS2D_Stage1(FlowNode2D<double,NUM_COMPONENTS>*     pLJ,
                    FlowNodeCore2D<double,NUM_COMPONENTS>* pLC,
                    int MAX_X, int MAX_Y,// int X0, 
                    unsigned long r_limit,
                    unsigned long l_limit,
                    double dxx, double dyy,
                    double dtdx, double dtdy,
                    double _dt,
                    int _FT, int Num_Eq) {
    
    unsigned long int index = threadIdx.x + blockIdx.x * blockDim.x;
    
    if((index >= l_limit) &&
       (index < r_limit)) {

          FlowNode2D< double,NUM_COMPONENTS >* CurrentNode=&pLJ[index];

          if(CurrentNode->CT != (ulong)(CT_SOLID_2D | CT_NODE_IS_SET_2D) &&
             CurrentNode->CT != (ulong)(NT_FC_2D)) { 

              FlowNodeCore2D< double,NUM_COMPONENTS >* NextNode=&pLC[index];
              
              double beta[NUM_COMPONENTS+6];  
              double _beta[NUM_COMPONENTS+6]; 
              
              int  n1 = CurrentNode->idXl; 
              int  n2 = CurrentNode->idXr;
              int  n3 = CurrentNode->idYu;
              int  n4 = CurrentNode->idYd;
              
              double  n_n_1 = 1./max(n1+n2,1);
              double  m_m_1 = 1./max(n3+n4,1);
              
              FlowNode2D< double,NUM_COMPONENTS >* UpNode    = CurrentNode->UpNode;
              FlowNode2D< double,NUM_COMPONENTS >* DownNode  = CurrentNode->DownNode;
              FlowNode2D< double,NUM_COMPONENTS >* RightNode = CurrentNode->RightNode;
              FlowNode2D< double,NUM_COMPONENTS >* LeftNode  = CurrentNode->LeftNode;
              
              // Scan equation system ... k - number of equation
#pragma unroll              
              for (int k=0;k<Num_Eq;k++ ) {
                    
                  int      c_flag = 0;
                  int      dx_flag, dx2_flag;                 

                  int      dy_flag, dy2_flag;
                  double   dXX,dYY;

                  beta[k]  = CurrentNode->beta[k];
                  _beta[k] = 1. - beta[k];

                // Precomputed variables for current node ...
                    c_flag  = dx_flag = dy_flag = dx2_flag = dy2_flag = 0;
                    if ( k < 4 ) { // Make bit flags for future test for current equation
                        c_flag   = CT_Ro_CONST_2D     << k; 
                        dx_flag  = CT_dRodx_NULL_2D   << k;
                        dy_flag  = CT_dRody_NULL_2D   << k;
                        dx2_flag = CT_d2Rodx2_NULL_2D << k;
                        dy2_flag = CT_d2Rody2_NULL_2D << k;
                    } else if (k < (4+NUM_COMPONENTS)) {
                        c_flag   = CT_Y_CONST_2D;
                        dx_flag  = CT_dYdx_NULL_2D;
                        dy_flag  = CT_dYdy_NULL_2D;
                        dx2_flag = CT_d2Ydx2_NULL_2D;
                        dy2_flag = CT_d2Ydy2_NULL_2D;
                    } else if ((CurrentNode->isTurbulenceCond2D(TCT_k_eps_Model_2D) ||
                                CurrentNode->isTurbulenceCond2D(TCT_Spalart_Allmaras_Model_2D))) { //
                      if( k == i2d_k) {
                          c_flag   = TCT_k_CONST_2D     << (k-4-NUM_COMPONENTS); 
                          dx_flag  = TCT_dkdx_NULL_2D   << (k-4-NUM_COMPONENTS);
                          dy_flag  = TCT_dkdy_NULL_2D   << (k-4-NUM_COMPONENTS);
                          dx2_flag = TCT_d2kdx2_NULL_2D << (k-4-NUM_COMPONENTS);
                          dy2_flag = TCT_d2kdy2_NULL_2D << (k-4-NUM_COMPONENTS);
                      } else if (k == i2d_eps) {
                          c_flag   = TCT_eps_CONST_2D     << (k-4-NUM_COMPONENTS); 
                          dx_flag  = TCT_depsdx_NULL_2D   << (k-4-NUM_COMPONENTS);
                          dy_flag  = TCT_depsdy_NULL_2D   << (k-4-NUM_COMPONENTS);
                          dx2_flag = TCT_d2epsdx2_NULL_2D << (k-4-NUM_COMPONENTS);
                          dy2_flag = TCT_d2epsdy2_NULL_2D << (k-4-NUM_COMPONENTS);
                      }
                    }
                    // Check BC for current equation
                    if (k<(4+NUM_COMPONENTS)) {

                        if ( CurrentNode->isCond2D((CondType2D)c_flag) )
                            c_flag  = 0;
                        else
                            c_flag  = 1;

                        if ( CurrentNode->isCond2D((CondType2D)dx_flag) ) {
                            dx_flag = 0;
                        } else {
                            dx_flag = 1;
                        }

                        if ( CurrentNode->isCond2D((CondType2D)dy_flag) ) {
                            dy_flag = 0;
                        } else {
                            dy_flag = 1;
                        }

                        if ( CurrentNode->isCond2D((CondType2D)dx2_flag) ) {
                            dx2_flag = 1;
                        } else {
                            dx2_flag = 0;
                        }

                        if ( CurrentNode->isCond2D((CondType2D)dy2_flag) ) {
                            dy2_flag = 1;
                        } else {
                            dy2_flag = 0;
                        }
                    } else if((CurrentNode->isTurbulenceCond2D(TCT_k_eps_Model_2D) ||
                               CurrentNode->isTurbulenceCond2D(TCT_Spalart_Allmaras_Model_2D)) ) {
                        if ( CurrentNode->isTurbulenceCond2D((TurbulenceCondType2D)c_flag) )
                            c_flag  = 0;
                        else
                            c_flag  = 1;

                        if ( CurrentNode->isTurbulenceCond2D((TurbulenceCondType2D)dx_flag) ) {
                            dx_flag = 0;
                        } else {
                            dx_flag = 1;
                        }
                        if ( CurrentNode->isTurbulenceCond2D((TurbulenceCondType2D)dy_flag) ) {
                            dy_flag = 0;
                        } else {
                            dy_flag = 1;
                        }
                        if ( CurrentNode->isTurbulenceCond2D((TurbulenceCondType2D)dx2_flag) ) {
                            dx2_flag = 1;
                        } else {
                            dx2_flag = 0;
                        }
                        if ( CurrentNode->isTurbulenceCond2D((TurbulenceCondType2D)dy2_flag) ) {
                            dy2_flag = 1;
                        } else {
                            dy2_flag = 0;
                        }
                    }
                    
                    if ( c_flag ) {
                        if ( dx_flag ) {
                            dXX = (RightNode->A[k]-LeftNode->A[k])*n_n_1;  // CurrentNode->dSdx[k] = 
                        } else {
                            CurrentNode->S[k] = (LeftNode->S[k]*n2+RightNode->S[k]*n1)*n_n_1;
                            dXX = 0.;                                     //  CurrentNode->dSdx[k]=  
                        }
                        if ( dy_flag ) {
                            dYY = (UpNode->B[k]-DownNode->B[k])*m_m_1;    // CurrentNode->dSdy[k] =
                        } else {                                                                                                                    
                            CurrentNode->S[k] =  (UpNode->S[k]*n3+DownNode->S[k]*n4)*m_m_1;
                            dYY = 0;                                       // CurrentNode->dSdy[k] =
                        }
                        
                        // Cauchi BC temporary blocked 
                        /*
                        if ( dx2_flag ) {
                            dXX = (LeftNode->dSdx[k]+RightNode->dSdx[k])*0.5;
                        }
                        if ( dy2_flag ) {
                            dYY = (UpNode->dSdy[k]+DownNode->dSdy[k])*0.5;
                        }
                        */
                        if ( _FT ) {
                            NextNode->S[k] = CurrentNode->S[k]*beta[k]+_beta[k]*(dxx*(LeftNode->S[k]+RightNode->S[k])+dyy*(UpNode->S[k]+DownNode->S[k]))*0.5
                                          - (dtdx*dXX+dtdy*(dYY+CurrentNode->F[k]/(CurrentNode->ix+0.5))) + (CurrentNode->Src[k])*_dt+CurrentNode->SrcAdd[k];
                        } else {
                            NextNode->S[k] = CurrentNode->S[k]*beta[k]+_beta[k]*(dxx*(LeftNode->S[k]+RightNode->S[k])+dyy*(UpNode->S[k]+DownNode->S[k]))*0.5
                                          - (dtdx*dXX+dtdy*dYY) + (CurrentNode->Src[k])*_dt+CurrentNode->SrcAdd[k];
                        }
                }
            }
            //CalcChemicalReactions(CurrentNode,CRM_ZELDOVICH, (void*)(pCRMD));
          }
            
     }
}

__global__  void 
cuda_DEEPS2D_Stage2(FlowNode2D<double,NUM_COMPONENTS>*     pLJ,
                    FlowNodeCore2D<double,NUM_COMPONENTS>* pLC,
                    int ii, int MAX_X, int MAX_Y, //int X0, 
                    unsigned long r_limit,
                    unsigned long l_limit,
                    double beta_init, double  beta0, 
                    int b_FF, double CFL0,
                    ChemicalReactionsModelData2D* pCRMD,
                    int noTurbCond,
                    double SigW, double SigF, double dx_1, double dy_1, double delta_bl,
                    FlowType _FT, int Num_Eq,
#ifdef _RMS_             
                    double*  RMS, 
                    int*     iRMS,
                    double   DD_max,
                    int*     i_c,
                    int*     j_c,
#endif // _RMS_
                    double* _Hu,
                    int _isSrcAdd,
                    float* dt_global,
                    TurbulenceExtendedModel TurbExtModel ) {
    

    unsigned long int index = threadIdx.x + blockIdx.x * blockDim.x;
    
    if((index >= l_limit) &&
       (index < r_limit)) {
        
          FlowNode2D< double,NUM_COMPONENTS >* CurrentNode=&pLJ[index];

          if(CurrentNode->CT != (ulong)(CT_SOLID_2D | CT_NODE_IS_SET_2D) &&
             CurrentNode->CT != (ulong)(NT_FC_2D)) { 
              
              double  beta_min;
              
              beta_min = min(beta0,beta_init);

              FlowNodeCore2D< double,NUM_COMPONENTS >* NextNode=&pLC[index];
              
              int  n1 = CurrentNode->idXl; 
              int  n2 = CurrentNode->idXr;
              int  n3 = CurrentNode->idYu;
              int  n4 = CurrentNode->idYd;
              
              double  n_n_1 = 1./max(n1+n2,1);
              double  m_m_1 = 1./max(n3+n4,1);
              
              FlowNode2D< double,NUM_COMPONENTS >* UpNode    = CurrentNode->UpNode;
              FlowNode2D< double,NUM_COMPONENTS >* DownNode  = CurrentNode->DownNode;
              FlowNode2D< double,NUM_COMPONENTS >* RightNode = CurrentNode->RightNode;
              FlowNode2D< double,NUM_COMPONENTS >* LeftNode  = CurrentNode->LeftNode;
              
              double dx_1xn_n_1=dx_1*n_n_1;
              double dy_1xm_m_1=dy_1*m_m_1;

              // Scan equation system ... k - number of equation
#pragma unroll              
              for (int k=0;k<Num_Eq;k++ ) {
                    
                  int      c_flag = 0;

                  if ( k < 4 ) // Make bit flags for future test for current equation 
                      c_flag  = CT_Ro_CONST_2D   << k;
                  else if (k<(4+NUM_COMPONENTS))  // 7 ?
                      c_flag  = CT_Y_CONST_2D;
                  else if((CurrentNode->isTurbulenceCond2D(TCT_k_eps_Model_2D) ||
                           CurrentNode->isTurbulenceCond2D(TCT_Spalart_Allmaras_Model_2D) )) 
                      c_flag  = TCT_k_CONST_2D << (k-4-NUM_COMPONENTS); 

                  if ( !CurrentNode->isCond2D((CondType2D)c_flag) && 
                        CurrentNode->S[k] != 0. ) {
                        double DD_local;
                        double Tmp;

                        if(k == i2d_RoU && k == i2d_RoV ) {
                            Tmp = sqrt(CurrentNode->S[i2d_RoU]*CurrentNode->S[i2d_RoU]+
                                       CurrentNode->S[i2d_RoV]*CurrentNode->S[i2d_RoV]+1.e-30); // Flux
                        } else {
                            Tmp = CurrentNode->S[k];
                        }

                        if(fabs(Tmp) > 1.e-15)
                           DD_local = fabs((NextNode->S[k]-CurrentNode->S[k])/Tmp);
                        else
                           DD_local = 0.0;
                        
                        
                        if( b_FF == BFF_L) {
                         //LINEAR locally adopted blending factor function  (LLABFF)
                           CurrentNode->beta[k] = min(beta_min,(beta_min*beta_min)/(beta_min+DD_local));
                         } else if( b_FF == BFF_LR) {
                         //LINEAR locally adopted blending factor function with relaxation (LLABFFR)
                           CurrentNode->beta[k] = min((beta_min+CurrentNode->beta[k])*0.5,(beta_min*beta_min)/(beta_min+DD_local));
                         } else if( b_FF == BFF_S) {
                         //SQUARE locally adopted blending factor function (SLABF)
                           CurrentNode->beta[k] = min(beta_min,(beta_min*beta_min)/(beta_min+DD_local*DD_local));
                         } else if (b_FF == BFF_SR) {
                         //SQUARE locally adopted blending factor function with relaxation (SLABFFR)
                           CurrentNode->beta[k] = min((beta_min+CurrentNode->beta[k])*0.5,(beta_min*beta_min)/(beta_min+DD_local*DD_local));
                         } else if( b_FF == BFF_SQR) {
                         //SQRT() locally adopted blending factor function (SQRLABF)
                           CurrentNode->beta[k] = min(beta_min,(beta_min*beta_min)/(beta_min+sqrt(DD_local)));
                         } else if( b_FF == BFF_SQRR) {
                         //SQRT() locally adopted blending factor function with relaxation (SQRLABFFR)
                           CurrentNode->beta[k] = min((beta_min+CurrentNode->beta[k])*0.5,(beta_min*beta_min)/(beta_min+sqrt(DD_local))); 
                         } else {
                           // Default->SQRLABF
                           CurrentNode->beta[k] = min(beta_min,(beta_min*beta_min)/(beta_min+sqrt(DD_local)));
                         }
                         
#ifdef _RMS_
                         RMS[k+ii*Num_Eq] += DD_local;
                         iRMS[k+ii*Num_Eq]++;
                         DD_max[k+ii*Num_Eq] = max(DD_max[k+ii*Num_Eq],DD_local);

                         if ( DD_max[k+ii*Num_Eq] == DD_local ) {
                              i_c[ii] = i;
                              j_c[ii] = j;
                         }
#endif // RMS
                  }
                  
                  if (k<(4+NUM_COMPONENTS)) {
                      if ( !CurrentNode->isCond2D((CondType2D)c_flag) )
                            CurrentNode->S[k]   = NextNode->S[k];
                  } else if ((CurrentNode->isTurbulenceCond2D(TCT_k_eps_Model_2D) ||
                              CurrentNode->isTurbulenceCond2D(TCT_Spalart_Allmaras_Model_2D)) ){
                      if ( !CurrentNode->isTurbulenceCond2D((TurbulenceCondType2D)c_flag) )
                            CurrentNode->S[k]   =  NextNode->S[k];
                  }
                  
              }

              CurrentNode->droYdx[NUM_COMPONENTS]=CurrentNode->droYdy[NUM_COMPONENTS]=0.;

#pragma unroll
              for (int k=4;k<NUM_EQ-2;k++ ) {
                  if ( !CurrentNode->isCond2D(CT_dYdx_NULL_2D) ) {
                      CurrentNode->droYdx[k-4]=(RightNode->S[k]-LeftNode->S[k])*dx_1*0.5;
                      CurrentNode->droYdx[NUM_COMPONENTS]+=(RightNode->S[k]-LeftNode->S[k])*dx_1*0.5;
                  }
                  if ( !CurrentNode->isCond2D(CT_dYdy_NULL_2D) ) {
                        CurrentNode->droYdy[k-4]=(UpNode->S[k]-DownNode->S[k])*dy_1*0.5;
                        CurrentNode->droYdy[NUM_COMPONENTS]+=(DownNode->S[k]-UpNode->S[k])*dy_1*0.5;
                  }
              }
              
              if (CurrentNode->isCond2D(CT_WALL_NO_SLIP_2D) || CurrentNode->isCond2D(CT_WALL_LAW_2D) )  {
                  CurrentNode->dUdx=(RightNode->U*n1-LeftNode->U*n2)*dx_1xn_n_1;
                  CurrentNode->dVdx=(RightNode->V*n1-LeftNode->V*n2)*dx_1xn_n_1;

                  CurrentNode->dUdy=(UpNode->U*n3-DownNode->U*n4)*dy_1xm_m_1;
                  CurrentNode->dVdy=(UpNode->V*n3-DownNode->V*n4)*dy_1xm_m_1;

                  if(CurrentNode->isTurbulenceCond2D(TCT_k_eps_Model_2D)){
                    CurrentNode->dkdx   =(RightNode->S[i2d_k]*n1-LeftNode->S[i2d_k]*n2)*dx_1/CurrentNode->S[i2d_Ro]*n_n_1;
                    CurrentNode->depsdx =(RightNode->S[i2d_eps]*n1-LeftNode->S[i2d_eps]*n2)*dx_1/CurrentNode->S[i2d_Ro]*n_n_1;

                    CurrentNode->dkdy   =(UpNode->S[i2d_k]*n3-DownNode->S[i2d_k]*n4)*dy_1/CurrentNode->S[i2d_Ro]*m_m_1;
                    CurrentNode->depsdy =(UpNode->S[i2d_eps]*n3-DownNode->S[i2d_eps]*n4)*dy_1/CurrentNode->S[i2d_Ro]*m_m_1;
                  } else if (CurrentNode->isTurbulenceCond2D(TCT_Spalart_Allmaras_Model_2D)) {
                             CurrentNode->dkdx   =(RightNode->S[i2d_k]*n1-LeftNode->S[i2d_k]*n2)*dx_1/CurrentNode->S[i2d_Ro]*n_n_1;
                             CurrentNode->dkdy   =(UpNode->S[i2d_k]*n3-DownNode->S[i2d_k]*n4)*dy_1/CurrentNode->S[i2d_Ro]*m_m_1;
                  }
              } else {
                  CurrentNode->dUdx   =(RightNode->U-LeftNode->U)*dx_1xn_n_1;
                  CurrentNode->dVdx   =(RightNode->V-LeftNode->V)*dx_1xn_n_1;

                  CurrentNode->dUdy   =(UpNode->U-DownNode->U)*dy_1xm_m_1;
                  CurrentNode->dVdy   =(UpNode->V-DownNode->V)*dy_1xm_m_1;
                  if(CurrentNode->isTurbulenceCond2D(TCT_k_eps_Model_2D)){
                    CurrentNode->dkdx   =(RightNode->S[i2d_k]-LeftNode->S[i2d_k])*dx_1/CurrentNode->S[i2d_Ro]*n_n_1;
                    CurrentNode->depsdx =(RightNode->S[i2d_eps]-LeftNode->S[i2d_eps])*dx_1/CurrentNode->S[i2d_Ro]*n_n_1;

                    CurrentNode->dkdy   =(UpNode->S[i2d_k]-DownNode->S[i2d_k])*dy_1/CurrentNode->S[i2d_Ro]*m_m_1;
                    CurrentNode->depsdy =(UpNode->S[i2d_eps]-DownNode->S[i2d_eps])*dy_1/CurrentNode->S[i2d_Ro]*m_m_1;
                  } else if (CurrentNode->isTurbulenceCond2D(TCT_Spalart_Allmaras_Model_2D)) {
                             CurrentNode->dkdx   =(RightNode->S[i2d_k]-LeftNode->S[i2d_k])*dx_1/CurrentNode->S[i2d_Ro]*n_n_1;
                             CurrentNode->dkdy   =(UpNode->S[i2d_k]-DownNode->S[i2d_k])*dy_1/CurrentNode->S[i2d_Ro]*m_m_1;
                  }
              }

              CurrentNode->dTdx=(RightNode->Tg-LeftNode->Tg)*dx_1xn_n_1;
              CurrentNode->dTdy=(UpNode->Tg-DownNode->Tg)*dy_1xm_m_1;
              
              //CalcChemicalReactions(CurrentNode,CRM_ZELDOVICH, (void*)(pCRMD));
              
              if(noTurbCond) {
                 CurrentNode->FillNode2D(0,1,SigW,SigF,TurbExtModel,delta_bl,1.0/dx_1,1.0/dy_1,_Hu,_isSrcAdd,_FT);
              } else {
                 CurrentNode->FillNode2D(1,0,SigW,SigF,TurbExtModel,delta_bl,1.0/dx_1,1.0/dy_1,_Hu,_isSrcAdd,_FT);
              }
              
              if( CurrentNode->Tg < 0. ) {
                  *dt_global = 0.0;  // Computational instability
              }  else {
                  double AAA          = sqrt(CurrentNode->k*CurrentNode->R*CurrentNode->Tg); 
                  double dt_min_local = CFL0*min(dx_1*(AAA+fabs(CurrentNode->U)),dy_1*(AAA+fabs(CurrentNode->V)));
                  //*dt_global = min(*dt_global,dt_min_local);
                  fatomicMin(dt_global,dt_min_local);
              }
       }
     }
   }
#endif // _CUDA_

