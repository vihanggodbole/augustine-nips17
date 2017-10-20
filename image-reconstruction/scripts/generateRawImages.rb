# Take in the raw image files and generate the images that they represent.

require 'fileutils'

DEFAULT_OUT_DIR = 'out'
DEFAULT_WIDTH = 64
# Just use the simple format for ease.
PGM_MAGIC_NUMBER = 'P2'
MAX_GREY_VALUE = 255

# The pixels are greyscale bightness percent.
# pgm files will be written out.
# For some reason, the data comes in rotated -90 degrees, so by default we will rotate that back.
def writeImage(pixels, width, path, rotate90 = true)
   height = pixels.size() / width

   if (width <= 0 || height <= 0)
      raise("Bad image dimensions (#{width}, #{height}) for [#{path}].")
   end

   File.open(path, 'w'){|file|
      # Magic number
      file.puts(PGM_MAGIC_NUMBER)

      # Dimentsion (width, height)
      file.puts("#{width} #{height}")

      # Maxval
      file.puts("#{MAX_GREY_VALUE}")

      for row in 0...height
         for col in 0...width
            if (rotate90)
               index = col * width + row
            else
               index = row * width + col
            end

            file.print("#{(pixels[index] * MAX_GREY_VALUE).to_i()} ")
         end

         file.puts()
      end
   }
end

def main(inPath, outDir, width)
   FileUtils.mkdir_p(outDir)

   File.open(inPath, 'r'){|inFile|
      index = 0
      inFile.each{|line|
         line = line.strip()
         if (line == '')
            next
         end

         pixels = line.split("\t").map{|pixel| pixel.to_f()}
         writeImage(pixels, width, File.join(outDir, "#{'%04d' % index}.pgm"))

         index += 1
      }
   }
end

def loadArgs(args)
   if (![1, 2, 3].include?(args.size()) || args.map{|arg| arg.gsub('-', '').downcase()}.include?('help'))
      puts "USAGE: ruby #{$0} <raw data file> [out dir] [width]"
      puts "   Pull out all the images represetend by the data file and put them into a directory named by their index in the file."
      puts "   The output directory defaults to '#{DEFAULT_OUT_DIR}'."
      puts "   The default witdth is #{DEFAULT_WIDTH}."
      exit(1)
   end

   inPath = args.shift()
   outDir = DEFAULT_OUT_DIR
   width = DEFAULT_WIDTH

   if (args.size() > 0)
      outDir = args.shift()
   end

   if (args.size() > 0)
      width = args.shift().to_i()
   end

   return inPath, outDir, width
end

if ($0 == __FILE__)
   main(*loadArgs(ARGV))
end
