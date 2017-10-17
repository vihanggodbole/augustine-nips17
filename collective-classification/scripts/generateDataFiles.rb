DATASET_SEARCH_PATTERN = '__dataset__'
FOLD_SEARCH_PATTERN = '__fold__'
METHOD_SEARCH_PATTERN = '__type__'

DATASETS = ['citeseer', 'cora']
FOLDS =  (0...20).to_a()
METHODS = ['learn', 'eval']

def main(templatePath, dataset, fold, method, outPath)
   File.open(templatePath, 'r'){|inFile|
      File.open(outPath, 'w'){|outFile|
         inFile.each{|line|
            outFile.puts(
                  line.gsub(DATASET_SEARCH_PATTERN, dataset)
                  .gsub(FOLD_SEARCH_PATTERN, "#{fold}")
                  .gsub(METHOD_SEARCH_PATTERN, method)
            )
         }
      }
   }
end

def loadArgs(args)
   if (args.size() != 5 || args.map{|arg| arg.gsub('-', '').downcase()}.include?('help'))
      puts "USAGE: ruby #{$0} <model template> <out path> <dataset> <fold> <method>"
      puts "   model template - the path to the template data file to use."
      puts "   out path - the path to place the replaced template at."
      puts "   dataset - the core dataset to use. Possible values: #{DATASETS}."
      puts "   fold - the fold configuration to use. Possible values: #{FOLDS}."
      puts "   method - the psl method to use. Possible values: #{METHODS}."
      exit(1)
   end

   templatePath = args.shift()
   outPath = args.shift()
   dataset = args.shift()
   fold = args.shift()
   method = args.shift()

   if (!DATASETS.include?(dataset))
      puts "Unknown dataset: '#{dataset}'."
      exit(2)
   end

   if (!fold.match(/\d+/))
      puts "Bad format for fold (#{fold}), expecting integer."
      exit(3)
   end

   fold = fold.to_i()
   if (!FOLDS.include?(fold))
      puts "Unknown fold: '#{fold}'."
      exit(4)
   end

   if (!METHODS.include?(method))
      puts "Unknown method: '#{method}'."
      exit(5)
   end

   return templatePath, dataset, fold, method, outPath
end

if ($0 == __FILE__)
   main(*loadArgs(ARGV))
end
