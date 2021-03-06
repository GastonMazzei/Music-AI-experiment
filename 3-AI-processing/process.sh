#!/bin/bash

#-------------------------------------------------------
# REFERENCE FOR CHANGING NEURAL NETWORK PARAMETERS
#------------------------------------------------------
# (A)
# datapoints / degrees_of_freedom ratio = 1 + A
#
# (B)
# integration epochs
#
# (C)
# minibatched stochastic gradient descent's batch size
# (training set is ~20k points)
#
# (D)
# Hidden Layers = 1 + D
#
# (E)
# Gradient Descent's learning rate
#
#-------------n-e-t-w-o-r-k--p-a-r-a-m-e-t-e-r-s--------
A=4
B=100
C=20
D=0
E=0.004
#----------------e--n--d--------------------------------
#
#
#---------------------------------------------------------
#    REFERENCE FOR BUILDING THE DATABASE
#-------------------------------------------------------------
#      scaler = 0-SKlearn.MinMaxScaler
#               1-SKLearn.StandardScaler
#               2-None (data is already processed for 1-4 range)
#
#         vol = 1-Yes, volume is considered
#               0-No, volume is removed
#
#   centering = 0- time is (tstart,tend)
#               1- time is (center, duration)
#               2- time is (tstart, duration)
#
#         pca = 0 to N  (default 4)
#                      :the Number of PCA eigenvectors
#                       included as features
#
# contraction = 0.01-1.00 (default = 1)
#                      :contract sample rate by this factor 
#                       to reduce Number of Features
#
#    sampling = 4*1 - 4*N (default 400)
#                      :7*4 times the sampling rate (notes/sec)
#
#         tau = 0-7 (default 3)
#                      :variation margin for selected fragments
#                       used in training (windows will be 7+-tau)
#-------------------------------------------------------------------
#-----v-e-c-t-o-r-i-z-e-d--d-a-t-a-b-a-s-e--p-a-r-a-m-e-t-e-r-s-----
#
# (vectorized for if iteration is desired)
declare -a scaler=(1)
declare -a vol=(1)
declare -a centering=(0)
declare -a pca=(4)
declare -a contraction=("1")
declare -a sampling=(400)
declare -a tau=(3)
#--------------------------e-n-d------------------------------------


for i in "${sampling[@]}";do
  for j in "${tau[@]}";do
  printf "Processing songs under specs:\nsampling rate $i\nwindow margin $j"
  printf "\n\n...it could take a while... (3mins)\n"	
  (cd "../2-AI-database-building"; unzip works-by-composer.zip)
  (cd "../2-AI-database-building"; bash pipe.sh $i $j > /dev/null 2>&1)
  printf "\n--DONE!--\n"
  for k in "${contraction[@]}";do
    for l in "${pca[@]}";do
      for m in "${centering[@]}";do
        for n in "${vol[@]}";do
          for o in "${scaler[@]}";do
            printf "\n\nCreating a database under specs:\n"
            printf "contraction $k\npca $l\ncentering $m\n"
	    printf "vol $n\nscaler $o\n"
	    printf "\n\nthe database will be in './datasets'\n"
            python3 scripts/make_database.py $k $n $m $o $l  >/dev/null 2>&1                         
            printf "\n--DONE!--\n"
	    printf "NOW: five times AI-models (NeuralNetwork and RandomFOrest)\n"
	    printf "     will be built for their successive evaluation..."
            for i in $(seq 1 5); do
	      printf "\n\nTraining a neural network under the specs:\n"
	      printf "data/degrees_of_freedom ~ $A\nepochs $B\n"
	      printf "batch size $C\ndeepness $D\nlearning rate $E"
	      printf "\nClassification results, in general for this problem "
    	      printf "very poor, will be available in results/last-neural-network.png\n"
              python3 scripts/process.py $A 100 $C $D $E $l $o $k $m $n 'network' $i $j  >/dev/null 2>&1
	      printf "\n--DONE!--\n"
              printf "\n\nTraining a Random Forest classifier under specs:\n"
	      printf "N Trees: 200\n"
	      printf "and all other defaults same as SKLearn's"            
              python3 scripts/process.py $A $B $C $D $E $l $o $k $m $n 'forest' $i $j  >/dev/null 2>&1 	      
              printf "\n--DONE!--\n"
            done
           done
          done
        done
      done
    done
  done                                          
done

message="
\n\nFINAL MESSAGE:
correct and predicted values for both validation & testing set
have been appended to './results/' files:
'val-network-predictions.csv'
'test-network-predictions.csv'
'val-forest-predictions.csv'
'test-forest-predictions.csv'

A copy of them has been made in the '../7-results' directory.
"
declare -a results=('val-network-predictions.csv'
		    'test-network-predictions.csv'
                    'val-forest-predictions.csv'
                    'test-forest-predictions.csv')
for i in ${results[@]};do
  cp "results/$i" "../6-results/data/$i"
done
cp tags.dat "../6-results/data/tags.dat"
printf $message
