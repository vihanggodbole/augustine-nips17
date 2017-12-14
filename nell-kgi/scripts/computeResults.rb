# This is for parsing results specific to this experiment.
# More general parsing scripts can be found in ../scripts.

# We are looking for the positive class precision of the HasCat predicate.

require_relative '../../scripts/eval'
require_relative '../../scripts/parse'
require_relative '../../scripts/util'

module NellKGIEval
   TARGET_METHODS = ['psl-admm-postgres', 'psl-maxwalksat-postgres', 'psl-mcsat-postgres', 'tuffy-maxwalksat', 'tuffy-mcsat']

   DATA_RELPATH = File.join('data', 'processed', 'eval')
   RESULTS_BASEDIR = 'out'
   TUFFY_RESULTS_FILENAME = 'results.txt'
   PSL_CAT_RESULTS_FILENAME = 'CAT.txt'
   PSL_REL_RESULTS_FILENAME = 'REL.txt'

   DATA_CAT_TARGETS_FILENAME = 'CAT_targets.txt'
   DATA_CAT_TRUTH_FILENAME = 'CAT_truth.txt'
   DATA_REL_TARGETS_FILENAME = 'REL_targets.txt'
   DATA_REL_TRUTH_FILENAME = 'REL_truth.txt'

   # Get the positive class precision.
   def NellKGIEval.parseTuffyResults(dataDir, path)
      catInferredAtoms, relInferredAtoms = Parse.tuffyAtoms(File.join(path, TUFFY_RESULTS_FILENAME))

      catTruthAtoms = Parse.truthAtoms(File.join(dataDir, DATA_CAT_TRUTH_FILENAME))
      catTargets = catTruthAtoms.keys()

      relTruthAtoms = Parse.truthAtoms(File.join(dataDir, DATA_REL_TRUTH_FILENAME))
      relTargets = relTruthAtoms.keys()

      # Since Tuffy doesn't write out false atoms, fill in the false spots.
      catTargets.each{|cat|
         if (!catInferredAtoms.include?(cat))
            catInferredAtoms[cat] = 0.0
         end
      }
      relTargets.each{|rel|
         if (!relInferredAtoms.include?(rel))
            relInferredAtoms[rel] = 0.0
         end
      }

      return [
         Evaluation.computeAUPRC(
               catTargets + relTargets,
               catInferredAtoms.merge(relInferredAtoms),
               catTruthAtoms.merge(relTruthAtoms),
               0.55),
         Evaluation.computeAUPRC(catTargets, catInferredAtoms, catTruthAtoms, 0.55),
         Evaluation.computeAUPRC(relTargets, relInferredAtoms, relTruthAtoms, 0.55),
      ]
   end

   # Get the positive class precision.
   def NellKGIEval.calcPSLResults(dataDir, path)
      catInferredAtoms = Parse.pslAtoms(File.join(path, PSL_CAT_RESULTS_FILENAME))
      catTruthAtoms = Parse.truthAtoms(File.join(dataDir, DATA_CAT_TRUTH_FILENAME))
      catTargets = catTruthAtoms.keys()

      relInferredAtoms = Parse.pslAtoms(File.join(path, PSL_REL_RESULTS_FILENAME))
      relTruthAtoms = Parse.truthAtoms(File.join(dataDir, DATA_REL_TRUTH_FILENAME))
      relTargets = relTruthAtoms.keys()

      return [
         Evaluation.computeAUPRC(
               catTargets + relTargets,
               catInferredAtoms.merge(relInferredAtoms),
               catTruthAtoms.merge(relTruthAtoms),
               0.55),
         Evaluation.computeAUPRC(catTargets, catInferredAtoms, catTruthAtoms, 0.55),
         Evaluation.computeAUPRC(relTargets, relInferredAtoms, relTruthAtoms, 0.55),
      ]
   end

   def NellKGIEval.parseResults(dataDir, path, method)
      if (method.match(/^psl-\w+-(h2|postgres)$/))
         return calcPSLResults(dataDir, path)
      elsif (method.start_with?('tuffy'))
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
         auprc, catAUPRC, relAUPRC = parseResults(dataDir, methodPath, method)

         if (auprc != nil)
            stats[method][:auprc] = auprc
         end

         if (catAUPRC != nil)
            stats[method][:cat] = catAUPRC
         end

         if (relAUPRC != nil)
            stats[method][:rel] = relAUPRC
         end
      }

      rows = []
      stats.keys().sort().each{|method|
         rows << [method, stats[method][:auprc], stats[method][:cat], stats[method][:rel]]
      }

      return rows
   end

   def NellKGIEval.getHeader()
      return ['method', 'AUPRC', 'Cat AUPRC', 'Rel AUPRC']
   end

   def NellKGIEval.printEval(baseDir)
      rows = NellKGIEval.eval(baseDir)

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

   NellKGIEval.printEval(baseDir)
end
