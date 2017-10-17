#!/bin/sh

JAR_PATH="${HOME}/.m2/repository/org/linqs/psl-cli/2.1.0-SNAPSHOT/psl-cli-2.1.0-SNAPSHOT.jar"
OUT_BASE_DIR='out'

DATASETS='citeseer cora'
FOLDS=`seq -w -s ' ' 0 19`

MODEL_FILE='collective-classification-citeseer-neighbor.psl'
LEARNED_MODEL_FILE='collective-classification-citeseer-neighbor-learned.psl'

trap exit SIGINT

for dataset in $DATASETS; do
   for fold in $FOLDS; do
      outDir="${OUT_BASE_DIR}/${dataset}/${fold}"
      outputLearnPath="${outDir}/out-learn.txt"
      outputEvalPath="${outDir}/out-eval.txt"
      mkdir -p $outDir

      echo "Running ${dataset}/${fold} (learn). Output redirected to ${outputLearnPath}."

      dataFile="dataFiles/collective-classification-${dataset}-${fold}-learn.data"
      time java -jar $JAR_PATH -l -d ${dataFile} -m ${MODEL_FILE} -D log4j.threshold=DEBUG > ${outputLearnPath}

      learnedModelPath="${outDir}/${LEARNED_MODEL_FILE}"
      mv ${LEARNED_MODEL_FILE} ${learnedModelPath}

      echo "Running ${dataset}/${fold} (eval). Output redirected to ${outputEvalPath}."

      dataFile="dataFiles/collective-classification-${dataset}-${fold}-eval.data"
      time java -jar $JAR_PATH -i -d ${dataFile} -m ${learnedModelPath} -D log4j.threshold=DEBUG -ed -o ${outDir} > ${outputEvalPath}
   done
done
