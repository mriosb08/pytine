#!/usr/bin/python
from pair import Pair
import pickle
import sys
from metrics import SetMetrics, VerbMetrics, Lin, VectorMetrics
from rteTools import RTETools, WNTools, SRLTools
def main(args):
    pickle_file = args[0]
    print 'loading file:',pickle_file
    with open(pickle_file, 'r') as pf:
        pairs = pickle.load(pf)
        k = 0        
        for pair in pairs:
            print 'id:', pair.get_id()
            print 's1:', pair.get_text()
            print 's2:', pair.get_hypo()
            print 'features:', pair.get_features_text_type()
            print 'set-metrics, cos test'
            lemmas_text = pair.get_feature_text('lemmas')
            lemmas_hypo = pair.get_feature_hypo('lemmas')
            set_th = SetMetrics(lemmas_text, lemmas_hypo)
            cos = set_th.cosine()
            #print cos
            print 'SRL tools'
            frames_text = pair.get_feature_text('frames')
            print frames_text
            print '################'
            srl = SRLTools(lemmas_text, frames_text)
            word_to_frame = srl.get_words_frame()
            print word_to_frame
            print '################'
            print srl.get_verbs()
            print '################'
            
            #print 'verb-metrics, '
            pos_text = pair.get_feature_text('pos')
            pos_hypo = pair.get_feature_hypo('pos')
            verbs = VerbMetrics()
            lin = Lin()
            vectors = VectorMetrics()
            hyper = WNTools()
            for i, pos_tuple_t in enumerate(pos_text):
                (token, pos_t) = pos_tuple_t
                if pos_t.startswith('V'):
                    for j, pos_tuple_h in enumerate(pos_hypo):
                        (token, pos_h) = pos_tuple_h
                        if pos_h.startswith('V'):                            
                            verbs.set_text_verb(lemmas_text[i])
                            verbs.set_hypo_verb(lemmas_hypo[j])
                            #print 'verbs test t:%s h:%s'%(lemmas_text[i], lemmas_hypo[j])
                            vn_isec = verbs.vn_isec()
                            #print 'verb net isec: %d'%vn_isec
                            #print 'lin(%s):'%lemmas_text[i], '\n', lin.n_similar_words(lemmas_text[i])
                            #print 'lin(%s):'%lemmas_hypo[j], '\n', lin.n_similar_words(lemmas_hypo[j])
                            t_sim = lin.n_similar_words(lemmas_text[i])
                            h_sim = lin.n_similar_words(lemmas_hypo[j])
                            t_score = [float(score) for word,score in t_sim]
                            h_score = [float(score) for word,score in h_sim]
                            vectors.set_vectors(t_score, h_score)
                            #print 'cos_vect: ', vectors.cosine()
                        elif pos_h.startswith('N'):
                            #print 'wn test hypernyms'
                            trees = hyper.get_mfs_hypernyms((lemmas_hypo[j], pos_h))
                            #print trees


            k += 1
            if k >= 10:
                break
        pf.close
    return

if __name__ == "__main__":
    if len(sys.argv[1:]) != 1:
        print 'USAGE:./test.py <pickle-file>'
        sys.exit(0)
    else:
        main(sys.argv[1:])
