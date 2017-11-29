# This is for parsing results specific to this experiment.
# More general parsing scripts can be found in ../scripts.

# We are looking for the positive class precision of the HasCat predicate.

require_relative '../../scripts/eval'
require_relative '../../scripts/parse'
require_relative '../../scripts/util'

FOLDS = (0...8).to_a()
TARGET_METHODS = ['psl-admm-h2', 'psl-maxwalksat-h2', 'psl-mcsat-h2', 'tuffy']

DATA_RELPATH = File.join('data', 'splits')
RESULTS_BASEDIR = 'out'
TUFFY_RESULTS_FILENAME = 'results.txt'
PSL_RESULTS_FILENAME = 'TRUSTS.txt'

DATA_TARGETS_FILENAME = 'trusts_target.txt'
DATA_TRUTH_FILENAME = 'trusts_truth.txt'

module EpinionsEvaluation
   # Get the positive class precision.
   def EpinionsEvaluation.parseTuffyResults(dataDir, path, fold)
      inferredAtoms = Parse.tuffyAtoms(File.join(path, TUFFY_RESULTS_FILENAME))
      truthAtoms = Parse.truthAtoms(File.join(dataDir, DATA_TRUTH_FILENAME))
      targets = Parse.targetAtoms(File.join(dataDir, DATA_TARGETS_FILENAME))

      return [
         Evaluation.computeAUROC(targets, inferredAtoms, truthAtoms),
         Evaluation.computeAUPRC(targets, inferredAtoms, truthAtoms),
         Evaluation.computeNegativeClassAUPRC(targets, inferredAtoms, truthAtoms)
      ]
   end

   # Get the positive class precision.
   def EpinionsEvaluation.calcPSLResults(dataDir, path, fold)
      inferredAtoms = Parse.pslAtoms(File.join(path, PSL_RESULTS_FILENAME))
      truthAtoms = Parse.truthAtoms(File.join(dataDir, DATA_TRUTH_FILENAME))
      targets = Parse.targetAtoms(File.join(dataDir, DATA_TARGETS_FILENAME))

      if (inferredAtoms.size() == 0)
         return nil
      end

      return [
         Evaluation.computeAUROC(targets, inferredAtoms, truthAtoms),
         Evaluation.computeAUPRC(targets, inferredAtoms, truthAtoms),
         Evaluation.computeNegativeClassAUPRC(targets, inferredAtoms, truthAtoms)
      ]
   end

   def EpinionsEvaluation.parseResults(dataDir, path, method, fold)
      if (method.match(/^psl-\w+-(h2|postgres)$/))
         return calcPSLResults(dataDir, path, fold)
      elsif (method == 'tuffy')
         return parseTuffyResults(dataDir, path, fold)
      else
         raise("ERROR: Unsupported method: '#{method}'.")
      end
   end

   def EpinionsEvaluation.eval(baseDir)
      # {method => {:stat => [value, ...], ...}, ...}
      stats = Hash.new{|hash, key| hash[key] = Hash.new{|innerHash, innerKey| innerHash[innerKey] = []}}

      Util.listDir(File.join(baseDir, RESULTS_BASEDIR)){|method, methodPath|
         if (!TARGET_METHODS.include?(method))
            next
         end

         Util.listDir(methodPath){|fold, foldPath|
            dataDir = File.join(baseDir, DATA_RELPATH, fold, 'eval')

            auroc, auprc, nauprc = parseResults(dataDir, foldPath, method, fold)
            stats[method][:auroc] << auroc
            stats[method][:auprc] << auprc
            stats[method][:nauprc] << nauprc
         }

         if (stats[method][:auroc].size() != FOLDS.size())
            raise "Incorrect number of folds for #{methodPath}. Expected #{FOLDS.size()}, Found: #{stats[method].size()}."
         end
      }

      stats.keys().sort().each{|method|
         if (stats[method] == ([nil] * FOLDS.size()))
            next
         end

         auroc = Util.mean(stats[method][:auroc])
         auprc = Util.mean(stats[method][:auprc])
         nauprc = Util.mean(stats[method][:nauprc])

         puts [method, auroc, auprc, nauprc].join("\t")
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

   EpinionsEvaluation.eval(baseDir)
end
