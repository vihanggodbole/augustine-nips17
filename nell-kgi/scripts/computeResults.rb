# This is for parsing results specific to this experiment.
# More general parsing scripts can be found in ../scripts.

# We are looking for the positive class precision of the HasCat predicate.

require_relative '../../scripts/eval'
require_relative '../../scripts/parse'
require_relative '../../scripts/util'

TARGET_METHODS = ['psl-admm-h2', 'psl-maxwalksat-h2', 'psl-mcsat-h2', 'tuffy']

DATA_RELPATH = File.join('data', 'processed', 'eval')
RESULTS_BASEDIR = 'out'
TUFFY_RESULTS_FILENAME = 'results.txt'
PSL_CAT_RESULTS_FILENAME = 'CAT.txt'
PSL_REL_RESULTS_FILENAME = 'REL.txt'

DATA_CAT_TARGETS_FILENAME = 'cat_targets.txt'
DATA_CAT_TRUTH_FILENAME = 'cat_truth.txt'
DATA_REL_TARGETS_FILENAME = 'rel_targets.txt'
DATA_REL_TRUTH_FILENAME = 'rel_truth.txt'

module NellKGIEval
   # Get the positive class precision.
   def NellKGIEval.parseTuffyResults(dataDir, path)
      catInferredAtoms, relInferredAtoms = Parse.tuffyAtoms(File.join(path, PSL_CAT_RESULTS_FILENAME))

      catTruthAtoms = Parse.truthAtoms(File.join(dataPath, DATA_CAT_TRUTH_FILENAME))
      catTargets = Parse.targetAtoms(File.join(dataPath, DATA_CAT_TARGETS_FILENAME))

      relTruthAtoms = Parse.truthAtoms(File.join(dataPath, DATA_REL_TRUTH_FILENAME))
      relTargets = Parse.targetAtoms(File.join(dataPath, DATA_REL_TARGETS_FILENAME))

      if (catInferredAtoms.size() == 0 || relInferredAtoms.size() == 0)
         return nil, nil
      end

      return [
         Evaluation.computeAUPRC(catTargets, catInferredAtoms, catTruthAtoms),
         Evaluation.computeAUPRC(relTargets, relInferredAtoms, relTruthAtoms),
      ]
   end

   # Get the positive class precision.
   def NellKGIEval.calcPSLResults(dataDir, path)
      catInferredAtoms = Parse.pslAtoms(File.join(path, PSL_CAT_RESULTS_FILENAME))
      catTruthAtoms = Parse.truthAtoms(File.join(dataPath, DATA_CAT_TRUTH_FILENAME))
      catTargets = Parse.targetAtoms(File.join(dataPath, DATA_CAT_TARGETS_FILENAME))

      relInferredAtoms = Parse.pslAtoms(File.join(path, PSL_REL_RESULTS_FILENAME))
      relTruthAtoms = Parse.truthAtoms(File.join(dataPath, DATA_REL_TRUTH_FILENAME))
      relTargets = Parse.targetAtoms(File.join(dataPath, DATA_REL_TARGETS_FILENAME))

      if (catInferredAtoms.size() == 0 || relInferredAtoms.size() == 0)
         return nil, nil
      end

      return [
         Evaluation.computeAUPRC(catTargets, catInferredAtoms, catTruthAtoms),
         Evaluation.computeAUPRC(relTargets, relInferredAtoms, relTruthAtoms),
      ]
   end

   def NellKGIEval.parseResults(dataDir, path, method)
      if (method.match(/^psl-\w+-(h2|postgres)$/))
         return calcPSLResults(dataDir, path)
      elsif (method == 'tuffy')
         return parseTuffyResults(dataDir, path)
      else
         raise("ERROR: Unsupported method: '#{method}'.")
      end
   end

   def NellKGIEval.eval(baseDir)
      # {method => {:stat => value, ...}, ...}
      stats = Hash.new{|hash, key| hash[key] = {}}

      Util.listDir(File.join(baseDir, RESULTS_BASEDIR)){|method, methodPath|
         if (!TARGET_METHODS.include?(method))
            next
         end

         dataDir = File.join(baseDir, DATA_RELPATH)

         catAUPRC, relAUPRC = parseResults(methodPath, method)
         stats[method][:cat] = catAUPRC
         stats[method][:rel] = relAUPRC
      }

      puts ['method', 'Cat AUPRC', 'Rel AUPRC'].join("\t")
      stats.keys().sort().each{|method|
         puts [method, stats[:cat], stats[:rel]].join("\t")
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

   NellKGIEval.eval(baseDir)
end
