# Copy over the targets as the query.

TARGET_FILENAME = 'trusts_target.txt'
PREDICATE_NAME = 'Trusts'

require 'fileutils'

def readTargets(path)
   # [[arg, arg, ...], ...]
   targets = []

   File.open(File.join(path, TARGET_FILENAME), 'r'){|file|
      file.each{|line|
         targets << line.strip().split("\t")
      }
   }

   return targets
end

def writeTargets(outPath, targets)
   File.open(outPath, 'w'){|file|
      file.puts(targets.map{|target| "#{PREDICATE_NAME}(#{target.join(', ')})"}.join("\n"))
   }
end

def main(dataDir, outPath)
   FileUtils.mkdir_p(File.dirname(outPath))

   targets = readTargets(dataDir)
   writeTargets(outPath, targets)
end

def loadArgs(args)
   if (args.size() != 2 || args.map{|arg| arg.gsub('-', '').downcase()}.include?('help'))
      puts "USAGE: ruby #{$0} <data dir> <out path>"
      puts "   As per MLN convention, all evidence will be put into a single file."
      exit(1)
   end

   dataDir = args.shift()
   outPath = args.shift()

   return dataDir, outPath
end

if ($0 == __FILE__)
   main(*loadArgs(ARGV))
end
