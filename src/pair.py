#!/usr/bin/python

class Pair:
    """This is a Pair object with:
    param: id, id of the the pair
    param: text, string of the text part
    param: hypo, string of the hypothesis part
    param: value, entialment decision
    param: task, task of the current pair
    param: features_text, features from the connll style file for the text part
    param:features_hypo, features from the connll style file for the hypo part
    """
    def __init__(self, id = -1, text = '', hypo = '', value = '', task = '', features_text = {}, features_hypo = {}):
        self.id = id
        self.text = text
        self.hypo = hypo
        self.value = value
        self.task = task
        self.features_text = features_text
        self.features_hypo = features_hypo
    #Getterts
    def get_id(self):
        return self.id
    
    def get_text(self):
        return self.text
    
    def get_hypo(self):
        return self.hypo
    
    def get_value(self):
        return self.value
    
    def get_task(self):
        return self.task
    
    def get_features_text(self):
        return self.features_text
    
    def get_feature_text(self, feature_name):
        """The method returns the value of a feature
        Input:
            feature_name: string with the name of the feature
        Output:
            the value of the feature related to feature_name (e.g. list of words)        
        """
        return self.features_text[feature_name]
    
    def get_features_text_type(self):
        return self.features_text.keys()
    
    def get_features_hypo(self):
        return self.features_hypo
    
    def get_feature_hypo(self, feature_name):
        """The method returns the value of a feature
        Input:
            feature_name: string with the name of the feature
        Output:
            the value of the feature related to feature_name (e.g. list of words)        
        """
        return self.features_hypo[feature_name]
    
    def get_features_hypo_type(self):
        return self.features_hypo.keys()
    #Setters
    def set_features_text(self, feature_name = '', feature_value = ''):
        """The method set a feature name, feature value pair for the text part
        Input:
            feature_name: string with the name of the feature
            feature_value: the value of the feature (e.g. list with words)
        """
        self.features_text[feature_name] = feature_value
    
    def set_features_hypo(self, feature_name = '', feature_value = ''):
        """The method set a feature name, feature value pair for the hypo part
        Input:
            feature_name: string with the name of the feature
            feature_value: the value of the feature (e.g. list with words)
        """
        self.features_hypo[feature_name] = feature_value
    
