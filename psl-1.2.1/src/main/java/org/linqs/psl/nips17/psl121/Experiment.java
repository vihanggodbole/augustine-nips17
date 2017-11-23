package org.linqs.psl.nips17.psl121;

import org.linqs.psl.application.inference.MPEInference;
import org.linqs.psl.application.learning.weight.maxlikelihood.MaxLikelihoodMPE;
import org.linqs.psl.application.learning.weight.maxlikelihood.VotedPerceptron;
import org.linqs.psl.config.ConfigBundle;
import org.linqs.psl.database.Database;
import org.linqs.psl.database.DataStore;
import org.linqs.psl.database.Partition;
import org.linqs.psl.database.Queries;
import org.linqs.psl.groovy.PSLModel;
import org.linqs.psl.model.atom.GroundAtom;
import org.linqs.psl.model.predicate.StandardPredicate;
import org.linqs.psl.model.term.Constant;
import org.linqs.psl.utils.evaluation.statistics.ContinuousPredictionComparator;
import org.linqs.psl.utils.evaluation.statistics.DiscretePredictionComparator;
import org.linqs.psl.utils.evaluation.statistics.DiscretePredictionStatistics;

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
   private static final String PARTITION_OBSERVATIONS = "observations";
   private static final String PARTITION_TARGETS = "targets";
   private static final String PARTITION_TRUTH = "truth";

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

      obsPartition = dataStore.getPartition(PARTITION_OBSERVATIONS);
      targetsPartition = dataStore.getPartition(PARTITION_TARGETS);
      truthPartition = dataStore.getPartition(PARTITION_TRUTH);
   }

   public void runInference() {
      Set<StandardPredicate> closedPredicates = getClosedPredicates();
      Database database = dataStore.getDatabase(targetsPartition, closedPredicates, obsPartition);

      MPEInference mpe = new MPEInference(model, database, config);
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
					for (Constant term : atom.getArguments()) {
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
		vp.learn();

		randomVariableDatabase.close();
		observedTruthDatabase.close();

		log.info("Weight learning complete");

      // Write out the learned model.
      System.out.println(model.asString().replaceAll("\\( | \\)", ""));
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
			// Before we run evaluation, ensure that the truth database actaully has instances of the target predicate.
			if (Queries.countAllGroundAtoms(truthDatabase, targetPredicate) == 0) {
				log.info("Skipping continuous evaluation for {} since there are no ground truth atoms", targetPredicate);
				continue;
			}

			comparator.setMetric(ContinuousPredictionComparator.Metric.MAE);
			double mae = comparator.compare(targetPredicate);

			comparator.setMetric(ContinuousPredictionComparator.Metric.MSE);
			double mse = comparator.compare(targetPredicate);

			log.info("Continuous evaluation results for {} -- MAE: {}, MSE: {}", targetPredicate.getName(), mae, mse);
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
			// Before we run evaluation, ensure that the truth database actaully has instances of the target predicate.
			if (Queries.countAllGroundAtoms(truthDatabase, targetPredicate) == 0) {
				log.info("Skipping discrete evaluation for {} since there are no ground truth atoms", targetPredicate);
				continue;
			}

			DiscretePredictionStatistics stats = comparator.compare(targetPredicate);

			double accuracy = stats.getAccuracy();
			double error = stats.getError();
			double positivePrecision = stats.getPrecision(DiscretePredictionStatistics.BinaryClass.POSITIVE);
			double positiveRecall = stats.getRecall(DiscretePredictionStatistics.BinaryClass.POSITIVE);
			double negativePrecision = stats.getPrecision(DiscretePredictionStatistics.BinaryClass.NEGATIVE);
			double negativeRecall = stats.getRecall(DiscretePredictionStatistics.BinaryClass.NEGATIVE);

			log.info("Discrete evaluation results for {} --" +
					" Accuracy: {}, Error: {}," +
					" Positive Class Precision: {}, Positive Class Recall: {}," +
					" Negative Class Precision: {}, Negative Class Recall: {},",
					targetPredicate.getName(),
					accuracy, error, positivePrecision, positiveRecall, negativePrecision, negativeRecall);
		}

		predictionDatabase.close();
		truthDatabase.close();

		log.info("Discrete evaluation complete");
	}

   public void close() {
      dataStore.close();
   }

   public abstract void definePredicates();
   public abstract void defineRules();
   public abstract void loadData(String dataPath);
   public abstract void eval();

   protected abstract Set<StandardPredicate> getClosedPredicates();
   protected abstract Set<StandardPredicate> getOpenPredicates();
}
