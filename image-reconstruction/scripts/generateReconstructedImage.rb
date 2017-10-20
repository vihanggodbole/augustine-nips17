# Take in the raw image files and generate the images that they represent.

require 'fileutils'

DEFAULT_OUT_DIR = 'out'
DEFAULT_WIDTH = 64
# Just use the simple format for ease.
PGM_MAGIC_NUMBER = 'P2'
MAX_GREY_VALUE = 255

SIDE_BY_SIDE_BARRIER_WIDTH = 10

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
               pixelIndex = col * width + row
            else
               pixelIndex = row * width + col
            end

            file.print("#{(pixels[pixelIndex] * MAX_GREY_VALUE).to_i()} ")
         end

         file.puts()
      end
   }
end

# Return: {imageIndex => {pixelIndex => brightness (float), ...}, ...}
def parsePredicateData(path)
   data = Hash.new{|hash, key| hash[key] = {}}

   File.open(path, 'r'){|file|
      file.each{|line|
         parts = line.strip().split("\t")

         data[parts[1].gsub("'", '').to_i()][parts[0].gsub("'", '').to_i()] = parts[2].to_f()
      }
   }

   return data
end

def main(predicatePath, rawDataPath, outDir, width, sideBySide, rotate90 = true)
   FileUtils.mkdir_p(outDir)

   data = parsePredicateData(predicatePath)
   rawData = []

   File.open(rawDataPath, 'r'){|inFile|
      inFile.each{|line|
         line = line.strip()
         if (line == '')
            next
         end

         rawData << line.split("\t").map{|pixel| pixel.to_f()}
      }
   }

   # Throw out images that we didn't reconstruct.
   rawData = rawData[(rawData.size() - data.size())...rawData.size()]

   rawData.each_index{|imageIndex|
      pixels = rawData[imageIndex]

      if (sideBySide)
         # First make a copy of the pixels and overlay the reconstruction values.
         newPixels = pixels.dup()
         data[imageIndex].each{|pixelIndex, newValue|
            newPixels[pixelIndex] = newValue
         }

         # Now make a new image that has both pixels with a white barrier between them.
         height = pixels.size() / width
         sideBySidePixels = Array.new(height * (width * 2 + SIDE_BY_SIDE_BARRIER_WIDTH), 0.0)

         sideBySideIndex = 0
         for row in 0...height
            # Original
            for col in 0...width
               if (rotate90)
                  pixelIndex = col * width + row
               else
                  pixelIndex = row * width + col
               end

               sideBySidePixels[sideBySideIndex] = pixels[pixelIndex]
               sideBySideIndex += 1
            end

            # Whitespace
            for i in 0...SIDE_BY_SIDE_BARRIER_WIDTH
               sideBySidePixels[sideBySideIndex] = 1.0
               sideBySideIndex += 1
            end

            # Reconstructed
            for col in 0...width
               if (rotate90)
                  pixelIndex = col * width + row
               else
                  pixelIndex = row * width + col
               end

               sideBySidePixels[sideBySideIndex] = newPixels[pixelIndex]
               sideBySideIndex += 1
            end
         end

         # Note that we already rotated.
         writeImage(sideBySidePixels, width * 2 + SIDE_BY_SIDE_BARRIER_WIDTH, File.join(outDir, "#{'%04d' % imageIndex}.pgm"), false)
      else
         # Override the values with the reconstruction values.
         data[imageIndex].each{|pixelIndex, newValue|
            pixels[pixelIndex] = newValue
         }

         writeImage(pixels, width, File.join(outDir, "#{'%04d' % imageIndex}.pgm"), rotate90)
      end
   }
end

def loadArgs(args)
   if (![2, 3, 4, 5].include?(args.size()) || args.map{|arg| arg.gsub('-', '').downcase()}.include?('help'))
      puts "USAGE: ruby #{$0} <psl predicate dump> <raw data file> [out dir] [--side] [width]"
      puts "   The psl predicate dump file should be the one created by the cli when outputting the results."
      puts "      It will typically be named PIXELBRIGHTNESS.txt."
      puts "   The raw data file is the same one that is provided to scripts/generateRawImages.rb."
      puts "   The output directory defaults to '#{DEFAULT_OUT_DIR}'."
      puts "   If '--side' is supplied, then the resulting image will be a side-by-side image with the original image."
      puts "   The default witdth is #{DEFAULT_WIDTH}."
      puts "   It is assumed that all the reconstructed images appear last in the raw file."
      exit(1)
   end

   predicatePath = args.shift()
   rawDataPath = args.shift()
   outDir = DEFAULT_OUT_DIR
   sideBySide = false
   width = DEFAULT_WIDTH

   if (args.size() > 0)
      outDir = args.shift()
   end

   if (args.size() > 0)
      arg = args.shift()

      if (arg != '--side')
         puts "Unknown arg: '#{arg}'. Expecting '--side'."
         exit(2)
      end

      sideBySide = true
   end

   if (args.size() > 0)
      width = args.shift().to_i()
   end

   return predicatePath, rawDataPath, outDir, width, sideBySide
end

if ($0 == __FILE__)
   main(*loadArgs(ARGV))
end
