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
from collections import defaultdict, OrderedDict
from itertools import chain

def partition(lst, n):
    return [ lst[i::n] for i in xrange(n) ]

def main():
    parser = OptionParser(usage="usage: %prog [options]", version="%prog 1.0")
    parser.add_option("-i", "--train-file", action="store", dest="train_file"
            , help="File with train db file")
    parser.add_option("-g", "--gs-file", action="store", dest="gs_file"
            , help="Pickle file with id-gs annotation")
    parser.add_option("-t", "--tmp", type=str 
            , help="temp dir (defaults to 'tmp'", default='tmp')
    parser.add_option("-k", "--k-folds", type = int, action="store", dest="k"
            , help="K number of folds default [10] note: not less than 2 folds"
            , default=10)
    parser.add_option("-a", "--alchemy-path", action="store", dest="a_path"
            , help="Path to alchemy default:/media/raid-vapnik/mrios/workspace/alchemy/alchemy"
            , default="/media/raid-vapnik/mrios/workspace/alchemy/alchemy")
    parser.add_option("-m", "--mln", action="store", dest="mln"
            , help="File with mln rules")
    parser.add_option("-q", "--query", action="store", dest="query"
            , default="Entailment", help="Query for the MLN default [Entailment]")

    (options, args) = parser.parse_args()
    if not options.train_file or not options.gs_file or not options.mln:
        parser.print_help()
        parser.error("wrong number of options")
    try:
        os.mkdir(options.tmp)
    except:
        pass
   
    preds = readDB(options.train_file, options.query)
    items = sorted(preds.keys())
    items = preds.keys()
    num_items = len(items)
    size_fold = int(num_items / options.k) 
    print >> sys.stderr, 'size_fold', size_fold
    random.shuffle(items)
    folds = defaultdict(list)
    f = 0
    fn = 0
    folds = partition(items, options.k)
    #for item in preds: # items:
    #    if f >= size_fold:
    #        fn += 1
    #        f = 0
    #    folds[fn].append(item)
    #    f += 1
    avg_acc = 0
    avg_prec = 0
    avg_rec = 0 
    avg_f1 = 0
    print >>sys.stderr, 'Total of items: ', num_items
    for fid, pids in enumerate(folds):
        test = pids
        train = []
        for other_fids, other_pids in enumerate(folds):
            if fid != other_fids:
                train.extend(other_pids)
        #for id_j in set(folds.iterkeys()).difference([id_i]):
        #    train.extend(folds[id_j])
        #train and test mln
        if options.k == 1:
            train = test
        (acc, prec, rec, f1)= eval(fid, train, test, preds, options)
        avg_acc += acc
        avg_prec += prec
        avg_rec += rec
        avg_f1 += f1
    avg_acc = float(avg_acc) / options.k
    avg_prec = float(avg_prec) / options.k
    avg_rec = float(avg_rec) / options.k
    avg_f1 = float(avg_f1) / options.k
    print >>sys.stderr, '######################################'
    print >>sys.stderr, 'AVG ACC:%.2f'%(avg_acc)
    print >>sys.stderr, 'AVG PREC:%.2f'%(avg_prec)
    print >>sys.stderr, 'AVG REC:%.2f'%(avg_rec)
    print >>sys.stderr, 'AVG F1:%.2f'%(avg_f1)
    return

def readDB(file_db, query):
    preds = defaultdict(list)
    tmp_line = []
    with open(file_db, 'r') as f:
        for line in (s.strip() for s in f):
            if line.startswith('//'):
                (comm, id) = line.split('#')
                preds[id] = tmp_line
                tmp_line = []
            else:
                tmp_line.append(line)
            #print >> fff, line
            #m = re.search('^(\w+)\((.+)\)$', line)
            #TODO read different types of models!!!!
            #if m:
            #    p, args = m.group(1), m.group(2)
            #    if p.startswith(query):
            #        (value, pid) = [x.strip() for x in args.split(',')]
                    #print >> fff, 'if)', pid
            #    else:
            #        (pid, o_arg) = [x.strip() for x in args.split(',', 1)]
                    #print >> fff, 'else)', pid
            #    pid = int(pid)
            #    entries = preds.get(pid, None)
            #    if entries is None:
            #        entries = []
            #        preds[pid] = entries
            #    entries.append(line)
                
    f.close()
    return preds

def eval(fold, train, test, preds, options):
    print >> sys.stderr, '######FOLD(%s)#######'%fold
   
    
    (fileName, fileExtension) = os.path.splitext(os.path.basename(options.train_file))
    result_mln = '%s/%s.mln.%d.mln' % (options.tmp, fileName, fold)
    result_file = '%s/%s.%d.pred' % (options.tmp, fileName, fold)
    log_file = '%s/%s.log.%d' % (options.tmp, fileName, fold)
    train_file = '%s/%s.train.%d.db' % (options.tmp, fileName, fold)
    test_file = '%s/%s.test.%d.db' % (options.tmp, fileName, fold)
    sh_file = '%s/%s.cmd.%d' % (options.tmp, fileName, fold)
    #create train and test file
    print >>sys.stderr, 'Total items train: ', len(train)
    print >>sys.stderr, 'Total items test: ', len(test)
    toFile(train_file, train, preds, 'train', options.query)
    toFile(test_file, test, preds, 'test', options.query)

    cmd_train = '%s/bin/learnwts -d -i %s -o %s -t %s -ne %s -memLimit 10485760 > %s'%(options.a_path
            , options.mln
            , result_mln
            , train_file
            , options.query
            , log_file)
    cmd_test = '%s/bin/infer -ms -i %s -r %s -e %s -q %s >> %s'%(options.a_path
            , result_mln
            , result_file
            , test_file
            , options.query
            , log_file)
    with open(sh_file, 'w') as sh_desc:
        proc(cmd_train, sh_desc)
        proc(cmd_test, sh_desc)
    (acc, prec, rec, f1) = score(options.query, result_file, options.gs_file)

    return (acc, prec, rec, f1)

def toFile(name, ids, preds, type, query):
    i = 0
    with open(name, 'w') as f:
        for ni, id in enumerate(ids):
            if id in preds:
                for pred in preds[id]:
                    if type == 'test':
                        if not pred.startswith(query):
                            print >> f,'%s'%pred
                    else:
                        print >> f,'%s'%pred
    f.closed
    return

def proc(cmd, log):
    print >> sys.stderr, 'Running alchemy...'
    print >> sys.stderr, 'CMD: %s'%cmd
    print >> log, cmd
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
    with open(result, 'r') as results:
        for line in results:
            line.rstrip()
            m = re.search('^' + query + '\(\"(\w+)\",(.+)\) (.+)$', line)
            if m:
                value = m.group(1) 
                id = m.group(2)
                prob = float(m.group(3))
                test.setdefault(id, {})[value] = prob
    e1 = RTEEvalMetrics()

    print >> sys.stderr, 'total items in gs: ', len(gs.keys())
    true_rate = 0
    false_rate = 0
    true_p = []
    false_p = []

    for (gs_id, gs) in gs.items():
        if gs_id in test:
            if 'true' in test[gs_id] and 'false' in test[gs_id]:
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

    print >> sys.stderr, 'ACC: %s'%acc
    print >> sys.stderr, 'PREC: %s'%prec
    print >> sys.stderr, 'REC: %s'%rec
    print >> sys.stderr, 'F1: %s'%f1
    return (acc, prec, rec, f1)

if __name__ == '__main__':
    main()
