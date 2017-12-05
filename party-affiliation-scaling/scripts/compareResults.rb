# Read in two VOTES files and gets some stats on their differnce.

def readFile(path)
   # {[keys, ...] => value}
   atoms = {}

   File.open(path, 'r'){|file|
      file.each{|line|
         parts = line.strip().split("\t")

         # Technically not safe if we have "'" in key.
         atoms[parts[0...-1].map{|key| key.gsub("'", '')}] = parts[-1].to_f()
      }
   }

   return atoms
end

def main(path1, path2)
   atoms1 = readFile(path1)
   atoms2 = readFile(path2)

   if (atoms1.size() != atoms2.size())
      raise "Unequal number of atoms: #{atoms1.size()} vs #{atoms2.size()}."
   end

   absError = 0.0
   squaredError = 0.0

   atoms1.each{|atom, value1|
      if (!atoms2.include?(atom))
         raise "Atom2 missing: #{atom}"
      end

      diff = value1 - atoms2[atom]

      absError += diff.abs()
      squaredError += diff ** 2
   }

   mae = absError / atoms1.size()
   mse = squaredError / atoms2.size()

   puts "AE: #{absError}, SE: #{squaredError} MAE: #{mae}, MSE: #{mse}"
end

def loadArgs(args)
   if (args.size() != 2 || args.map{|arg| arg.gsub('-', '').downcase()}.include?('help'))
      puts "USAGE: ruby #{$0} <VOTES.txt 1> <VOTES.txt 2>"
      exit(1)
   end

   return args.shift(), args.shift()
end

if ($0 == __FILE__)
   main(*loadArgs(ARGV))
end
