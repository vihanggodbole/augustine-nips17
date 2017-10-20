DATASET_SEARCH_PATTERN = '__dataset__'
METHOD_SEARCH_PATTERN = '__type__'

DATASETS = ['caltech', 'olivetti']
METHODS = ['learn', 'eval']

def main(templatePath, dataset, method, outPath)
   File.open(templatePath, 'r'){|inFile|
      File.open(outPath, 'w'){|outFile|
         inFile.each{|line|
            outFile.puts(
                  line.gsub(DATASET_SEARCH_PATTERN, dataset)
                  .gsub(METHOD_SEARCH_PATTERN, method)
            )
         }
      }
   }
end

def loadArgs(args)
   if (args.size() != 4 || args.map{|arg| arg.gsub('-', '').downcase()}.include?('help'))
      puts "USAGE: ruby #{$0} <model template> <out path> <dataset> <method>"
      puts "   model template - the path to the template data file to use."
      puts "   out path - the path to place the replaced template at."
      puts "   dataset - the core dataset to use. Possible values: #{DATASETS}."
      puts "   method - the psl method to use. Possible values: #{METHODS}."
      exit(1)
   end

   templatePath = args.shift()
   outPath = args.shift()
   dataset = args.shift()
   method = args.shift()

   if (!DATASETS.include?(dataset))
      puts "Unknown dataset: '#{dataset}'."
      exit(2)
   end

   if (!METHODS.include?(method))
      puts "Unknown method: '#{method}'."
      exit(3)
   end

   return templatePath, dataset, method, outPath
end

if ($0 == __FILE__)
   main(*loadArgs(ARGV))
end
