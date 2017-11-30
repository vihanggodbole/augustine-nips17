# A module to help process timings on carious methods.

require_relative 'parse'
require_relative 'util'

RESULTS_BASEDIR = 'out'

class Timing
   def initialize(baseDir, targetMethods, numDatasets, numFolds)
      @baseDir = baseDir
      @targetMethods = targetMethods
      @numDatasets = numDatasets
      @numFolds = numFolds
   end

   def parseTuffyResults(path)
      stats = Parse.tuffyRun(path)
      return [
         stats[Parse::GROUNDING_TIME],
         stats[Parse::INFERENCE_TIME],
         stats[Parse::TOTAL_TIME]
      ]
   end

   # Get the positive class precision.
   def calcPSLResults(path)
      stats = Parse.pslRun(path)
      return [
         stats[Parse::GROUNDING_TIME],
         stats[Parse::INFERENCE_TIME],
         stats[Parse::TOTAL_TIME]
      ]
   end

   def parseResults(path, method)
      if (method.match(/^psl-\w+-(h2|postgres)$/))
         return calcPSLResults(path)
      elsif (method == 'tuffy')
         return parseTuffyResults(path)
      else
         raise("ERROR: Unsupported method: '#{method}'.")
      end
   end

   def parse()
      stats = {}

      Util.listDir(File.join(@baseDir, RESULTS_BASEDIR)){|method, methodPath|
         if (!@targetMethods.include?(method))
            next
         end

         if (@numDatasets > 0)
            stats[method] = parseDatasets(methodPath, method)
         elsif (@numFolds > 0)
            stats[method] = parseFolds(methodPath, method)
         else
            stats[method] = parseDir(methodPath, method)
         end
      }

      return stats
   end

   # Parse a directory that contains all the datasets.
   def parseDatasets(path, method)
      stats = {}

      Util.listDir(path){|dataset, datasetPath|
         stats[dataset] = parseFolds(datasetPath, method)
      }

      if (stats.size() != @numDatasets)
         puts "WARNING: Incorrect number of datasets for #{path}. Expected #{@numDatasets}, Found: #{stats.size()}."
      end

      return stats
   end

   # Parse a directory that contains all the folds.
   def parseFolds(path, method)
      stats = Hash.new{|hash, key| hash[key] = []}

      Util.listDir(path){|fold, foldPath|
         foldStats = parseDir(foldPath, method)

         foldStats.each{|statKey, value|
            stats[statKey] << value
         }
      }

      stats.each{|statKey, values|
         if (values.size() != @numFolds)
            puts "WARNING: Incorrect number of folds for #{path}[#{statKey}]. Expected #{@numFolds}, Found: #{values.size()}."
         end
      }

      return stats
   end

   # Parse a dir that contains the actual output files.(
   def parseDir(path, method)
      stats = {}

      grounding, inference, total = parseResults(path, method)

      if (grounding != nil)
         stats[:grounding] = grounding
      end

      if (inference != nil)
         stats[:inference] = inference
      end

      if (total != nil)
         stats[:total] = total
      end

      return stats
   end

   def printStats(stats, aggregate = true)
      header = getHeader(aggregate)
      rows = flattenStats(stats, aggregate)

      puts header.join("\t")
      rows.each{|row|
         puts row.join("\t")
      }
   end

   def getHeader(aggregate = true)
      header = ['method']

      if (@numDatasets > 0)
         header << 'dataset'
      end

      if (@numFolds > 0 && !aggregate)
         header << 'fold'
      end

      header += ['grounding (ms)', 'inference (ms)', 'total (ms)']
      return header
   end

   # WARNING: If some experiments are missing folds, then the output will not be properly aligned.
   # (ie if the first fold is missing, we will report the second fold as the first.)
   def flattenStats(stats, aggregate = true)
      flatStats = []

      stats.each{|method, methodStats|
         if (methodStats.size() == 0)
            next
         end

         row = [method]

         if (@numDatasets > 0)
            flatStats += flattenDatasetStats(row, methodStats, aggregate)
         elsif (@numFolds > 0)
            flatStats += flattenFoldStats(row, methodStats, aggregate)
         else
            flatStats += flattenRowStats(row, methodStats)
         end
      }

      flatStats
   end

   def flattenDatasetStats(row, stats, aggregate)
      flatStats = []

      stats.each{|dataset, datasetStats|
         if (datasetStats.size() == 0)
            next
         end

         datasetRow = row + [dataset]
         flatStats += flattenFoldStats(datasetRow, datasetStats, aggregate)
      }

      return flatStats
   end

   def flattenFoldStats(row, stats, aggregate)
      flatStats = []

      if (aggregate)
         foldStats = {}
         [:grounding, :inference, :total].each{|key|
            foldStats[key] = Util.mean(stats[key])
         }

         flatStats += flattenRowStats(row, foldStats)
      else
         for i in 0...@numFolds
            foldRow = row + [i]

            foldStats = Hash.new{|hash, key| hash[key] = -1}

            [:grounding, :inference, :total].each{|key|
               if (stats[key].size() >= i)
                  foldStats[key] = stats[key][i]
               end
            }

            flatStats += flattenRowStats(foldRow, foldStats)
         end
      end

      return flatStats
   end

   def flattenRowStats(row, stats)
      return [row + [stats[:grounding], stats[:inference], stats[:total]]]
   end
end
