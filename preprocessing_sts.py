#!/usr/bin/python
import nltk
import treetaggerwrapper
import sys
import subprocess
import pickle
from pair import Pair
import os
import codecs
from collections import deque

def main(args):
    (sts_file, score_file, task, senna_path, tt_path) = args
	#print sts_file, score_file, task, senna_path, tt_path
    preprocess(sts_file, score_file, task, senna_path, tt_path)
    return

def preprocess(sts_file = '', score_file = '', task = 'sts', senna_path = '/media/raid-vapnik/tools/senna/', tt_path = '/home/tools/treetagger/'):
    entailment_pairs = []
    scores = load_scores(score_file)
    (filepath, filename) = os.path.split(sts_file)
    (name, extension) = os.path.splitext(filename)
    with open(sts_file, 'r') as sts_f:
        id = 0
        for line in sts_f:
            line = line.rstrip('\n')
            (text, hypo) = line.split('\t')
            features_text = run_senna(text, id, name, senna_path, tt_path)
            features_hypo = run_senna(hypo, id, name, senna_path, tt_path)
            value = scores.popleft()
            pair = Pair(id, text, hypo, value, task, features_text, features_hypo)
            entailment_pairs.append(pair)
            id += 1
        (filepath, filename) = os.path.split(sts_file)
        (pickle_name, extension) = os.path.splitext(filename)
        pickle_name = '%s.pickle' % pickle_name  
        with open(pickle_name, 'w') as f:
            pickle.dump(entailment_pairs, f) 
            f.close()               
    return

def load_scores(score_file = ''):
    score_queue = deque()
    with open(score_file, 'r') as f:
        for line in f:
            line = line.rstrip('\n')
            score_queue.append(line)
    return score_queue


def run_senna(text, id, name, senna_path, tt_path):
    features = {}
    cols = ('words', 'pos', 'chunk', 'ne','srl')
    input = '%s.sts'%name
    output = '%s.sts.srl'%name
    
    #with codecs.open(input, 'w', 'utf-8') as f:
    #    f.write(text)
    with open(input, 'w') as f:
        f.write(text)

	f.close()
    senna_command = '%s/senna-linux64 -path %s/ < %s' %(senna_path, senna_path, input)
    proc = subprocess.Popen(senna_command,shell=True, stderr=subprocess.PIPE, stdout=subprocess.PIPE)
    return_code = proc.wait()
    iob_2_conll(proc.stdout, output)
    conll = nltk.corpus.reader.ConllCorpusReader(root = './', fileids = output, columntypes = cols, srl_includes_roleset= False)
    sents = conll.sents()
    tagger = treetaggerwrapper.TreeTagger(TAGLANG = 'en', TAGDIR = tt_path)
    lemmas_tt = lemmas_Treetagger(tagger,' '.join(sents[0]))
    grids = conll._grids()
    ne_grid = conll._get_column(grids[0], 3)
    ne = attach_ne(ne_grid, sents[0])
    srl_frames = conll.srl_spans() #all the frames in the text
    features['words'] = sents[0]
    features['pos'] = conll.tagged_sents()[0]
    features['lemmas'] = lemmas_tt
    features['chunks'] = conll.chunked_sents()[0]
    features['ne'] = ne
    features['frames'] = srl_frames[0]
    return features

def lemmas_Treetagger(tagger, sentence):
    lemmas = []
    tags = tagger.TagText(sentence)
    for tag in tags:
        (word, pos, lemma) = tag.split()
        if lemma.startswith('<unknown>'):
            lemmas.append(word)
        else:
            lemmas.append(lemma)
    return lemmas


def attach_ne(ne_grid, sentence):
    ne_list = []
    words = []
    i = 0
    for ne in ne_grid:
        if ne.startswith('B-'):
            words.append(sentence[i]) 
            i += 1                                      
        elif ne.startswith('I-'):
            words.append(sentence[i]) 
            i += 1
        elif ne.startswith('E-'):
            (iob, tag) = ne.split('-',1)
            words.append(sentence[i])
            ne_list.append((words, tag))
            del words[:] 
            i += 1               
        elif ne.startswith('S-'):
            (iob, tag) = ne.split('-',1)             
            ne_list.append((sentence[i], tag))            
            i += 1               
        elif ne.startswith('O'):
            ne_list.append((sentence[i], ne))
            i += 1                       
    return ne_list

def iob_2_conll(input, output):
    try:
        f = open(output, 'w')
    except:
        print 'file %s not found' %output
    start = 5
    for line in input:
        line.strip()        
        tokens = line.split()
        new_line = tokens[:start] #start-1
        frames = tokens[start:]        
        new_frames = []
        #print line
        for frame in frames:
            new_tag = ''
            if frame.startswith('B-'):
                (iob, tag) = frame.split('-',1)
                new_tag = '(' + tag + '*'                
            elif frame.startswith('I-'):
                new_tag = '*'                
            elif frame.startswith('E-'):
                new_tag = '*)'               
            elif frame.startswith('S-'):
                (iob, tag) = frame.split('-',1)
                new_tag = '(' + tag + '*' + ')'                
            elif frame.startswith('O'):
                new_tag = '*'
            new_frames.append(new_tag)
        new_line.extend(new_frames)
        print >>f, '\t'.join(new_line)
    f.close()
    return

if __name__ == "__main__":
    if len(sys.argv[1:]) != 5:
        print 'USAGE: ./preprocessing_sts.py <sts-file> <score-file> <task> <senna-path> <tt-path>'
        sys.exit(0)
    else:
        main(sys.argv[1:])
