#!/usr/bin/python
import pickle
from optparse import OptionParser
import os
import subprocess
import re
from eval_metrics import RTEEvalMetrics
import sys
import time
import random
from collections import defaultdict

def main():
    parser = OptionParser(usage="usage: %prog [options]", version="%prog 1.0")
    parser.add_option("-i", "--train-file", action="store", dest="train_file"
            , help="File with train db file")
    parser.add_option("-o", "--test-file", action="store", dest="test_file"
            , help="File with test db file")
    parser.add_option("-g", "--gs-file", action="store", dest="gs_file"
            , help="Pickle file with id-gs annotation")
    parser.add_option("-a", "--alchemy-path", action="store", dest="a_path"
            , help="Path to alchemy default:/media/raid-vapnik/mrios/workspace/alchemy/alchemy"
            , default="/media/raid-vapnik/mrios/workspace/alchemy/alchemy")
    parser.add_option("-m", "--mln", action="store", dest="mln"
            , help="File with mln rules")
    parser.add_option("-q", "--query", action="store", dest="query"
            , default="Entailment", help="Query for the MLN")

    (options, args) = parser.parse_args()
    if not options.train_file or not options.test_file or not options.gs_file or not options.mln:
        parser.print_help()
        parser.error("wrong number of options")
    eval(options)
    return

def eval(options):
    (fileName, fileExtension) = os.path.splitext(options.train_file)
    result_mln = '%s.mln'%fileName
    result_file = '%s.result'%fileName
    log_file = '%s.log'%fileName
    cmd_train = '%s/bin/learnwts -d -i %s -o %s -t %s -ne %s -memLimit 10485760 -dNumIter 50 > %s'%(options.a_path
            , options.mln
            , result_mln
            , options.train_file
            , options.query
            , log_file)
    cmd_test = '%s/bin/infer -ms -i %s -r %s -e %s -q %s >> %s'%(options.a_path
            , result_mln
            , result_file
            , options.test_file
            , options.query
            , log_file)
    proc(cmd_train)
    proc(cmd_test)
    score(options.query, result_file, options.gs_file)
    return

def proc(cmd):
    print 'Running alchemy...'
    print 'CMD: %s'%cmd
    #start = time.clock()
    proc = subprocess.Popen(cmd, shell=True, stdout=subprocess.PIPE)
    return_code = proc.wait()
    #elapsed = (time.clock() - start)
    #print 'time:%s'%elapsed
    return

def score(query, result, gs_file):
    gs = pickle.load(open(gs_file, 'r'))
    test = {}
    t_test = 0
    f_test = 0
    tmp = {}
    with open(result, 'r') as results:
        for line in results:
            line.rstrip()
            m = re.search('^' + query + '\(\"(\w+)\",(.+)\) (.+)$', line)
            if m:
                value = m.group(1) 
                id = m.group(2)
                prob = float(m.group(3))
                test.setdefault(id, {})[value] = prob
                tmp[id] = 1

    e1 = RTEEvalMetrics()
    e2 = RTEEvalMetrics()

    print >> sys.stderr, 'total in gs: ', len(gs.keys())
    true_rate = 0
    false_rate = 0
    true_p = []
    false_p = []

    for (gs_id, gs) in gs.items():
        if gs_id in test:
            if test[gs_id]['true'] > test[gs_id]['false']:
                sys_o = 'true'
                true_rate += 1
                true_p.append((sys_o, gs))
            else:
                sys_o = 'false'
                false_rate += 1
                false_p.append((sys_o, gs))
            #print test[gs_id]['true'], ':', test[gs_id]['false']
            e1.compare(sys_o, gs)
    print >> sys.stderr, 'stats'
    print >> sys.stderr, 'total predicted: ', len(test.keys())
    print >> sys.stderr, 'total true: ', true_rate
    print >> sys.stderr, 'total false: ', false_rate
    acc = e1.get_accuracy()
    prec = e1.get_precision()
    rec = e1.get_recall()
    f1 = e1.get_f1()

    e1.print_matrix()

    print >> sys.stderr, 'ACC: %.2f'%acc
    print >> sys.stderr, 'PREC: %.2f'%prec
    print >> sys.stderr, 'REC: %.2f'%rec
    print >> sys.stderr, 'F1: %.2f'%f1


    #size_t = len(true_p)
    #size_f = len(false_p)
    #if size_t > size_f:
    #    final_size = size_f
    #else:
    #    final_size = size_t

    #random.shuffle(true_p)
    #random.shuffle(false_p)

    #true_pn = [true_p[i] for i in xrange(final_size)]
    #false_pn = [false_p[i] for i in xrange(final_size)]

    #final_pn = []
    #final_pn.extend(true_pn)
    #final_pn.extend(false_pn)

    #for (sys_o, gs) in final_pn:
    #    e2.compare(sys_o, gs)
    #print >> sys.stderr, ''
    #print >> sys.stderr, 'fixed size eval [%s]:'%final_size
    #acc = e2.get_accuracy()
    #prec = e2.get_precision()
    #rec = e2.get_recall()
    #f1 = e2.get_f1()

    #e2.print_matrix()

    #print >> sys.stderr, 'ACC: %.2f'%acc
    #print >> sys.stderr, 'PREC: %.2f'%prec
    #print >> sys.stderr, 'REC: %.2f'%rec
    #print >> sys.stderr, 'F1: %.2f'%f1

    return

if __name__ == '__main__':
    main()
