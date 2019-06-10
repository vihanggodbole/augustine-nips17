package edu.ucsc.cs;


import java.util.Collections;
import java.util.Iterator;
import java.util.Random;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;


import org.linqs.psl.application.inference.*;
import org.linqs.psl.application.learning.weight.maxlikelihood.*;
import org.linqs.psl.config.*;
import org.linqs.psl.core.*;
import org.linqs.psl.core.inference.*;
import org.linqs.psl.database.*;
import org.linqs.psl.database.rdbms.*;
import org.linqs.psl.database.rdbms.driver.H2DatabaseDriver;
import org.linqs.psl.database.rdbms.driver.H2DatabaseDriver.Type;
import org.linqs.psl.utils.evaluation.statistics.DiscretePredictionComparator;
import org.linqs.psl.utils.evaluation.statistics.DiscretePredictionStatistics;
import org.linqs.psl.utils.dataloading.InserterUtils;

import org.linqs.psl.groovy.*;
import org.linqs.psl.groovy.PSLModel;

import org.linqs.psl.model.atom.*;
import org.linqs.psl.model.formula.*;
import org.linqs.psl.model.function.*;
import org.linqs.psl.model.kernel.*;
import org.linqs.psl.model.predicate.*;
import org.linqs.psl.model.term.*;
import org.linqs.psl.model.rule.*;
import org.linqs.psl.model.weight.*;



import org.linqs.psl.ui.loading.*;
import org.linqs.psl.util.database.*;

import com.google.common.collect.Iterables;

import org.linqs.psl.evaluation.resultui.printer.*;

import java.io.*;
import java.util.*;

import groovy.time.*;


class JointStanceDisagreementPrediction{
    Logger log = LoggerFactory.getLogger(this.class);

    private ExperimentConfig ec;
    private PSLModel model;
    private DataStore data;


    class ExperimentFold{
        public int fold;

        public Partition cvTruth;
        public Partition cvTest;
        public Partition cvTrain;

        public Partition wlTruth;
        public Partition wlTest;
        public Partition wlTrain;

        public ExperimentFold(int fold){
            this.fold = fold;
        }
    }

    class ExperimentConfig{
        public ConfigBundle cb;

        Date start;

        public String experimentName;
        public String dbPath;
        public String dataPath;
        public String outputPath;

        public boolean useSquaredPotentials = true;
        public double initialWeight;

        public int numFolds;

        public Map<Predicate, String> predicateFileMap;
        public Map<Predicate, Boolean> predicateInsertionTypeMap;
        public Set<Predicate> closedPredicates;
        public Set<Predicate> inferredPredicates; 

        public ExperimentConfig(ConfigBundle cb){
            this.cb = cb;
            this.start = new Date();

            this.experimentName = cb.getString('experiment.name', 'default');
            this.dbPath = cb.getString('experiment.dbpath', '/tmp/');
            this.dataPath = cb.getString('experiment.data.path', 'data/');
            this.outputPath = cb.getString('experiment.output.outputdir', 'output/'+this.experimentName+'/');

            this.initialWeight = cb.getDouble('experiment.wl.initweight', 5.0);
            this.numFolds = cb.getDouble('experiment.numfolds', 5);
        }
    }

    public JointStanceDisagreementPrediction(ConfigBundle cb){
        this.ec = new ExperimentConfig(cb);
        this.data = new RDBMSDataStore(new H2DatabaseDriver(Type.Disk, ec.dbPath+'stanceprediction', true), ec.cb);
        this.model = new PSLModel(this, this.data);
    }


    private void definePredicateInsertionMaps(ExperimentConfig ec){

        ec.predicateFileMap = [((Predicate)localPro):"localPro.csv",
        ((Predicate)localDisagrees):"localDisagrees.csv",
        ((Predicate)participates):"participates.csv",
        ((Predicate)responds):"responds.csv",
        ((Predicate)isProAuth):"isProAuth.csv",
        ((Predicate)disagrees):"disagrees.csv"];

        ec.predicateInsertionTypeMap = [((Predicate)localPro):true,
        ((Predicate)localDisagrees):false,
        ((Predicate)participates):false,
        ((Predicate)responds):false,
        ((Predicate)isProAuth):true,
        ((Predicate)disagrees):true];  

    }


    private void definePredicates(){

        model.add predicate: "participates", types: [ConstantType.UniqueID, ConstantType.UniqueID];
        model.add predicate: "localPro", types: [ConstantType.UniqueID, ConstantType.UniqueID];
        model.add predicate: "localDisagrees", types: [ConstantType.UniqueID, ConstantType.UniqueID];

        /*
         * Auxiliary topic predicate
         */
         model.add predicate: "responds", types: [ConstantType.UniqueID, ConstantType.UniqueID];

        /*
         * Target predicates
         */
         model.add predicate: "isProAuth", types: [ConstantType.UniqueID, ConstantType.UniqueID];
         model.add predicate: "disagrees", types: [ConstantType.UniqueID, ConstantType.UniqueID];

         ec.closedPredicates = [participates, localDisagrees, localPro, responds] as Set;
         ec.inferredPredicates = [isProAuth, disagrees] as Set;

     }

     private void defineRules(){

        log.info("Defining model rules");
        def initialWeight = ec.initialWeight;

        //Prior that the label given by the text classifier is indeed the stance labe, likewise for disagreement

        model.add( rule: (localPro(A, T)) >> isProAuth(A, T), squared: true, weight : initialWeight)
        model.add( rule : (~(localPro(A, T))) >> ~(isProAuth(A, T)), squared:true, weight : initialWeight) 

        model.add( rule: (localDisagrees(A1, A2)) >> disagrees(A1, A2), squared:true, weight: initialWeight)
        model.add( rule: (~localDisagrees(A1, A2)) >> ~disagrees(A1, A2), squared:true, weight: initialWeight)

        //Disagreement affects stance

        model.add( rule: (disagrees(A1, A2) & (A1 - A2) & responds(A1, A2) & participates(A2, T) & isProAuth(A1, T)) >> ~isProAuth(A2, T), squared:true, weight: initialWeight)
        model.add( rule: (disagrees(A1, A2) & (A1 - A2) & responds(A1, A2) & participates(A1, T) & participates(A2, T) & ~isProAuth(A1, T)) >> isProAuth(A2, T), squared:true, weight: initialWeight)

        model.add( rule: (~disagrees(A1, A2) & (A1 - A2) & responds(A1, A2) & participates(A2, T) & isProAuth(A1, T)) >> isProAuth(A2, T), squared:true, weight: initialWeight)
        model.add( rule: (~disagrees(A1, A2) & (A1 - A2) & responds(A1, A2) & participates(A1, T) & participates(A2, T) & ~isProAuth(A1, T)) >> ~isProAuth(A2, T), squared:true, weight: initialWeight)

        model.add( rule: (disagrees(A1, A2) & (A1 - A2) & responds(A1, A2) & participates(A1, T) & isProAuth(A2, T)) >> ~isProAuth(A1, T), squared:true, weight: initialWeight)
        model.add( rule: (disagrees(A1, A2) & (A1 - A2) & responds(A1, A2) & participates(A1, T) & participates(A2, T) & ~isProAuth(A2, T)) >> isProAuth(A1, T), squared:true, weight: initialWeight)

        model.add( rule: (~disagrees(A1, A2) & (A1 - A2) & responds(A1, A2) & participates(A1, T) & isProAuth(A2, T)) >> isProAuth(A1, T), squared:true, weight: initialWeight)
        model.add( rule: (~disagrees(A1, A2) & (A1 - A2) & responds(A1, A2) & participates(A1, T) & participates(A2, T) & ~isProAuth(A2, T)) >> ~isProAuth(A1, T), squared:true, weight: initialWeight)

        //Stance affects disagreement

        model.add( rule: (responds(A1, A2) & (A1 - A2) & participates(A2, T) & isProAuth(A1, T) & ~isProAuth(A2, T)) >> disagrees(A1, A2), squared:true, weight: initialWeight)
        model.add( rule: (responds(A1, A2) & (A1 - A2) & participates(A1, T) & ~isProAuth(A1, T) & isProAuth(A2, T)) >> disagrees(A1, A2), squared:true, weight: initialWeight)

        model.add( rule: (responds(A1, A2) & (A1 - A2) & participates(A2, T) & isProAuth(A1, T) & isProAuth(A2, T)) >> ~disagrees(A1, A2), squared:true, weight: initialWeight)
        model.add( rule: (responds(A1, A2) & (A1 - A2) & participates(A1, T) & participates(A2, T) & ~isProAuth(A1, T) & ~isProAuth(A2, T)) >> ~disagrees(A1, A2), squared:true, weight: initialWeight)

    }



    private void loadObservedData(Partition trainPartition, String evidenceType, ExperimentFold ef){

        for(Predicate pred: ec.closedPredicates){
            String fileName = ec.predicateFileMap[pred];
            def inserter = data.getInserter(pred, trainPartition);

            def fullFilePath = ec.dataPath + '/' + ef.fold + '/' + evidenceType + '/' + fileName;

            if(ec.predicateInsertionTypeMap[pred]){
                InserterUtils.loadDelimitedDataTruth(inserter, fullFilePath, ',');
            }
            else{
                InserterUtils.loadDelimitedData(inserter, fullFilePath, ',');
            }
        }
    }


    private void loadFoldData(ExperimentFold ef){
        def fold = ef.fold;

        ef.cvTrain = data.getPartition('cvtrain' + fold);
        ef.cvTest = data.getPartition('cvtest' + fold);
        ef.cvTruth = data.getPartition('cvtruth' + fold);

        ef.wlTrain = data.getPartition('wltrain' + fold);
        ef.wlTest = data.getPartition('wltest' + fold);
        ef.wlTruth = data.getPartition('wltruth' + fold);

        log.info("Setting up partitions for cross fold experiment");

        loadObservedData(ef.wlTrain, 'train', ef);
        loadObservedData(ef.cvTrain, 'test', ef);

        loadTruthData(ef.wlTruth, 'train', ef);
        loadTruthData(ef.cvTruth, 'test', ef);
        
    }


    /* Needs to be completed so that truth data can be read into partitions accordingly */
    private void loadTruthData(Partition truthPartition, String evidenceType, ExperimentFold ef){

        for(Predicate pred: ec.inferredPredicates){
            String fileName = ec.predicateFileMap[pred];
            def inserter = data.getInserter(pred, truthPartition);

            def fullFilePath = ec.dataPath + '/' + ef.fold + '/' + evidenceType + '/' + fileName;

            if(ec.predicateInsertionTypeMap[pred]){
                InserterUtils.loadDelimitedDataTruth(inserter, fullFilePath, ',');
            }
            else{
                InserterUtils.loadDelimitedData(inserter, fullFilePath, ',');
            }
        }
    }

    private void populateDatabase(Database dbToPopulate, Partition populatePartition){

        Database populationDatabase = data.getDatabase(populatePartition, ec.inferredPredicates);
        DatabasePopulator dbPop = new DatabasePopulator(dbToPopulate);

        for (Predicate p : ec.inferredPredicates){
            dbPop.populateFromDB(populationDatabase, p);
        }

        populationDatabase.close();

    }

    private void learnWeights(ExperimentFold ef){

        log.info("Learning weights on fold " + ef.fold);

        def weightLearningEvidencePartition = ef.wlTrain;
        def weightLearningWritePartition = ef.wlTest;
        def weightLearningTruthPartition = ef.wlTruth;


        Database wlTrainDB = data.getDatabase(weightLearningWritePartition, ec.closedPredicates, weightLearningEvidencePartition);
        populateDatabase(wlTrainDB, weightLearningTruthPartition);

        Database wlTruthDB = data.getDatabase(weightLearningTruthPartition, ec.inferredPredicates);

        if(ef.fold > 0){
            for(WeightedRule r : model.getRules()){
                r.setWeight(new PositiveWeight(ec.initialWeight));
            }
        }

        def weightLearner = new MaxLikelihoodMPE(model, wlTrainDB, wlTruthDB, ec.cb);

        weightLearner.learn();
        weightLearner.close();

        wlTruthDB.close();
        wlTrainDB.close();

    }

    private void runInference(ExperimentFold ef){

        def inferenceEvidencePartition = ef.cvTrain;
        def inferenceWritePartition = ef.cvTest;
        def inferenceTruthPartition = ef.cvTruth;

        Database inferenceDB = data.getDatabase(inferenceWritePartition, ec.closedPredicates, inferenceEvidencePartition);

        populateDatabase(inferenceDB, inferenceTruthPartition);

        def inferenceApp = new MPEInference(model, inferenceDB, ec.cb);
        inferenceApp.mpeInference();
        inferenceDB.close();
    }
    
    
    private void evalResults(ExperimentFold ef){
        def inferenceResultsPartition = ef.cvTest;
        def inferenceTruthPartition = ef.cvTruth;
        def inferredPredicates = ec.inferredPredicates;

        Database resultsDB = data.getDatabase(inferenceResultsPartition, inferredPredicates);
        Database truthDB = data.getDatabase(inferenceTruthPartition, inferredPredicates);

        DiscretePredictionComparator dpc = new DiscretePredictionComparator(resultsDB);
        dpc.setBaseline(truthDB);
        dpc.setThreshold(0.5);

        def stats = dpc.compare(isProAuth);
        log.warn("Accuracy: " + stats.getAccuracy());

        resultsDB.close();
        truthDB.close();

    }



    private static ConfigBundle populateConfigBundle(String[] args){
        ConfigBundle cb = ConfigManager.getManager().getBundle("stanceprediction");
        if(args.length > 0){
            System.out.println(args[0]);
            cb.setProperty('experiment.data.path', args[0]);
        }

        if(args.length > 1){
            cb.setProperty('experiment.name', args[1]);
        }

        return cb;
    }

    
    public void mainExperiment(){

        this.definePredicates();
        this.defineRules();

        this.definePredicateInsertionMaps(ec);

        for(int i = 0; i < ec.numFolds; i++){
            ExperimentFold ef = new ExperimentFold(i);
            this.loadFoldData(ef);
            this.learnWeights(ef);
            this.runInference(ef);
            this.evalResults(ef);

        }

        data.close();
        
    }


    public static void main(String[] args){

        ConfigBundle cb = populateConfigBundle(args);
        JointStanceDisagreementPrediction jsdp = new JointStanceDisagreementPrediction(cb);
        jsdp.mainExperiment();

    }
}
