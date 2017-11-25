package org.linqs.psl.nips17.psl121;

import edu.umd.cs.psl.config.ConfigBundle;
import edu.umd.cs.psl.database.DataStore;
import edu.umd.cs.psl.database.loading.Inserter;
import edu.umd.cs.psl.groovy.PSLModel;
import edu.umd.cs.psl.groovy.PredicateConstraint;
import edu.umd.cs.psl.model.predicate.StandardPredicate;
import edu.umd.cs.psl.model.argument.ArgumentType;
import edu.umd.cs.psl.ui.loading.InserterUtils;

import java.nio.file.Paths;
import java.util.HashSet;
import java.util.Set;

public class Jester extends Experiment {
   public Jester(ConfigBundle config, DataStore dataStore) {
      super(config, dataStore);
      // HACK(eriq): For stupid Groovy reasons, we have to construct the model here.
      model = new PSLModel(this, dataStore);
   }

   @Override
   public void definePredicates() {
      model.add(
         predicate: "AvgJokeRatingObs",
         types: [ArgumentType.UniqueID]
      );

      model.add(
         predicate: "AvgUserRatingObs",
         types: [ArgumentType.UniqueID]
      );

      model.add(
         predicate: "Joke",
         types: [ArgumentType.UniqueID]
      );

      model.add(
         predicate: "RatingPrior",
         types: [ArgumentType.UniqueID]
      );

      model.add(
         predicate: "SimObsRating",
         types: [ArgumentType.UniqueID, ArgumentType.UniqueID]
      );

      model.add(
         predicate: "User",
         types: [ArgumentType.UniqueID]
      );

      model.add(
         predicate: "Rating",
         types: [ArgumentType.UniqueID, ArgumentType.UniqueID]
      );

   }

   @Override
   public double[] getDefaultWeights() {
      double[] weights = new double[6];
      for (int i = 0; i < weights.length; i++) {
         weights[i] = 1.0;
      }

      return weights;
   }

   @Override
   public void defineRules(double[] weights) {
      model.add(
         rule: ( SimObsRating(J1,J2) & Rating(U,J1) ) >> Rating(U,J2),
         squared: true,
         weight: weights[0]
      );

      model.add(
         rule: ( User(U) & Joke(J) & AvgUserRatingObs(U) ) >> Rating(U,J),
         squared: true,
         weight: weights[1]
      );
      model.add(
         rule: ( User(U) & Joke(J) & AvgJokeRatingObs(J) ) >> Rating(U,J),
         squared: true,
         weight: weights[2]
      );
      model.add(
         rule: ( User(U) & Joke(J) & Rating(U,J) ) >> AvgUserRatingObs(U),
         squared: true,
         weight: weights[3]
      );
      model.add(
         rule: ( User(U) & Joke(J) & Rating(U,J) ) >> AvgJokeRatingObs(J),
         squared: true,
         weight: weights[4]
      );

      model.add(
         rule: ( User(U) & Joke(J) & RatingPrior(C) ) >> Rating(U,J),
         squared: true,
         weight: weights[5]
      );
   }

   @Override
   public void loadData(String dataPath) {
      Inserter inserter = null;

      inserter = dataStore.getInserter(AvgJokeRatingObs, obsPartition);
      InserterUtils.loadDelimitedDataTruth(inserter, Paths.get(dataPath, "avgJokeRatingObs_obs.txt").toString());

      inserter = dataStore.getInserter(AvgUserRatingObs, obsPartition);
      InserterUtils.loadDelimitedDataTruth(inserter, Paths.get(dataPath, "avgUserRatingObs_obs.txt").toString());

      inserter = dataStore.getInserter(Joke, obsPartition);
      InserterUtils.loadDelimitedDataTruth(inserter, Paths.get(dataPath, "joke_obs.txt").toString());

      inserter = dataStore.getInserter(RatingPrior, obsPartition);
      InserterUtils.loadDelimitedDataTruth(inserter, Paths.get(dataPath, "ratingPrior_obs.txt").toString());

      inserter = dataStore.getInserter(SimObsRating, obsPartition);
      InserterUtils.loadDelimitedDataTruth(inserter, Paths.get(dataPath, "simObsRating_obs.txt").toString());

      inserter = dataStore.getInserter(User, obsPartition);
      InserterUtils.loadDelimitedDataTruth(inserter, Paths.get(dataPath, "user_obs.txt").toString());

      inserter = dataStore.getInserter(Rating, obsPartition);
      InserterUtils.loadDelimitedDataTruth(inserter, Paths.get(dataPath, "rating_obs.txt").toString());

      inserter = dataStore.getInserter(Rating, targetsPartition);
      InserterUtils.loadDelimitedData(inserter, Paths.get(dataPath, "rating_targets.txt").toString());

      inserter = dataStore.getInserter(Rating, truthPartition);
      InserterUtils.loadDelimitedDataTruth(inserter, Paths.get(dataPath, "rating_truth.txt").toString());
   }

   @Override
   protected Set<StandardPredicate> getClosedPredicates() {
      return new HashSet<StandardPredicate>([AvgJokeRatingObs, AvgUserRatingObs, Joke, RatingPrior, SimObsRating, User]);
   }

   @Override
   protected Set<StandardPredicate> getOpenPredicates() {
      return new HashSet<StandardPredicate>([Rating]);
   }

   @Override
   public void eval() {
      continuousEval();
   }
}
