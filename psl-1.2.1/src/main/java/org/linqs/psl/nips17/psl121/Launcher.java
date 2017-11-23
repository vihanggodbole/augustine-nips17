package org.linqs.psl.nips17.psl121;

import org.linqs.psl.config.ConfigBundle;
import org.linqs.psl.config.ConfigManager;
import org.linqs.psl.database.DataStore;
import org.linqs.psl.database.rdbms.driver.H2DatabaseDriver;
import org.linqs.psl.database.rdbms.driver.H2DatabaseDriver.Type;
import org.linqs.psl.database.rdbms.RDBMSDataStore;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

import java.net.InetAddress;
import java.net.UnknownHostException;
import java.nio.file.Paths;
import java.util.ArrayList;
import java.util.Arrays;
import java.util.List;
import java.util.Stack;

public class Launcher {
   private static final String DEFAULT_HOSTNAME = "unknown";

   private static Logger log = LoggerFactory.getLogger(Launcher.class);

   private ConfigBundle config;
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

      // TODO(eriq)
      if (modelName.equals("friendship")) {
         experiment = new Friendship(config, dataStore);
      } else {
         throw new IllegalArgumentException("Unknown model: " + modelName);
      }
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

      modelName = args.remove(0);

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
            dataPath = parseValueArg(args, i, toRemove);
            i++;
         } else if (args.get(i).equals("-model")) {
            modelPath = parseValueArg(args, i, toRemove);
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

      if (dataPath == null) {
         log.error("'-data' required");
         printUsage();
         System.exit(1);
      }

      if (outputDir == null) {
         log.error("'-output' required");
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
      experiment.definePredicates();
      experiment.defineRules();
      experiment.loadData(dataPath);

      if (learn) {
         experiment.learn();
      }
      
      experiment.runInference();
      experiment.writeOutput(outputDir);
      experiment.eval();

      experiment.close();
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
      System.out.println("USAGE: java " + Launcher.class.getName() + " modelName [OPTIONS]");
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
