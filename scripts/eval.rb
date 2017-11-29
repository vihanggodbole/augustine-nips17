# Evaluation utilities.

module Evaluation
   TRUTH_THREHSOLD = 0.5

   def Evaluation.computeAccuracyCounts(targets, predicatedAtoms, truthAtoms)
      tp = 0
      fn = 0
      tn = 0
      fp = 0

      targets.each{|args|
         if (!predicatedAtoms.include?(args))
            next
         end
         predicated = predicatedAtoms[args] >= TRUTH_THREHSOLD

         if (truthAtoms.include?(args))
            expected = truthAtoms[args] >= TRUTH_THREHSOLD
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
end
