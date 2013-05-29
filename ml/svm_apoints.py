#!/usr/bin/python
from sklearn import svm
import pylab as pl
from sklearn.metrics import precision_score
from sklearn.metrics import recall_score
from sklearn.metrics import confusion_matrix
from sklearn.metrics import f1_score
import pickle
import sys
from metrics import SetMetrics

def main(argv):

    subset_train = loadSub(argv[0])
    (x_train, y_train) = loadData(argv[1], subset_train)
    subset_test = loadSub(argv[2])
    (x_test, y_test) = loadData(argv[3], subset_test)
    clf = svm.SVC(kernel='linear')
    #clf = svm.SVC(kernel='rbf', gamma=0.7)
    #clf = svm.SVC(kernel='poly', degree=3)
    clf.fit(x_train, y_train)
    y_pred = clf.predict(x_test)
    prec = precision_score(y_test, y_pred)
    recall = recall_score(y_test, y_pred)
    f1 = f1_score(y_test, y_pred)
    matrix = confusion_matrix(y_test, y_pred)
    score = clf.score(x_test, y_test)
    print 'Linear SVM'
    print 'SCORE: ', score
    # print 'ACC: ', acc
    print 'PREC: ', prec
    print 'REC: ', recall
    print 'F1: ', f1
    print 'MATRIX: \n', matrix
    print 'Istances: ', len(y_pred)
    return

def loadSub(file_sub):
    with open(file_sub, 'r') as sub:
        subset = pickle.load(sub)
    return subset

def loadData(file_data, subset):
    with open(file_data, 'r') as pf1:
            tmp_pairs = pickle.load(pf1)
            metric = SetMetrics()
            X = []
            Y = []
            for pair in tmp_pairs:
                id = pair.get_id()
                if id in subset:
                    value = pair.get_value()
                    lemmas_text = pair.get_feature_text('lemmas')
                    lemmas_hypo = pair.get_feature_hypo('lemmas')
                    metric.set_text(lemmas_text)
                    metric.set_hypo(lemmas_hypo)
                    isec = metric.get_isec()
                
                    X.append([isec])
                    if value == 'TRUE':
                        Y.append(1)
                    else:
                        Y.append(0)
    return (X, Y)

if __name__ == '__main__':
    if len(sys.argv) != 5:
        print 'usage:./svm_apoints.py <subset-TRAIN-pickle> <features-TRAIN-pickle> <subset-TEST-pickle> <features-TEST-pickle>'
        sys.exit(0)
    else:
        main(sys.argv[1:])
