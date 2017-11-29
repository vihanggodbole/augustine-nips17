# General file parsing utilities specific to PSL and Tuffy.

module Parse
   NUM_REGEX = '-?\d+(?:\.\d+)?'

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

            if (match = line.match(/^(#{NUM_REGEX})\t(\w+)\(([^)]+)\)\s+\/\//))
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
               stats[predicate][:mae] = match[2].to_f()
               stats[predicate][:mse] = match[3].to_f()
            elsif (match = line.match(/ - Discrete evaluation results for (\w+) -- Accuracy: (#{NUM_REGEX}), Error: (#{NUM_REGEX}), Positive Class Precision: (#{NUM_REGEX}), Positive Class Recall: (#{NUM_REGEX}), Negative Class Precision: (#{NUM_REGEX}), Negative Class Recall: (#{NUM_REGEX}),$/))
               predicate = match[1]
               stats[predicate][:accuracy] = match[2].to_f()
               stats[predicate][:error] = match[3].to_f()
               stats[predicate][:positiveClassPrecision] = match[4].to_f()
               stats[predicate][:positiveClassRecall] = match[5].to_f()
               stats[predicate][:negativeClassPrecision] = match[6].to_f()
               stats[predicate][:negativeClassRecall] = match[7].to_f()
            end
         }
      }

      return stats['HASCAT'][:positiveClassPrecision]
   end
end
