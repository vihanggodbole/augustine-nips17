#!/bin/sh

JAR_PATH="${HOME}/.m2/repository/org/linqs/psl-cli/2.1.0-SNAPSHOT/psl-cli-2.1.0-SNAPSHOT.jar"
OUT_BASE_DIR='out'
COUNTS='22050 33075 38588 44100 49613 55125 66150'

trap exit SIGINT

for count in $COUNTS; do
   outDir="${OUT_BASE_DIR}/${count}"
   outputPath="${outDir}/out.txt"
   mkdir -p $outDir

   echo "Running $count data. Output redirected to ${outputPath}."

   time java -jar $JAR_PATH -i -d dataFiles/party-affiliation-${count}.data -m party-affiliation.psl -D log4j.threshold=DEBUG -o ${outDir} > ${outputPath}
   # time java -jar $JAR_PATH -i -d dataFiles/party-affiliation-${count}.data -m party-affiliation.psl -D log4j.threshold=DEBUG -o ${outDir} --postgres testtime > ${outputPath}
done
