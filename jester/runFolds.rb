require 'fileutils'
require 'shellwords'

JAVA_PATH = File.join('/', 'usr', 'bin', 'java')
JAR_PATH = File.expand_path(File.join('~', '.m2', 'repository', 'org', 'linqs', 'psl-cli', '2.1.0-SNAPSHOT', 'psl-cli-2.1.0-SNAPSHOT.jar'))

PSL_CLI_DIR = '.'
JESTER_PSL_FILE = File.join(PSL_CLI_DIR, 'jester.psl')
JESTER_PSL_LEARNED_FILE = File.join(PSL_CLI_DIR, 'jester-learned.psl')
JESTER_DATA_FILE = File.join(PSL_CLI_DIR, 'jester.data')
POSTGRES_DB = 'testtime'

DATA_DIR = 'runData'
FOLDS_DIR = File.join('data', 'folds')
NUM_FOLDS = 10

OUTPUT_DIR = 'out'
LEARN_FILENAME = 'learn.out'
EVAL_FILENAME = 'eval.out'

NUMBER_REGEX = '(\d+\.\d+)'
STATS = ['MAE', 'MSE', 'Accuracy', 'Error', 'Positive Class Precision', 'Positive Class Recall', 'Negative Class Precision', 'Negative Class Recall']

def parseOutputForStats(output)
   stats = []

   output.each_line{|line|
      line = line.strip()

      if (match = line.match(/Continuous evaluation results for RATING -- MAE: #{NUMBER_REGEX}, MSE: #{NUMBER_REGEX}$/))
         stats += match[1..2].map{|val| val.to_f()}
      elsif (match = line.match(/Discrete evaluation results for RATING -- Accuracy: #{NUMBER_REGEX}, Error: #{NUMBER_REGEX}, Positive Class Precision: #{NUMBER_REGEX}, Positive Class Recall: #{NUMBER_REGEX}, Negative Class Precision: #{NUMBER_REGEX}, Negative Class Recall: #{NUMBER_REGEX}/))
         stats += match[1..6].map{|val| val.to_f()}
      end
   }

   return stats
end

def runWeightLearning(fold, outDir)
   args = [
      '-jar', JAR_PATH,
      '-l',
      '-d', JESTER_DATA_FILE,
      '-m', JESTER_PSL_FILE,
      '--postgres', POSTGRES_DB,
      '-D', 'log4j.threshold=DEBUG'
   ]
   command = "#{JAVA_PATH} #{Shellwords.join(args)}"

   FileUtils.cp_r(File.join(FOLDS_DIR, "#{fold}", 'learn'), DATA_DIR)
   
   output = `#{command}`
   File.write(File.join(outDir, LEARN_FILENAME), output)

   FileUtils.rm_rf(DATA_DIR)
end

def runInference(fold, outDir)
   args = [
      '-jar', JAR_PATH,
      '-i',
      '-d', JESTER_DATA_FILE,
      '-m', JESTER_PSL_LEARNED_FILE,
      '--postgres', POSTGRES_DB,
      '-ec', '-ed',
      '-D', 'log4j.threshold=DEBUG'
   ]
   command = "#{JAVA_PATH} #{Shellwords.join(args)}"

   FileUtils.cp_r(File.join(FOLDS_DIR, "#{fold}", 'eval'), DATA_DIR)
   
   output = `#{command}`
   File.write(File.join(outDir, EVAL_FILENAME), output)
   FileUtils.mv(JESTER_PSL_LEARNED_FILE, File.join(outDir, JESTER_PSL_LEARNED_FILE))

   FileUtils.rm_rf(DATA_DIR)

   return parseOutputForStats(output)
end

# Run PSL and just get the eval stats.
def runPSL(fold)
   outDir = File.join(OUTPUT_DIR, "#{fold}")
   FileUtils.mkdir_p(outDir)

   runWeightLearning(fold, outDir)
   return runInference(fold, outDir)

   # return runInference(fold, outDir)
end

def runFold(fold)
   FileUtils.rm_rf(DATA_DIR)
   stats = runPSL(fold)

   return stats
end

def main()
   sumStats = [0.0] * STATS.size()

   puts "Fold\t#{STATS.join("\t")}"
   for i in 0...NUM_FOLDS
      stats = runFold(i)
      puts "#{i}\t#{stats.join("\t")}"

      stats.each_index{|i|
         sumStats[i] += stats[i]
      }
   end

   puts "Mean\t#{sumStats.map{|val| val / NUM_FOLDS}.join("\t")}"
end

if (__FILE__ == $0)
   main()
end
