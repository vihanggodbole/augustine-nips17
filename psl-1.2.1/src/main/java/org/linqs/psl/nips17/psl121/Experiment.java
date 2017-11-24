package org.linqs.psl.nips17.psl121;

import edu.umd.cs.psl.application.inference.MPEInference;
import edu.umd.cs.psl.application.learning.weight.maxlikelihood.MaxLikelihoodMPE;
import edu.umd.cs.psl.application.learning.weight.maxlikelihood.VotedPerceptron;
import edu.umd.cs.psl.config.ConfigBundle;
import edu.umd.cs.psl.database.Database;
import edu.umd.cs.psl.database.DataStore;
import edu.umd.cs.psl.database.Partition;
import edu.umd.cs.psl.util.database.Queries;
import edu.umd.cs.psl.groovy.PSLModel;
import edu.umd.cs.psl.model.Model;
import edu.umd.cs.psl.model.atom.GroundAtom;
import edu.umd.cs.psl.model.predicate.StandardPredicate;
import edu.umd.cs.psl.model.argument.GroundTerm;
import edu.umd.cs.psl.evaluation.statistics.ContinuousPredictionComparator;
import edu.umd.cs.psl.evaluation.statistics.DiscretePredictionComparator;
import edu.umd.cs.psl.evaluation.statistics.DiscretePredictionStatistics;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

import java.io.File;
import java.io.FileWriter;
import java.io.IOException;
import java.util.Set;

/**
 * A base class for all of the experiments.
 * Experiments are responsible for keeping their own Model (PSLModel).
 */
public abstract class Experiment {
   private static final int PARTITION_OBSERVATIONS = 1;
   private static final int PARTITION_TARGETS = 2;
   private static final int PARTITION_TRUTH = 3;

   private static Logger log = LoggerFactory.getLogger(Experiment.class);

   protected Partition obsPartition;
   protected Partition targetsPartition;
   protected Partition truthPartition;

   protected ConfigBundle config;
   protected DataStore dataStore;
   protected PSLModel model;

   public Experiment(ConfigBundle config, DataStore dataStore) {
      // HACK(eriq): For stupid Groovy reasons, the model must be constructed in the base class.

      this.config = config;
      this.dataStore = dataStore;

      obsPartition = new Partition(PARTITION_OBSERVATIONS);
      targetsPartition = new Partition(PARTITION_TARGETS);
      truthPartition = new Partition(PARTITION_TRUTH);
   }

   public Model getModel() {
      return model;
   }

   public void runInference() {
      Set<StandardPredicate> closedPredicates = getClosedPredicates();
      Database database = dataStore.getDatabase(targetsPartition, closedPredicates, obsPartition);

      MPEInference mpe = null;
      try {
         mpe = new MPEInference(model, database, config);
      } catch (Exception ex) {
         throw new RuntimeException("Failed to construct MPEInference.", ex);
      }
      mpe.mpeInference();

      mpe.close();
      database.close();
   }

   public void writeOutput(String outputDir) {
      Set<StandardPredicate> closedPredicates = getClosedPredicates();
      Set<StandardPredicate> openPredicates = getOpenPredicates();

      Database database = dataStore.getDatabase(targetsPartition, closedPredicates, obsPartition);

		File outputDirectory = new File(outputDir);

		// mkdir -p
		outputDirectory.mkdirs();

		for (StandardPredicate openPredicate : openPredicates) {
			try {
				FileWriter predFileWriter = new FileWriter(new File(outputDirectory, openPredicate.getName() + ".txt"));

				for (GroundAtom atom : Queries.getAllAtoms(database, openPredicate)) {
					for (GroundTerm term : atom.getArguments()) {
						predFileWriter.write(term.toString() + "\t");
					}
					predFileWriter.write(Double.toString(atom.getValue()));
					predFileWriter.write("\n");
				}

				predFileWriter.close();
			} catch (IOException ex) {
				log.error("Exception writing predicate {}", openPredicate);
			}
		}

      database.close();
	}

   public void learn() {
		log.info("Starting weight learning");

      Set<StandardPredicate> closedPredicates = getClosedPredicates();

		Database randomVariableDatabase = dataStore.getDatabase(targetsPartition, closedPredicates, obsPartition);
		Database observedTruthDatabase = dataStore.getDatabase(truthPartition, dataStore.getRegisteredPredicates());

		VotedPerceptron vp = new MaxLikelihoodMPE(model, randomVariableDatabase, observedTruthDatabase, config);
      try {
		   vp.learn();
      } catch (Exception ex) {
         throw new RuntimeException("Failed to run weight learning.", ex);
      }

		randomVariableDatabase.close();
		observedTruthDatabase.close();

		log.info("Weight learning complete");
	}

	protected void continuousEval() {
		log.info("Starting continuous evaluation");

      Set<StandardPredicate> closedPredicates = getClosedPredicates();
      Set<StandardPredicate> openPredicates = getOpenPredicates();

		// Create database.
		Database predictionDatabase = dataStore.getDatabase(targetsPartition);
		Database truthDatabase = dataStore.getDatabase(truthPartition);

		ContinuousPredictionComparator comparator = new ContinuousPredictionComparator(predictionDatabase);
		comparator.setBaseline(truthDatabase);

		for (StandardPredicate targetPredicate : openPredicates) {
			comparator.setMetric(ContinuousPredictionComparator.Metric.MAE);
			double mae = comparator.compare(targetPredicate);

			comparator.setMetric(ContinuousPredictionComparator.Metric.MSE);
			double mse = comparator.compare(targetPredicate);

			log.info(String.format(
               "Continuous evaluation results for %s -- MAE: %f, MSE: %f",
               targetPredicate.getName(), mae, mse));
		}

		predictionDatabase.close();
		truthDatabase.close();

		log.info("Continuous evaluation complete");
	}

	protected void discreteEval(double threshold) {
		log.info("Starting discrete evaluation");

      Set<StandardPredicate> closedPredicates = getClosedPredicates();
      Set<StandardPredicate> openPredicates = getOpenPredicates();

		// Create database.
		Database predictionDatabase = dataStore.getDatabase(targetsPartition, openPredicates);
		Database truthDatabase = dataStore.getDatabase(truthPartition, openPredicates);

		DiscretePredictionComparator comparator = new DiscretePredictionComparator(predictionDatabase);
		comparator.setThreshold(threshold);
		comparator.setBaseline(truthDatabase);

		for (StandardPredicate targetPredicate : openPredicates) {
			DiscretePredictionStatistics stats = comparator.compare(targetPredicate);

			double accuracy = stats.getAccuracy();
			double error = stats.getError();
			double positivePrecision = stats.getPrecision(DiscretePredictionStatistics.BinaryClass.POSITIVE);
			double positiveRecall = stats.getRecall(DiscretePredictionStatistics.BinaryClass.POSITIVE);
			double negativePrecision = stats.getPrecision(DiscretePredictionStatistics.BinaryClass.NEGATIVE);
			double negativeRecall = stats.getRecall(DiscretePredictionStatistics.BinaryClass.NEGATIVE);

			log.info(String.format(
               "Discrete evaluation results for %s --" +
					" Accuracy: %f, Error: %f," +
					" Positive Class Precision: %f, Positive Class Recall: %f," +
					" Negative Class Precision: %f, Negative Class Recall: %f,",
					targetPredicate.getName(),
					accuracy, error, positivePrecision, positiveRecall,
               negativePrecision, negativeRecall));
		}

		predictionDatabase.close();
		truthDatabase.close();

		log.info("Discrete evaluation complete");
	}

   public void close() {
      dataStore.close();
   }

   public abstract void definePredicates();

   /**
    * All rules will get an initial weight.
    * If the launcher finds a weight file (indicating that a run of weight learning
    * happened earlier), then those weights will be passed in instead of these.
    */
   public abstract double[] getDefaultWeights();

   public abstract void defineRules(double[] weights);
   public abstract void loadData(String dataPath);
   public abstract void eval();

   protected abstract Set<StandardPredicate> getClosedPredicates();
   protected abstract Set<StandardPredicate> getOpenPredicates();
}
