#!/usr/bin/python

class Pair:    
    def __init__(self, id = -1, text = '', hypo = '', value = '', task = '', features_text = {}, features_hypo = {}):
        self.id = id
        self.text = text
        self.hypo = hypo
        self.value = value
        self.task = task
        self.features_text = features_text
        self.features_hypo = features_hypo
    
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
        return self.features_text[feature_name]
    
    def get_features_text_type(self):
        return self.features_text.keys()
    
    def get_features_hypo(self):
        return self.features_hypo
    
    def get_feature_hypo(self, feature_name):
        return self.features_hypo[feature_name]
    
    def get_features_hypo_type(self):
        return self.features_hypo.keys()
    
    def set_features_text(self, feature_name = '', feature_value = ''):
        self.features_text[feature_name] = feature_value
    
    def set_features_hypo(self, feature_name = '', feature_value = ''):
        self.features_hypo[feature_name] = feature_value
    
