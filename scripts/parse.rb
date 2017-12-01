# General file parsing utilities specific to PSL and Tuffy.

module Parse
   EVAL_OUTPUT_FILENAME = 'out-eval.txt'

   NUM_REGEX = '-?\d+(?:\.\d+)?'

   MAE = 'mae'
   MSE = 'mse'
   ACCURACY = 'accuracy'
   ERROR = 'error'
   POSITIVE_CLASS_PRECISION = 'positiveClassPrecision'
   POSITIVE_CLASS_RECALL = 'positiveClassRecall'
   NEGATIVE_CLASS_PRECISION = 'negativeClassPrecision'
   NEGATIVE_CLASS_RECALL = 'negativeClassRecall'

   NUM_GROUNDINGS = 'numGroundings'
   DATA_LOADING_TIME = 'dataLoading'
   GROUNDING_TIME = 'grounding'
   INFERENCE_TIME = 'inference'
   COMMITTING_RESULTS_TIME = 'committingResults'
   TOTAL_TIME = 'total'

   @@cache = {}

   # Tuffy puts all the atoms in a single file (even if there are multiple open predicates).
   # Each predicate will be passed back as its own map (in lexicographic order).
   # Will also check to see if the atoms are marginal or not.
   # Non-marginal atoms get a 1.0 truth value.
   def Parse.tuffyAtoms(path)
      # {predicate => {[arg0, arg1, ...] => value, ...}, ...}
      atoms = Hash.new{|hash, key| hash[key] = {}}

      File.open(path, 'r'){|file|
         file.each{|line|
            line.strip!()

            if (match = line.match(/^(#{NUM_REGEX})\t(\w+)\(([^)]+)\)/))
               predicate = match[2]
               args = match[3].split(", ")
               value = match[1].to_f()
            elsif (match = line.match(/^(\w+)\(([^)]+)\)/))
               predicate = match[1]
               args = match[2].split(", ")
               value = 1.0
            else
               raise "Unrecognized line (#{file.lineno}) in #{path}: #{line}"
            end

            atoms[predicate][args] = value
         }
      }

      return atoms.to_a().sort().map{|predicate, values| values}
   end

   def Parse.pslAtoms(path)
      # {[arg0, arg1, ...] => value, ...}
      atoms = {}

      if (!File.exists?(path))
         return {}
      end

      File.open(path, 'r'){|file|
         file.each{|line|
            parts = line.strip().split("\t")
            args = parts[0...2].map{|arg| arg.sub(/^'/, '').sub(/'$/, '')}

            atoms[args] = parts[-1].to_f()
         }
      }

      return atoms
   end

   def Parse.targetAtoms(path)
      if (cacheEntry = @@cache[path])
         return cacheEntry
      end

      # [[arg0, arg1, ...], ...]
      atoms = []

      File.open(path, 'r'){|file|
         file.each{|line|
            atoms << line.strip().split("\t")
         }
      }

      @@cache[path] = atoms
      return atoms
   end

   def Parse.truthAtoms(path)
      if (cacheEntry = @@cache[path])
         return cacheEntry
      end

      # {[arg0, arg1, ...] => value, ...}
      atoms = {}

      File.open(path, 'r'){|file|
         file.each{|line|
            parts = line.strip().split("\t")

            args = parts[0...2]
            atoms[args] = parts[-1].to_f()
         }
      }

      @@cache[path] = atoms
      return atoms
   end

   def Parse.pslEvalOutput(path)
      # {predicate => {stat => value, ...}, ...}
      stats = Hash.new{|hash, key| hash[key] = {}}

      File.open(path, 'r'){|file|
         file.each{|line|
            line.strip!()

            if (match = line.match(/ - Continuous evaluation results for (\w+) -- MAE: (#{NUM_REGEX}), MSE: (#{NUM_REGEX})$/))
               predicate = match[1]
               stats[predicate][MAE] = match[2].to_f()
               stats[predicate][MSE] = match[3].to_f()
            elsif (match = line.match(/ - Discrete evaluation results for (\w+) -- Accuracy: (#{NUM_REGEX}), Error: (#{NUM_REGEX}), Positive Class Precision: (#{NUM_REGEX}), Positive Class Recall: (#{NUM_REGEX}), Negative Class Precision: (#{NUM_REGEX}), Negative Class Recall: (#{NUM_REGEX}),$/))
               predicate = match[1]
               stats[predicate][ACCURACY] = match[2].to_f()
               stats[predicate][ERROR] = match[3].to_f()
               stats[predicate][POSITIVE_ClassPrecision] = match[4].to_f()
               stats[predicate][POSITIVE_CLASS_RECALL] = match[5].to_f()
               stats[predicate][NEGATIVE_CLASS_PRECISION] = match[6].to_f()
               stats[predicate][NEGATIVE_CLASS_RECALL] = match[7].to_f()
            end
         }
      }

      return stats
   end

   def Parse.pslRun(path)
      stats = {}

      File.open(File.join(path, EVAL_OUTPUT_FILENAME), 'r'){|file|
         startTime = nil
         time = nil

         file.each{|line|
            line.strip!()

            if (match = line.match(/^(\d+)\s/))
               time = match[1].to_i()
            end

            if (match = line.match(/- Loading data for.*$/))
               if (startTime != nil)
                  next
               end

               startTime = time
            elsif (match = line.match(/- Data loading complete$/))
               stats[DATA_LOADING_TIME] = time - startTime
            elsif (match = line.match(/- Grounding out model\.$/))
               startTime = time
            elsif (match = line.match(/- Initializing objective terms for (\d+) ground rules\.$/))
               stats[NUM_GROUNDINGS] = match[1].to_i()
               stats[GROUNDING_TIME] = time - startTime
            elsif (match = line.match(/- Beginning inference\.$/))
               startTime = time
            elsif (match = line.match(/- Inference complete. Writing results to Database\.$/))
               stats[INFERENCE_TIME] = time - startTime
               startTime = time
            elsif (match = line.match(/- Inference Complete$/))
               stats[COMMITTING_RESULTS_TIME] = time - startTime
               stats[TOTAL_TIME] = time
            end
         }
      }

      return stats
   end

   def Parse.tuffyRun(path)
      stats = {}

      File.open(File.join(path, EVAL_OUTPUT_FILENAME), 'r'){|file|
         startTime = nil
         time = nil

         file.each{|line|
            line.strip!()

            if (match = line.match(/^(\d+)\s/))
               time = match[1].to_i()
            end

            if (match = line.match(/\s+>>> Parsing evidence file:.*$/))
               startTime = time
            elsif (match = line.match(/\s+>>> Grounding...$/))
               stats[DATA_LOADING_TIME] = time - startTime
               startTime = time
            elsif (match = line.match(/\s+### atoms = ([\d,]+); clauses = ([\d,]+)/))
               stats[NUM_GROUNDINGS] = match[2].gsub(',', '').to_i()
            elsif (match = line.match(/\s+>>> Grouping Components into Buckets...$/))
               stats[GROUNDING_TIME] = time - startTime
               startTime = time
            elsif (match = line.match(/\s+flushing states of/))
               stats[INFERENCE_TIME] = time - startTime
               startTime = time
            elsif (match = line.match(/\s+>>> Cleaning up temporary data$/))
               stats[COMMITTING_RESULTS_TIME] = time - startTime
            end
         }

         stats[TOTAL_TIME] = time
      }

      return stats
   end
end
