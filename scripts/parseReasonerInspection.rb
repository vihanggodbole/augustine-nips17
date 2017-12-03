# Parse all supplied evaluation output files and parse out the reasoner inspection.
# This assumes that all supplied files are output from reasoners inspected by the same inspector
# (ie they all have the same stats).

MAX_ITERATIONS = 5000
NUM_COLUMNS = 4
TARGET_PREDICATE = 'HASCAT'

def parseFile(path)
   headers = []
   data = []

   File.open(path, 'r'){|file|
      row = []

      file.each{|line|
         if (match = line.match(/ - (?:Reasoner inspection update|#{TARGET_PREDICATE}) -- (.+)$/))
            stats = match[1].strip().split(', ').map{|stat| stat.split(': ')}

            if (stats[0][0] == 'Iteration')
               # Skip iteration in favor of order in file.
               stats = stats[1..-1]
            end

            stats.each{|stat|
               header = stat[0]
               value = stat[1]

               if (headers.size() < NUM_COLUMNS)
                  headers << header
               elsif (headers[row.size()] != header)
                  raise "Inconsistent header found on line #{file.lineno} (#{row.size()}). Expected: '#{headers[row.size()]}', Found: '#{header}'"
               end

               row << value
            }

            if (row.size() == NUM_COLUMNS)
               data << row
               row = []
            end

            if (data.size() == MAX_ITERATIONS)
               break
            end
         end
      }
   }

   return headers, data
end

# Size of common prefix for multiple arrays.
def commonPrefixLength(lists)
   minLength = lists.map{|list| list.size()}.min()
   prefixLen = 0

   for i in 0...minLength
      part = nil
      same = true

      lists.each{|list|
         if (part == nil)
            part = list[i]
         elsif (part != list[i])
            same = false
            break
         end
      }

      if (same)
         prefixLen += 1
      else
         break
      end
   end

   return prefixLen
end

# Remove the common prefix and suffix from all the paths and use the remaining as an id.
def computeFileIds(inputFiles)
   if (inputFiles.size() == 0)
      return inputFiles
   end

   cleanParts = inputFiles.map{|path| File.absolute_path(path).split(File::SEPARATOR)}

   # Prefix
   trimSize = commonPrefixLength(cleanParts)
   cleanParts.map!{|parts| parts[trimSize..-1]}

   # Suffix
   cleanParts.map!{|parts| parts.reverse()}
   trimSize = commonPrefixLength(cleanParts)
   cleanParts.map!{|parts| parts[trimSize..-1]}
   cleanParts.map!{|parts| parts.reverse()}

   return cleanParts.map{|parts| parts.join(File::SEPARATOR)}
end

def main(inputFiles)
   fileIds = computeFileIds(inputFiles)

   headers = ['iteration']
   rows = []

   totalColumns = nil

   inputFiles.each_with_index{|inputFile, fileIndex|
      fileId = fileIds[fileIndex]
      columns, data = parseFile(inputFile)

      # Once we get the first set of columns, we can calculate the width.
      # Don't include the iteration.
      if (totalColumns == nil)
         totalColumns = columns.size() * inputFiles.size()
      end

      headers += columns.map{|column| "#{fileId} -- #{column}"}

      # Lengthen the table if necessary.
      if (rows.size() < data.size())
         rows += Array.new(data.size() - rows.size()){ [[nil] * totalColumns] }
      end

      # The offset into the row that this file's data starts.
      rowOffset = fileIndex * columns.size()

      data.each_with_index{|row, iteration|
         row.each_with_index{|value, index|
            rows[iteration][rowOffset + index] = value
         }
      }
   }

   puts headers.join("\t")
   rows.each_with_index{|row, iteration|
      puts ([iteration + 1] + row).join("\t")
   }
end

def loadArgs(args)
   if (args.size() == 0 || args.map{|arg| arg.gsub('-', '').downcase()}.include?('help'))
      puts "USAGE: ruby #{$0} <evalaution output file> ..."
      puts "   Parse all supplied evaluation output files and parse out the reasoner inspection."
      puts "   This assumes that all supplied files are output from reasoners inspected by the same inspector"
      puts "   (ie they all have the same stats)."
      exit(1)
   end

   return args
end

if ($0 == __FILE__)
   main(loadArgs(ARGV))
end
