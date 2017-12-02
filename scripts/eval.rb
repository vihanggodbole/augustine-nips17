# Evaluation utilities.
# If a stat cannot be computed, we will always return nil or raise an exception.

require 'set'

module Evaluation
   TRUTH_THRESHOLD = 0.5

   def Evaluation.computeAccuracyCounts(targets, inferredAtoms, truthAtoms, truthThreshold = TRUTH_THRESHOLD)
      tp = 0
      fn = 0
      tn = 0
      fp = 0

      targets.each{|args|
         if (!inferredAtoms.include?(args))
            next
         end
         predicated = inferredAtoms[args] >= truthThreshold

         if (truthAtoms.include?(args))
            expected = truthAtoms[args] >= truthThreshold
         else
            expected = false
         end

         if (predicated && expected)
            tp += 1
         elsif (!predicated && !expected)
            tn += 1
         elsif (!predicated)
            fn += 1
         else
            fp += 1
         end
      }

      return tp, fn, tn, fp
   end

   # Treat the last argument of each atom as a category.
   # The truth atoms should only have entries for the category we want to assign to the preceding arguments.
   # Ex:
   #   Targets: [('a', 'x'), ('a', 'y'), ('a', 'z'), ...]
   #   Truth:   [('a', 'y'), ...]
   # We will assign "true" to the category that has the highest value (and hence use no threshold).
   def Evaluation.computeCategoricalAccuracyCounts(targets, inferredAtoms, truthAtoms)
      tp = 0
      fn = 0
      tn = 0
      fp = 0

      # Find the best categories
      # {(non-cat args) => {:args => args, :value => truthValue}, ...}
      # non-cat args = args[0...-1]
      bestCats = Hash.new{|hash, key| hash[key] = {:args => nil, :value => -1.0}}
      inferredAtoms.each{|args, value|
         if (value > bestCats[args[0...-1]][:value])
            bestCats[args[0...-1]] = {:args => args, :value => value}
         end
      }

      # Collect the args for all the best cats.
      inferredCats = Set.new(bestCats.to_a().map{|nonCatArgs, info| info[:args]})

      truthAtoms.each{|args, value|
         if (inferredCats.include?(args))
            tp += 1
         else
            fp += 1
         end
      }

      return tp, fn, tn, fp
   end

   def Evaluation.precision(targets, inferredAtoms, truthAtoms, truthThreshold = TRUTH_THRESHOLD)
      tp, fn, tn, fp = computeAccuracyCounts(targets, inferredAtoms, truthAtoms, truthThreshold)

      if (tp + fp == 0)
         return nil
      end

      return tp.to_f() / (tp + fp)
   end

   def Evaluation.categoricalPrecision(targets, inferredAtoms, truthAtoms)
      tp, fn, tn, fp = computeCategoricalAccuracyCounts(targets, inferredAtoms, truthAtoms)

      if (tp + fp == 0)
         return nil
      end

      return tp.to_f() / (tp + fp)
   end

   # Mean Squared Error
   def Evaluation.computeMSE(targets, inferredAtoms, truthAtoms)
      mse = 0.0
      count = 0

      targets.each{|target|
         if (!inferredAtoms.include?(target))
            next
         end

         truthValue = 0.0
         if (truthAtoms.include?(target))
            truthValue = truthAtoms[target]
         end

         mse += (truthValue - inferredAtoms[target]) ** 2
         count += 1
      }

      if (count == 0)
         return nil
      end

      return mse / count
   end

   # Mean Absolute Error
   def Evaluation.computeMAE(targets, inferredAtoms, truthAtoms)
      mae = 0.0
      count = 0

      targets.each{|target|
         if (!inferredAtoms.include?(target))
            next
         end

         truthValue = 0.0
         if (truthAtoms.include?(target))
            truthValue = truthAtoms[target]
         end

         mae += (truthValue - inferredAtoms[target]).abs()
         count += 1
      }

      if (count == 0)
         return nil
      end

      return mae / count
   end

   def Evaluation.computeNegativeClassAUPRC(targets, inferredAtoms, truthAtoms, truthThreshold = TRUTH_THRESHOLD)
      tn = 0
      fn = 0

      auc = 0.0
      previousPrecision = 1.0
      previousRecall = 0.0

      targets = sortTargets(targets, inferredAtoms)
      positiveCount, negativeCount = positiveNegativeCounts(targets, truthAtoms, truthThreshold)

      targets.reverse_each{|target|
         # Pretend we predict false for all targets.
         if (truthAtoms.include?(target) && truthAtoms[target] >= truthThreshold)
            fn += 1
         else
            tn += 1
         end

         precision = tn.to_f() / (tn + fn)
         recall = tn.to_f() / negativeCount

         auc += (recall - previousRecall) * ((precision + previousPrecision) / 2.0)

         previousPrecision = precision
         previousRecall = recall
      }

      # Add the final rectangle.
      auc += (1.0 - previousRecall) * ((0.0 + previousPrecision) / 2.0)

      return auc
   end

   def Evaluation.computeAUPRC(targets, inferredAtoms, truthAtoms, truthThreshold = TRUTH_THRESHOLD)
      tp = 0
      fp = 0

      auc = 0.0
      previousPrecision = 1.0
      previousRecall = 0.0

      targets = sortTargets(targets, inferredAtoms)
      positiveCount, negativeCount = positiveNegativeCounts(targets, truthAtoms, truthThreshold)

      targets.each{|target|
         # Pretend we predict true for all targets.
         if (truthAtoms.include?(target) && truthAtoms[target] >= truthThreshold)
            tp += 1
         else
            fp += 1
         end

         precision = tp.to_f() / (tp + fp)
         recall = tp.to_f() / positiveCount

         auc += (recall - previousRecall) * ((precision + previousPrecision) / 2.0)

         previousPrecision = precision
         previousRecall = recall
      }

      # Add the final rectangle.
      auc += (1.0 - previousRecall) * ((0.0 + previousPrecision) / 2.0)

      return auc
   end

   def Evaluation.computeAUROC(targets, inferredAtoms, truthAtoms, truthThreshold = TRUTH_THRESHOLD)
      tp = 0
      fp = 0

      auc = 0.0
      previousTPR = 0.0
      previousFPR = 0.0

      targets = sortTargets(targets, inferredAtoms)
      positiveCount, negativeCount = positiveNegativeCounts(targets, truthAtoms, truthThreshold)

      targets.each{|target|
         # Pretend we predict true for all targets.
         if (truthAtoms.include?(target) && truthAtoms[target] >= truthThreshold)
            tp += 1
         else
            fp += 1
         end

         tpr = tp.to_f() / positiveCount
         fpr = fp.to_f() / negativeCount

         auc += (fpr - previousFPR) * ((tpr + previousTPR) / 2.0)

         previousTPR = tpr
         previousFPR = fpr
      }

      # Add the final rectangle.
      auc += (1.0 - previousFPR) * ((1.0 + previousTPR) / 2.0)

      return auc
   end

   # Return a new list of targets sorted by truth value (the inferred value, not the value from the truth set).
   def Evaluation.sortTargets(targets, inferredAtoms, desc = true)
      targets = targets.select{|target| inferredAtoms.include?(target)}
      targets.sort!{|a, b|
         if (desc)
            inferredAtoms[b] <=> inferredAtoms[a]
         else
            inferredAtoms[a] <=> inferredAtoms[b]
         end
      }

      return targets
   end

   # Note that we observe the closed world assumption, so we only look for
   # positive examples and then compute the negative count.
   def Evaluation.positiveNegativeCounts(targets, truthAtoms, truthThreshold = TRUTH_THRESHOLD)
      positiveCount = 0

      targets.each{|target|
         if (truthAtoms.include?(target) && truthAtoms[target] >= truthThreshold)
            positiveCount += 1
         end
      }

      return positiveCount, targets.size() - positiveCount
   end
end
