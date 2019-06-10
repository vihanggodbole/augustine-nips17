package edu.ucsc.cs;

import org.linqs.psl.config.*;
import java.io.*;
import java.util.*;

public class FullForumsExperiment{
	private int numExperiments = 5;
	private String dataPath = "data/";
	private String forums = ["4forums", "createdebate"];
	private String ff_topics = ["abortion", "evolution", "gaymarriage", "guncontrol"];
	private String cd_topics = ["abortion", "gayRights", "marijuana", "obama"];
	private ConfigBundle cb;


	public FullForumsExperiment(String experimentName){
		this.cb = ConfigManager.getManager().getBundle(experimentName);
	}

	public static void main(String[] args){

		FullForumsExperiment ffe = new FullForumsExperiment("stance-classification-full-experiment");

		for(String forum: ffe.forums){

			def topics = ffe.cd_topics;
			if(forum == "4forums"){
				topics = ffe.ff_topics;
			}
			for(String topic: topics){
				for(int i = 0; i < ffe.numExperiments; i++){
					ffe.cb.setProperty('experiment.data.path', ffe.dataPath + forum + '/' + topic + '/' + i);
					JointStanceDisagreementPrediction jsdp = new JointStanceDisagreementPrediction(ffe.cb);
					jsdp.mainExperiment();
				}
			}
		}
	}

}
