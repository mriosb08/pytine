import string
import os
import math
import subprocess
from bsddb3 import db
from rteTools import Lin
class SetMetrics:
    """Metrics based on sets, the text and hypo are transformed into sets
    Input:
        text: list of tokens
        hypo: list of tokens
        bleu_path: string path to bleu 
        meteor_path: string path to meteor
    """
    
    def __init__(self, text = [], hypo = [], bleu_path = './', meteor_path = '/media/raid-vapnik/tools/meteor-1.3'):
        self.text = set(text)
        self.hypo = set(hypo)
        self.bleu_path = bleu_path
        self.meteor_path = meteor_path
        self.precision = 0
        self.recall = 0
        return
    #setters
    def set_text(self, text = []):
        """Method stores the text as a set
        Input:
            text: list of tokens
        """
        self.text = set(text)
        return
    
    def set_hypo(self, hypo = []):
        """Method stores the hypo as a set
        Input:
            hypo: list of tokens
        """
        self.hypo = set(hypo)
        return
    #getters
    def get_text(self):
        return self.text
    
    def get_hypo(self):
        return self.hypo
    
    def text_to_string(self, sep = ' '):
        return sep.join(self.text)
    
    def hypo_to_string(self, sep = ' '):
        return sep.join(self.hypo)
    
    def cosine(self):
        """Computes cosine metric
        Output:
            cosine score
        """
        isec = self.text & self.hypo
        try:
            result = float(len(isec)) / math.sqrt(len(self.text) * len(self.hypo))
            return result
        except:
            return 0.0
    
    def dice(self):
        """Computes dice metric
        Output:
            dice score
        """
        isec = self.text & self.hypo
        try:
            result = (2 * float(len(isec))) / (len(self.text) + len(self.hypo))
            return result
        except:
            return 0.0
    
    def jaccard(self):
        """Computes jaccard metric
        Output:
            jaccard score
        """
        isec = self.text & self.hypo
        union = self.text | self.hypo
        try:
            result = float(len(isec)) / len(union)
            return result
        except:
            return 0.0
    
    def overlap(self):
        """Computes overlap metric
        Output:
            overlap score
        """
        isec = self.text & self.hypo
        try:
            result = float(len(isec)) / min(len(self.text), len(self.hypo))
            return result
        except:
            return 0.0
    
    def get_precision(self):
        """Computes precision
        Output:
            precision score
        """
        isec = self.text & self.hypo
        len_i = len(isec)
        try:
            self.precision = float(len(isec)) / len(self.hypo)
            return self.precision
        except:
            return 0.0
    
    def get_recall(self):
        """Computes recall
        Output:
            recall score
        """
        isec = self.text & self.hypo
        try:
            self.recall = float(len(isec)) / len(self.text)
            return self.recall
        except:
            return 0.0
    
    def get_f1(self):
        """Computes F1
        Output:
            F1 score
        """
        if self.precision + self.recall == 0:
            return 0
        result = 2 * ((self.precision * self.recall) / (self.precision + self.recall))
        return result

    def get_isec(self):
        """Returns the size of the intersection between text and hypo
        """
        isec = self.text & self.hypo
        return len(isec)
    
    def bleu(self):
        """Calls bleu tool and runs it for the text and hypo"""
        try:
            f_text = open('tmp.text','w')
            f_hypo = open('tmp.hypo','w')
            f_text.write(' '.join(self.text))
            f_hypo.write(' '.join(self.hypo))
            f_text.close()
            f_hypo.close()
        except:
            print 'tmp files error!!!'
        command = '%s/multi-bleu.pl tmp.text < tmp.hypo' % self.bleu_path
        proc = subprocess.Popen(command, shell=True, stderr=subprocess.PIPE, stdout=subprocess.PIPE)
        return_code = proc.wait()
    
        for line in proc.stdout:
            (bs, ngrams, info) = line.split()
            (tag, score) = bs.split('=')
        os.remove('tmp.text')
        os.remove('tmp.hypo')
        return float(score.strip())

    def meteor(self):
        """Calls meteor tool and runs it for the text and hypo"""
        try:
            f_text = open('tmp.text','w')
            f_hypo = open('tmp.hypo','w')
            f_text.write(' '.join(self.text))
            f_hypo.write(' '.join(self.hypo))
            f_text.close()
            f_hypo.close()
        except:
            print 'tmp files error!!!'
        command = 'java -Xmx2G -jar %s/meteor-1.3.jar tmp.hypo tmp.text' % self.meteor_path
        proc = subprocess.Popen(command, shell=True, stderr=subprocess.PIPE, stdout=subprocess.PIPE)
        return_code = proc.wait()
        score = 0
        for line in proc.stdout:
            if line.rstrip().startswith('Final score:'):
                score_info = line.rstrip()
                (tag_a, tag_b, score) = score_info.split()
                break

        os.remove('tmp.text')
        os.remove('tmp.hypo')
        return score

    def meteor_list(self, list_t = [], list_h = []):
        """Call meteor tool and runs it over a list of text and hypo pairs
        Input:
            list_t: list of text parts, one string sentence per position
            list_h: list of hypo parts, one string sentence per position
        """
        ids = []
        try:
            f_text = open('tmp.text','w')
            f_hypo = open('tmp.hypo','w')
            for id, t in list_t:
                f_text.write(' '.join(t) + '\n')
                ids.append(id)
            for id, h in list_h:
                f_hypo.write(' '.join(h) + '\n')
            f_text.close()
            f_hypo.close()
        except:
            print 'tmp files error!!!'

        command = 'java -Xmx2G -jar %s/meteor-1.3.jar tmp.hypo tmp.text' % self.meteor_path
        proc = subprocess.Popen(command, shell=True, stderr=subprocess.PIPE, stdout=subprocess.PIPE)
        return_code = proc.wait()
        final_score = {}
        score = 0
        i = 0
        for line in proc.stdout:
            if line.rstrip().startswith('Segment'):
                score_info = line.rstrip()
                (tag_a, segment_id, tag_b, score) = score_info.split()
                final_score[ids[i]] = float(score)
                #print 'ids: ', ids[i],' score: ',score
                i += 1
        os.remove('tmp.text')
        os.remove('tmp.hypo')
        return final_score


class VectorMetrics:
    """Metrics based on vectors, the text and hypo are vectors of scores.
    Input:
        vector_a: list of scores or values for the text part
        vector_b: list of scores or values for the text part
    
    """

    def __init__(self, vector_a = [], vector_b = []):
        self.vector_a = vector_a
        self.vector_b = vector_b
        return
    #setters
    def set_vectors(self, vector_a = [], vector_b = []):
        self.vector_a = vector_a
        self.vector_b = vector_b
        return
    #getters
    def get_vectors(self):
        return (self.vector_a, self_vector_b)

    def cosine(self):
        """Computes the cosine between two vectors
        Output:
            cosine score
        """
        self.result = 0.0
        if len(self.vector_a) != len(self.vector_b) or len(self.vector_a) == 0 or len(self.vector_b) == 0:
            return None
        sum_xy = [(self.vector_a[i] * self.vector_b[i]) for i in range(len(self.vector_a))]
        sum_x = [(self.vector_a[i] ** 2) for i in range(len(self.vector_a))]
        sum_y = [(self.vector_b[i] ** 2) for i in range(len(self.vector_b))]
        self.result = sum(sum_xy) / (math.sqrt(sum(sum_x))* math.sqrt(sum(sum_y)))
        return self.result
    

class VerbMetrics:
    """Similarity metrics between a pair of verbs fro the text hypo pair.
    Input:
        text_v: verb from the text
        hypo_v: verb from the hypo
        vn_file: file path for VerbNet db
        vo_file: file path for VerbOcean db
        direct_file: file path for direct db
    """
    
    def __init__(self, text_v = '', hypo_v = '', vn_file = 'data/vn_classes.db', vo_file = 'data/verbocean.db', direct_file = 'data/DIRECT_verbs_1000.db', vn_strict = 0):
        self.text_v = text_v
        self.hypo_v = hypo_v
        self.vn_strict = vn_strict
        self.direct_DB = db.DB()
        self.direct_DB.open(direct_file, None, db.DB_BTREE, db.DB_DIRTY_READ)
        self.vn_DB = db.DB()
        self.vn_DB.open(vn_file, None, db.DB_BTREE, db.DB_DIRTY_READ)
        self.vo_DB = db.DB()
        self.vo_DB.open(vo_file, None, db.DB_BTREE, db.DB_DIRTY_READ)
        self.vo_relations = ('can-result-in'
                            ,'happens-before'
                            ,'low-vol'
                            ,'opposite-of'
                            ,'similar'
                            ,'stronger-than'
                            ,'unk')
        return
    #setters
    def set_text_verb(self, text_v = ''):
        self.text_v = text_v
        return

    def set_hypo_verb(self, hypo_v = ''):
        self.hypo_v = hypo_v
        return
    #getters
    def get_text_verb(self):
        return self.text_v

    def get_hypo_verb(self):
        return self.hypo_v    
    
    def vn_isec(self):
        """Checks if there is an intersection between VerbNet classes for the given pair of verbs
        Output:
            1: if the verbs share at least one class
            0: ow        
        """
        value_text = self.vn_DB.get(self.text_v)
        tmp_text = []
        if value_text:
            if self.vn_strict == 1:
                tmp_text = value_text.split()
            else:
                tmp = value_text.split()
                for tmp_cl in tmp:
                    (verb, cl) = tmp_cl.split('-', 1)
                    tmp_text.append(verb)

        value_hypo = self.vn_DB.get(self.hypo_v)
        tmp_hypo = []
        if value_hypo:
            if self.vn_strict == 1:
                tmp_hypo = value_hypo.split()
            else:
                tmp = value_hypo.split()
                for tmp_cl in tmp:
                    (verb, cl) = tmp_cl.split('-', 1)
                    tmp_hypo.append(verb)
        set_text = set(tmp_text)
        set_hypo = set(tmp_hypo)

        isec = set_text & set_hypo
        if len(isec) > 0:
            return 1
        else:
            return 0

    def direct(self):
        """ Checks if there is an entialment directional relation between the verbs (e.g. koala => animal, is true)
        Output:
            1: if the verbs hold an entialment directional relation
            0: ow
        """
        if self.text_v == self.hypo_v:
            return 1
        else:
            key_th = self.text_v + '|||' + self.hypo_v
            key_ht = self.hypo_v + '|||' + self.text_v
            value_th = self.direct_DB.get(key_th)
            value_ht = self.direct_DB.get(key_ht)
            if value_th > value_ht:
                return 1
            else:
                return 0

    def vo(self, relation = 'similar'):
        key = self.text_v + ' ' + self.hypo_v
        value = self.vo_DB.get(key)
        if value:
            (relation_vo, score) = value.split()
        else:
            relation_vo = 'unk'
        if relation == relation_vo:
            return 1
        else:
            return 0


class NEMetrics:
    """Metrics for Named Entities of the text and hypo
    Input:
        pairs_text: list of named entities from the text
        pairs_hypo: list of named entities from the hypo
        empty_tag: tag for non named entities default: 'O'
    """
    def __init__(self, pairs_text = [], pairs_hypo =[], empty_tag = 'O'):
        self.pairs_text = pairs_text
        self.pairs_hypo = pairs_hypo
        self.ne_score = 0
        self.num_ne = 0
        self.empty_tag = empty_tag
        self.lin = Lin()
        self.sim = SetMetrics()
        return
    
    def set_pairs_text(self, pairs_text = []):
        self.pairs_text = pairs_text
        return

    def set_pairs_hypo(self, pairs_hypo = []):
        self.pairs_hypo = pairs_hypo
        return

    def get_pairs_text(self):
        return self.pairs_text

    def get_pairs_hypo(self):
        return self.pairs_hypo

    def get_score_lin(self):
        """Computes named entity similarity with the help of the Lin thesaurus.
        The entityes with the same type are measure for equality or similarity given the thesaurus.
        Output:
            Named entity score
        """
        sum_ne  = 0
        for token_text, tag_text in self.pairs_text:
            for token_hypo, tag_hypo in self.pairs_hypo:
                if tag_text == tag_hypo and tag_text != self.empty_tag:
                    if token_text == token_hypo:
                        sum_ne += 1
                    else:
                        bow_text = self.lin.expand_w(str(token_text))
                        bow_hypo = self.lin.expand_w(str(token_hypo))
                        self.sim.set_text(bow_text)
                        self.sim.set_hypo(bow_hypo)
                        sum_ne += self.sim.cosine()
                    self.num_ne +=1
        if self.num_ne == 0:
            return 0
        self.ne_score = float(sum_ne) / self.num_ne
        return self.ne_score
