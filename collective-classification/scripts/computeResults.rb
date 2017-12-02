# This is for parsing results specific to this experiment.
# More general parsing scripts can be found in ../scripts.

# We are looking for the positive class precision of the HasCat predicate.

require_relative '../../scripts/eval'
require_relative '../../scripts/parse'
require_relative '../../scripts/util'

module CollectiveClassificationEval
   DATASETS = ['citeseer', 'cora']
   FOLDS = (0...20).to_a()
   TARGET_METHODS = ['psl-admm-postgres', 'psl-maxwalksat-postgres', 'psl-mcsat-postgres', 'tuffy']

   DATA_RELPATH = File.join('data', 'splits')
   RESULTS_BASEDIR = 'out'
   TUFFY_RESULTS_FILENAME = 'results.txt'
   PSL_RESULTS_FILENAME = 'HASCAT.txt'

   DATA_TARGETS_FILENAME = 'hasCat_targets.txt'
   DATA_TRUTH_FILENAME = 'hasCat_truth.txt'

   # Get the positive class precision.
   def CollectiveClassificationEval.parseTuffyResults(dataDir, path)
      inferredAtoms = Parse.tuffyAtoms(File.join(path, TUFFY_RESULTS_FILENAME))[0]
      truthAtoms = Parse.truthAtoms(File.join(dataDir, DATA_TRUTH_FILENAME))
      targets = Parse.targetAtoms(File.join(dataDir, DATA_TARGETS_FILENAME))

      return Evaluation.categoricalPrecision(targets, inferredAtoms, truthAtoms)
   end

   # Get the positive class precision.
   def CollectiveClassificationEval.calcPSLResults(dataDir, path)
      inferredAtoms = Parse.pslAtoms(File.join(path, PSL_RESULTS_FILENAME))
      truthAtoms = Parse.truthAtoms(File.join(dataDir, DATA_TRUTH_FILENAME))
      targets = Parse.targetAtoms(File.join(dataDir, DATA_TARGETS_FILENAME))

      return Evaluation.categoricalPrecision(targets, inferredAtoms, truthAtoms)
   end

   def CollectiveClassificationEval.parseResults(dataDir, path, method)
      if (method.match(/^psl-\w+-(h2|postgres)$/))
         return calcPSLResults(dataDir, path)
      elsif (method == 'tuffy')
         return parseTuffyResults(dataDir, path)
      else
         raise("ERROR: Unsupported method: '#{method}'.")
      end
   end

   def CollectiveClassificationEval.eval(baseDir)
      # {method => {dataset => {:stat => [value, ...], ...}, ...}, ...}
      stats = Hash.new{|hash, key|
         hash[key] = Hash.new{|innerHash, innerKey|
            innerHash[innerKey] = Hash.new{|statHash, statKey| statHash[statKey] = []}
         }
      }

      Util.listDir(File.join(baseDir, RESULTS_BASEDIR)){|method, methodPath|
         if (!TARGET_METHODS.include?(method))
            next
         end

         Util.listDir(methodPath){|dataset, datasetPath|
            Util.listDir(datasetPath){|fold, foldPath|
               dataDir = File.join(baseDir, DATA_RELPATH, dataset, fold, 'eval')
               precision = parseResults(dataDir, foldPath, method)

               if (precision != nil)
                  stats[method][dataset][:precision] << precision
               end
            }

            stats[method][dataset].each{|key, values|
               if (stats[method][dataset][key].size() != FOLDS.size())
                  puts "WARNING: Incorrect number of folds for #{datasetPath}[#{key}]. Expected #{FOLDS.size()}, Found: #{stats[method][dataset][key].size()}."
               end
            }
         }

         if (stats[method].size() != DATASETS.size())
            puts "WARNING: Incorrect number of datasets for #{methodPath}. Expected #{DATASETS.size()}, Found: #{stats[method].size()}."
         end
      }

      rows = []
      stats.keys().sort().each{|method|
         stats[method].keys().sort().each{|dataset|
            if (stats[method][dataset].size() == 0)
               next
            end

            precision = Util.mean(stats[method][dataset][:precision])

            rows << [method, dataset, precision]
         }
      }

      return rows
   end

   def CollectiveClassificationEval.getHeader()
      return ['method', 'dataset', 'precision']
   end

   def CollectiveClassificationEval.printEval(baseDir)
      rows = CollectiveClassificationEval.eval(baseDir)

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

   CollectiveClassificationEval.printEval(baseDir)
end
