# This is for parsing results specific to this experiment.
# More general parsing scripts can be found in ../scripts.

# We are looking for the positive class precision of the HasCat predicate.

require_relative '../../scripts/eval'
require_relative '../../scripts/parse'
require_relative '../../scripts/util'

module JesterEval
   FOLDS = (0...10).to_a()
   TARGET_METHODS = ['psl-admm-postgres', 'psl-maxwalksat-postgres', 'psl-mcsat-postgres', 'tuffy']

   DATA_RELPATH = File.join('data', 'splits')
   RESULTS_BASEDIR = 'out'
   TUFFY_RESULTS_FILENAME = 'results.txt'
   PSL_RESULTS_FILENAME = 'RATING.txt'

   DATA_TARGETS_FILENAME = 'rating_targets.txt'
   DATA_TRUTH_FILENAME = 'rating_truth.txt'

   # Get the positive class precision.
   def JesterEval.parseTuffyResults(dataDir, path)
      inferredAtoms = Parse.tuffyAtoms(File.join(path, TUFFY_RESULTS_FILENAME))
      truthAtoms = Parse.truthAtoms(File.join(dataDir, DATA_TRUTH_FILENAME))
      targets = Parse.targetAtoms(File.join(dataDir, DATA_TARGETS_FILENAME))

      return [
         Evaluation.computeMAE(targets, inferredAtoms, truthAtoms),
         Evaluation.computeMSE(targets, inferredAtoms, truthAtoms)
      ]
   end

   # Get the positive class precision.
   def JesterEval.calcPSLResults(dataDir, path)
      inferredAtoms = Parse.pslAtoms(File.join(path, PSL_RESULTS_FILENAME))
      truthAtoms = Parse.truthAtoms(File.join(dataDir, DATA_TRUTH_FILENAME))
      targets = Parse.targetAtoms(File.join(dataDir, DATA_TARGETS_FILENAME))

      return [
         Evaluation.computeMAE(targets, inferredAtoms, truthAtoms),
         Evaluation.computeMSE(targets, inferredAtoms, truthAtoms)
      ]
   end

   def JesterEval.parseResults(dataDir, path, method)
      if (method.match(/^psl-\w+-(h2|postgres)$/))
         return calcPSLResults(dataDir, path)
      elsif (method == 'tuffy')
         return parseTuffyResults(dataDir, path)
      else
         raise("ERROR: Unsupported method: '#{method}'.")
      end
   end

   def JesterEval.eval(baseDir)
      # {method => {:stat => [value, ...], ...}, ...}
      stats = Hash.new{|hash, key| hash[key] = Hash.new{|innerHash, innerKey| innerHash[innerKey] = []}}

      Util.listDir(File.join(baseDir, RESULTS_BASEDIR)){|method, methodPath|
         if (!TARGET_METHODS.include?(method))
            next
         end

         Util.listDir(methodPath){|fold, foldPath|
            dataDir = File.join(baseDir, DATA_RELPATH, fold, 'eval')
            mae, mse = parseResults(dataDir, foldPath, method)

            if (mae != nil)
               stats[method][:mae] << mae
            end

            if (mse != nil)
               stats[method][:mse] << mse
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

         mae = Util.mean(stats[method][:mae])
         mse = Util.mean(stats[method][:mse])

         rows << [method, mae, mse]
      }

      return rows
   end

   def JesterEval.getHeader()
      return ['method', 'MAE', 'MSE']
   end

   def JesterEval.printEval(baseDir)
      rows = JesterEval.eval(baseDir)

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

   JesterEval.printEval(baseDir)
end
