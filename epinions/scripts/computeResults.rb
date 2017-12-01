# This is for parsing results specific to this experiment.
# More general parsing scripts can be found in ../scripts.

# We are looking for the positive class precision of the HasCat predicate.

require_relative '../../scripts/eval'
require_relative '../../scripts/parse'
require_relative '../../scripts/util'

module EpinionsEvaluation
   FOLDS = (0...8).to_a()
   TARGET_METHODS = ['psl-admm-postgres', 'psl-maxwalksat-postgres', 'psl-mcsat-postgres', 'tuffy']

   DATA_RELPATH = File.join('data', 'splits')
   RESULTS_BASEDIR = 'out'
   TUFFY_RESULTS_FILENAME = 'results.txt'
   PSL_RESULTS_FILENAME = 'TRUSTS.txt'

   DATA_TARGETS_FILENAME = 'trusts_target.txt'
   DATA_TRUTH_FILENAME = 'trusts_truth.txt'

   # Get the positive class precision.
   def EpinionsEvaluation.parseTuffyResults(dataDir, path, fold)
      inferredAtoms = Parse.tuffyAtoms(File.join(path, TUFFY_RESULTS_FILENAME))[0]
      truthAtoms = Parse.truthAtoms(File.join(dataDir, DATA_TRUTH_FILENAME))
      targets = truthAtoms.keys()

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
      targets = truthAtoms.keys()

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

            if (auroc != nil)
               stats[method][:auroc] << auroc
            end

            if (auprc != nil)
               stats[method][:auprc] << auprc
            end

            if (nauprc)
               stats[method][:nauprc] << nauprc
            end
         }

         stats[method].each{|key, values|
            if (stats[method][key].size() != FOLDS.size())
               puts "WARNING: Incorrect number of folds for #{methodPath}[#{key}]. Expected #{FOLDS.size()}, Found: #{stats[method][key].size()}."
            end
         }
      }

      rows = []
      stats.keys().sort().each{|method|
         if (stats[method].size() == 0)
            next
         end

         auroc = Util.mean(stats[method][:auroc])
         auprc = Util.mean(stats[method][:auprc])
         nauprc = Util.mean(stats[method][:nauprc])

         rows << [method, auroc, auprc, nauprc]
      }

      return rows
   end

   def EpinionsEvaluation.getHeader()
      return ['method', 'AUROC', 'Positive Class AUPRC', 'Negative Class AUPRC']
   end

   def EpinionsEvaluation.printEval(baseDir)
      rows = EpinionsEvaluation.eval(baseDir)

      puts getHeader().join("\t")
      puts rows.map{|row| row.join("\t")}.join("\n")
   end
end

if ($0 == __FILE__)
   # Parse args
   args = ARGV

   if (args.size() > 1 || args.map{|arg| arg.gsub('-', '').downcase()}.include?('help'))
      puts "USAGE: ruby #{$0} [base experiment dir]"
      puts "   Will use the parent of the directory where this script lives if one it not provided."
      exit(1)
   end

   baseDir = File.dirname(File.dirname(File.absolute_path($0)))
   if (args.size() > 0)
      baseDir = args.shift()
   end

   EpinionsEvaluation.printEval(baseDir)
end
