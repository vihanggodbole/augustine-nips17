#!/bin/bash

# Pseudocode -
# for each weight learning method: 
#     for each example:
#         if out.txt doesn't exist:
#             Exectute run.sh
#             Write output to 'weight-learning-method/example-name/out.txt'
#             Write error to 'weight-learning-method/example-name/out.txt'

BASE_PATH=$(pwd)
DEFAULT_POSTGRES_DB='vg_psl_experiments'

mkdir -p "${BASE_PATH}/logs"

BASE_WEIGHT_NAME='org.linqs.psl.application.learning.weight.'

# declare -a weight_learning_methods=("bayesian.GaussianProcessPrior -D gpp.maxiterations=50" "maxlikelihood.MaxLikelihoodMPE" "maxlikelihood.MaxPiecewisePseudoLikelihood" "search.Hyperband" "search.InitialWeightHyperband" "search.grid.ContinuousRandomGridSearch" "search.grid.GuidedRandomGridSearch" "search.grid.RandomGridSearch")
declare -a weight_learning_methods=("search.Hyperband" "search.InitialWeightHyperband") #"search.grid.ContinuousRandomGridSearch -D continuousrandomgridsearch.maxlocations=100" "search.grid.GuidedRandomGridSearch -D guidedrandomgridsearch.explorelocations=5 -D guidedrandomgridsearch.seedlocations=10" "search.grid.RandomGridSearch")

for i in "${weight_learning_methods[@]}"; do

	echo "Running Weight Learner: ${i}"

	find . -wholename '*/cli/run.sh' -exec dirname {} \; | while read line ; do
      	
		current_example=$(echo $line | cut -d/ -f2)

		mkdir -p "${BASE_PATH}/logs/${current_example}"

	        pushd . > /dev/null
      	
		cd $line
        	sed -i "/readonly ADDITIONAL_LEARN_OPTIONS='--learn*/c\readonly ADDITIONAL_LEARN_OPTIONS='--learn ${BASE_WEIGHT_NAME}${i}'" run.sh
		for fold in 00 01 02 03 04
		do
			echo "-Running fold:${fold}"
			sed -i "s|/[0-9][0-9]/learn/|/${fold}/learn/|g" ${current_example}-learn.data
			sed -i "s|/[0-9][0-9]/eval/|/${fold}/eval/|g" ${current_example}-eval.data
			if [[ -e "${BASE_PATH}/logs/${current_example}/${i}_${fold}_${current_example}_out.txt" ]]; then
				echo "Output file already exists, skipping: ${current_example}"
			else
				echo "--Running example: ${current_example}"
				./run.sh --postgres ${DEFAULT_POSTGRES_DB} -D log4j.threshold=DEBUG > "${BASE_PATH}/logs/${current_example}/${i}_${fold}_${current_example}_out.txt" 2> "${BASE_PATH}/logs/${current_example}/${i}_${fold}_${current_example}_err.txt"
			fi
      		done
		popd > /dev/null 
	done

done
