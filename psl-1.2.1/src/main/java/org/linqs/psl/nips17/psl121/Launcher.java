package org.linqs.psl.nips17.psl121;

import edu.umd.cs.psl.config.ConfigBundle;
import edu.umd.cs.psl.config.ConfigManager;
import edu.umd.cs.psl.database.DataStore;
import edu.umd.cs.psl.database.rdbms.driver.H2DatabaseDriver;
import edu.umd.cs.psl.database.rdbms.driver.H2DatabaseDriver.Type;
import edu.umd.cs.psl.database.rdbms.RDBMSDataStore;
import edu.umd.cs.psl.model.Model;
import edu.umd.cs.psl.model.kernel.Kernel;
import edu.umd.cs.psl.model.kernel.rule.CompatibilityRuleKernel;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

import java.io.BufferedWriter;
import java.io.FileWriter;
import java.io.File;
import java.io.IOException;
import java.net.InetAddress;
import java.net.UnknownHostException;
import java.nio.file.Paths;
import java.util.ArrayList;
import java.util.Arrays;
import java.util.List;
import java.util.Scanner;
import java.util.Stack;

/**
 * Act as a thin surrogate for the proper PSL cli.
 */
public class Launcher {
   private static final String DEFAULT_HOSTNAME = "unknown";
   private static final String WEIGHTS_FILE = "learned-weights.txt";

   private static Logger log = LoggerFactory.getLogger(Launcher.class);

   private ConfigBundle config;
   private String dataFilePath;
   private String dataPath;
   private DataStore dataStore;
   private boolean learn;
   private String modelName;
   private String modelPath;
   private String outputDir;

   private boolean evalContinuous;
   private boolean evalDiscrete;
   private double discreteThreshold;

   private Experiment experiment;

   public Launcher(List<String> args) {
      // Ensure out list is mutable (supports remove()).
      args = new ArrayList<String>(args);

      try {
      config = ConfigManager.getManager().getBundle(modelName);
      } catch (Exception ex) {
         throw new RuntimeException("Failed to get configuration", ex);
      }

      evalContinuous = false;
      evalDiscrete = false;

      parseArgs(args);
      initDB();
      dataPath = discoverDataPath(dataFilePath);

      // TODO(eriq)
      if (modelName.equals("friendship")) {
         experiment = new Friendship(config, dataStore);
      } else if (modelName.equals("collective-classification")) {
         experiment = new CollectiveClassification(config, dataStore);
      } else if (modelName.equals("epinions")) {
         experiment = new Epinions(config, dataStore);
      } else {
         throw new IllegalArgumentException("Unknown model: " + modelName);
      }
   }

   /**
    * Read enough of a PSL data file to figure out the directory that
    * the data is held in.
    */
   private String discoverDataPath(String dataFilePath) {
      Scanner scanner = null;
      try {
         scanner = new Scanner(new File(dataFilePath));
      } catch (Exception ex) {
         throw new RuntimeException("Failed to create scanner.", ex);
      }

      while (scanner.hasNextLine()) {
         String line = scanner.nextLine().trim();

         if (line.matches("^\\w+:\\s+[^:]+\\.txt$")) {
            return Paths.get(line.split(":")[1].trim()).getParent().toString();
         }
      }

      throw new RuntimeException("Unable to discover data path.");
   }

   private void initDB() {
      String suffix = System.getProperty("user.name") + "@" + getHostname();
      String baseDBPath = config.getString("dbpath", System.getProperty("java.io.tmpdir"));
      String dbPath = Paths.get(baseDBPath, modelName + "_" + suffix).toString();

      dataStore = new RDBMSDataStore(new H2DatabaseDriver(Type.Disk, dbPath, true), config);
   }

   /**
    * Parse any launcher arguments off the command-line args.
    * All launcher argumnet will be removed from the list,
    * while any non-launcher arguments will be left in.
    * This is far from robust or complete.
    * It is just meant to loosly work with the formal PSL CLI interface.
    */
   private void parseArgs(List<String> args) {
      if (args.size() < 4) {
         log.error("Launcher needs at least 4 arguments.");
         printUsage();
         System.exit(1);
      }

      // Make sure we have seen -learn/-infer
      boolean gotMethod = false;

      Stack<Integer> toRemove = new Stack<Integer>();
      for (int i = 0; i < args.size(); i++) {
         if (args.get(i).equals("-help") || args.get(i).equals("--help") || args.get(i).equals("-h")) {
            printUsage();
            System.exit(0);
         } else if (args.get(i).equals("-learn")) {
            toRemove.push(i);
            learn = true;
            gotMethod = true;
         } else if (args.get(i).equals("-infer")) {
            toRemove.push(i);
            learn = false;
            gotMethod = true;
         } else if (args.get(i).equals("-ec")) {
            toRemove.push(i);
            evalContinuous = true;
         } else if (args.get(i).equals("-ed")) {
            evalDiscrete = true;
            discreteThreshold = Double.valueOf(parseValueArg(args, i, toRemove));
            i++;
         } else if (args.get(i).equals("-data")) {
            dataFilePath = parseValueArg(args, i, toRemove);
            i++;
         } else if (args.get(i).equals("-model")) {
            modelPath = parseValueArg(args, i, toRemove);
            modelName = Paths.get(modelPath).getFileName().toString().replaceFirst("(-learned)?\\.psl$", "");
            i++;
         } else if (args.get(i).equals("-output")) {
            outputDir = parseValueArg(args, i, toRemove);
            i++;
         } else if (args.get(i).equals("-D")) {
            String[] parts = parseValueArg(args, i, toRemove).split("=");
            i++;

            if (parts.length != 2) {
               log.error("Bad configuration argument: " + args.get(i));
               printUsage();
               System.exit(1);
            }

            config.setProperty(parts[0], parts[1]);
         }
      }

      for (Integer removeIndex : toRemove) {
         args.remove(removeIndex);
      }

      if (!gotMethod) {
         log.error("Either '-learn' or '-infer' required");
         printUsage();
         System.exit(1);
      }

      if (modelName == null) {
         log.error("Unable to figure out model name");
         printUsage();
         System.exit(1);
      }

      if (dataFilePath == null) {
         log.error("'-data' required");
         printUsage();
         System.exit(1);
      }

      if (outputDir == null && !learn) {
         log.error("'-output' required with '-infer'");
         printUsage();
         System.exit(1);
      }
   }

   private String parseValueArg(List<String> args, int index, Stack<Integer> toRemove) {
      toRemove.push(index);
      index++;
      toRemove.push(index);

      if (index == args.size()) {
         log.error("Missing argument value for: '" + args.get(index - 1) + "'");
         printUsage();
         System.exit(1);
      }

      return args.get(index);
   }

   private void run() {
      double[] weights = fetchWeights();

      experiment.definePredicates();
      experiment.defineRules(weights);

      log.info("Starting data loading.");
      experiment.loadData(dataPath);
      log.info("Finished data loading.");

      if (learn) {
         experiment.learn();
         writeLearnedModel();
         writeWeights();
      } else {
         log.info("Starting inference.");
         experiment.runInference();
         log.info("Finished inference.");

         experiment.writeOutput(outputDir);
         experiment.eval();
      }

      experiment.close();
   }

   private double[] fetchWeights() {
      String weightsPath = Paths.get(outputDir, WEIGHTS_FILE).toString();
      File weightsFile = new File(weightsPath);

      if (!weightsFile.isFile()) {
         return experiment.getDefaultWeights();
      }

      Scanner scanner = null;
      try {
         scanner = new Scanner(weightsFile);
      } catch (Exception ex) {
         throw new RuntimeException("Failed to create scanner.", ex);
      }

      List<Double> rawWeights = new ArrayList<Double>();
      while (scanner.hasNextLine()) {
         rawWeights.add(Double.valueOf(scanner.nextLine().trim()));
      }

      double[] weights = new double[rawWeights.size()];
      for (int i = 0; i < rawWeights.size(); i++) {
         weights[i] = rawWeights.get(i).doubleValue();
      }

      return weights;
   }

   /**
    * Write out the full learned model for reference.
    */
   private void writeLearnedModel() {
      String modelDir = Paths.get(modelPath).getParent().toString();
      String learnedModelPath = Paths.get(modelDir, modelName + "-learned.psl").toString();

      try {
         BufferedWriter writer = new BufferedWriter(new FileWriter(learnedModelPath));
         writer.write(experiment.getModel().toString() + "\n");
         writer.close();
      } catch (IOException ex) {
         throw new RuntimeException("Failed to open weight writer.", ex);
      }
   }

   private void writeWeights() {
      String weightsPath = Paths.get(outputDir, WEIGHTS_FILE).toString();

      try {
         BufferedWriter writer = new BufferedWriter(new FileWriter(weightsPath));

         for (Kernel rule : experiment.getModel().getKernels()) {
            if (!(rule instanceof CompatibilityRuleKernel)) {
               continue;
            }

            writer.write("" + ((CompatibilityRuleKernel)rule).getWeight().getWeight() + "\n");
         }

         writer.close();
      } catch (IOException ex) {
         throw new RuntimeException("Failed to open weight writer.", ex);
      }
   }

   private static String getHostname() {
      String hostname = DEFAULT_HOSTNAME;

      try {
         hostname = InetAddress.getLocalHost().getHostName();
      } catch (UnknownHostException ex) {
         log.warn("Hostname can not be resolved, using '" + hostname + "'.");
      }

      return hostname;
   }

   private static void printUsage() {
      System.out.println("USAGE: java " + Launcher.class.getName() + " [OPTIONS]");
      System.out.println("Options:");
      System.out.println("   -help          -- print this message and exit");
      System.out.println("   -learn         -- run weight learning");
      System.out.println("   -infer         -- run MAP inference");
      System.out.println("   -data <path>   -- path to the directory containing the data");
      System.out.println("   -output <path> -- path for writing results to filesystem");
   }

   public static void main(String[] args) {
      Launcher launcher = new Launcher(Arrays.asList(args));
      launcher.run();
   }
}
