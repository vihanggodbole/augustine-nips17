# This is for parsing results specific to this experiment.
# More general parsing scripts can be found in ../scripts.

# We are looking for the positive class precision of the HasCat predicate.

require_relative '../../scripts/eval'
require_relative '../../scripts/parse'
require_relative '../../scripts/util'

DATASETS = ['citeseer', 'cora']
FOLDS = (0...20).to_a()
TARGET_METHODS = ['psl-admm-h2', 'psl-maxwalksat-h2', 'psl-mcsat-h2', 'tuffy']

DATA_RELPATH = File.join('data', 'splits')
RESULTS_BASEDIR = 'out'
TUFFY_RESULTS_FILENAME = 'results.txt'
PSL_RESULTS_FILENAME = 'HASCAT.txt'

DATA_TARGETS_FILENAME = 'hasCat_targets.txt'
DATA_TRUTH_FILENAME = 'hasCat_truth.txt'

module CollectiveClassificationEval
   # Get the positive class precision.
   def CollectiveClassificationEval.parseTuffyResults(dataDir, path, dataset, fold)
      inferredAtoms = Parse.tuffyAtoms(File.join(path, TUFFY_RESULTS_FILENAME))
      truthAtoms = Parse.truthAtoms(File.join(dataDir, DATA_TRUTH_FILENAME))
      targets = Parse.targetAtoms(File.join(dataDir, DATA_TARGETS_FILENAME))

      return Evaluation.precision(targets, inferredAtoms, truthAtoms)
   end

   # Get the positive class precision.
   def CollectiveClassificationEval.calcPSLResults(dataDir, path, dataset, fold)
      inferredAtoms = Parse.pslAtoms(File.join(path, PSL_RESULTS_FILENAME))
      truthAtoms = Parse.truthAtoms(File.join(dataDir, DATA_TRUTH_FILENAME))
      targets = Parse.targetAtoms(File.join(dataDir, DATA_TARGETS_FILENAME))

      if (inferredAtoms.size() == 0)
         return nil
      end

      return Evaluation.precision(targets, inferredAtoms, truthAtoms)
   end

   def CollectiveClassificationEval.parseResults(dataDir, path, method, dataset, fold)
      if (method.match(/^psl-\w+-(h2|postgres)$/))
         return calcPSLResults(dataDir, path, dataset, fold)
      elsif (method == 'tuffy')
         return parseTuffyResults(dataDir, path, dataset, fold)
      else
         raise("ERROR: Unsupported method: '#{method}'.")
      end
   end

   def CollectiveClassificationEval.eval(baseDir)
      # {method => {dataset => [foldPrecision, ...], ...}, ...}
      stats = Hash.new{|hash, key| hash[key] = Hash.new{|innerHash, innerKey| innerHash[innerKey] = []}}

      Util.listDir(File.join(baseDir, RESULTS_BASEDIR)){|method, methodPath|
         if (!TARGET_METHODS.include?(method))
            next
         end

         Util.listDir(methodPath){|dataset, datasetPath|
            Util.listDir(datasetPath){|fold, foldPath|
               dataDir = File.join(baseDir, DATA_RELPATH, dataset, fold, 'eval')
               stats[method][dataset] << parseResults(dataDir, foldPath, method, dataset, fold)
            }

            if (stats[method][dataset].size() != FOLDS.size())
               raise "Incorrect number of folds for #{datasetPath}. Expected #{FOLDS.size()}, Found: #{stats[method][dataset].size()}."
            end
         }

         if (stats[method].size() != DATASETS.size())
            raise "Incorrect number of datasets for #{methodPath}. Expected #{DATASETS.size()}, Found: #{stats[method].size()}."
         end
      }

      stats.keys().sort().each{|method|
         stats[method].keys().sort().each{|dataset|
            if (stats[method][dataset] == ([nil] * FOLDS.size()))
               next
            end

            puts [method, dataset, Util.mean(stats[method][dataset])].join("\t")
         }
      }
   end
end

if ($0 == __FILE__)
   # Parse args
   args = ARGV

   if (args.size() > 1 || args.map{|arg| arg.gsub('-', '').downcase()}.include?('help'))
      puts "USAGE: ruby #{$0} [base experiment dir]"
      puts "   Will use this directory if one it not provided."
      exit(1)
   end

   baseDir = '.'
   if (args.size() > 0)
      baseDir = args.shift()
   end

   CollectiveClassificationEval.eval(baseDir)
end