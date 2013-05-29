#!/usr/bin/python
from collections import defaultdict
import os
import pickle
import sys
from rteTools import SRLTools

def main(argv):
    with open(argv[0], 'rb') as f:
        pairs = pickle.load(f)
        is_h = defaultdict(int)
        vz_t = defaultdict(int)
        vz_h = defaultdict(int)
        v_t = defaultdict(int)
        v_h = defaultdict(int)
        neg_t = defaultdict(int)
        neg_h = defaultdict(int)
        ne_t = defaultdict(int)
        ne_h = defaultdict(int)
        f_t = defaultdict(int)
        f_h = defaultdict(int)
        is_pos = defaultdict(int)
        for pair in pairs:
            id = pair.get_id()
            value = pair.get_value()
            lemmas_text = pair.get_feature_text('lemmas')
            lemmas_hypo = pair.get_feature_hypo('lemmas')
            frames_text = pair.get_feature_text('frames')
            frames_hypo = pair.get_feature_hypo('frames')
            ne_text = pair.get_feature_text('ne')
            ne_hypo = pair.get_feature_hypo('ne')
            pos_text = pair.get_feature_text('pos')
            pos_hypo = pair.get_feature_hypo('pos')
            chunk_text = pair.get_feature_text('chunks')
            chunk_hypo = pair.get_feature_hypo('chunks')
            srl_t = SRLTools(lemmas_text, frames_text)
            srl_h = SRLTools(lemmas_hypo, frames_hypo)
            verbs_t = srl_t.get_verbs()
            verbs_h = srl_h.get_verbs()
            wf_t = srl_t.get_words_frame()
            wf_h = srl_h.get_words_frame()
            #check if trere 'is' in h
            for verb, span in verbs_h:
                if verb == 'be':
                    is_h[id] += 1
                    break
            for (word, tag) in pos_hypo:
                if tag.startswith('V'):
                    if word == 'is':
                        is_pos[id] += 1
                        break
            #check neg words in h
            if check_token('no', lemmas_hypo) or check_token('not', lemmas_hypo):
                neg_h[id] += 1

            if check_token('no', lemmas_text) or check_token('not', lemmas_text):
                neg_t[id] += 1
            
            if len(verbs_h) == 0:
                vz_h[id] += 1

            if len(verbs_t) == 0:
                vz_t[id] += 1


            for token, tag in ne_hypo:
                ne_h[tag] += 1

            for token, tag in ne_text:
                ne_t[tag] += 1

            for verb, frame in wf_t.items():
                v_t[verb] +=1
                for tag, words in frame:
                    f_t[tag] += 1

            for verb, frame in wf_h.items():
                v_h[verb] += 1
                for tag, words in frame:
                    f_h[tag] += 1


    #stats
    print 'total of pairs: ', len(pairs)
    print 'H sentences with verb(is): POS', len(is_pos.keys())
    print 'H sentences with verb(is): SRL ', len(is_h.keys())
    print 'H sentences with neg words: ', len(neg_h.keys())
    print 'T sentences with neg words: ', len(neg_t.keys())
    print 'H sentences with no verbs: ', len(vz_h.keys())
    print 'T sentences with no verbs: ', len(vz_t.keys())
    print '#############################'
    print 'T types of arguments: %s'%f_t
    print '#############################'
    print 'H types of arguments: %s'%f_h
    print '#############################'
    print 'T NE types: %s'%ne_t
    print '#############################'
    print 'H NE types: %s'%ne_h
    print '#############################'
    print 'T verb types: %s'%v_t
    print '#############################'
    print 'H verb types: %s'%v_h
    return

def check_token(token, words):
    result = 0
    for word in words:
        if word == token:
            result = 1
            break
    return result

if __name__ == '__main__':
    if len(sys.argv) != 2:
        print 'Usage: ./stats_rte.py <pickle-file> > <log>'
        sys.exit(0)
    else:
        main(sys.argv[1:])


