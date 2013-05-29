#!/usr/bin/python
import numpy as np
import sys
from metrics import SetMetrics
import pickle
import matplotlib.pyplot as plt
import matplotlib.mlab as mlab
from sklearn import svm
import pylab as pl
from sklearn.metrics import precision_score
from sklearn.metrics import recall_score
from sklearn.metrics import confusion_matrix
from sklearn.metrics import f1_score
#from sklearn.metrics import accuracy_score

def main(argv):
    (isec_t, value_t, x_train, y_train) = load_file(argv[0])
    (isec_h, value_h, x_test, y_test) = load_file(argv[1])
    (amin, amax, ptp, avg, mean, med, std, var, hist, bins, count) = stats(isec_t, value_t.keys())
    print '####TEXT(%s)###'%argv[0]
    print 'values: ', value_t
    print 'min: ', amin
    print 'max: ', amax
    print 'ptp: ', ptp
    print 'avg: ', avg
    print 'mean: ', mean
    print 'med: ', med
    print 'std: ', std
    print 'var: ', std
    print 'count: ', count
    print 'bins: ', bins

    (amin, amax, ptp, avg, mean, med, std, var, hist, bins, count) = stats(isec_h, value_h.keys())
    print '####HYPO(%s)###'%argv[1]
    print 'values: ', value_h
    print 'min: ', amin
    print 'max: ', amax
    print 'ptp: ', ptp
    print 'avg: ', avg
    print 'mean: ', mean
    print 'med: ', med
    print 'std: ', std
    print 'var: ', std
    print 'count: ', count
    print 'bins: ', bins

    #svc = svm.SVC(kernel='linear', C=C).fit(X, Y)
    clf = svm.SVC(kernel='linear')
    clf.fit(x_train, y_train)
    y_pred = clf.predict(x_test)
    #acc = accuracy_score(y_test, y_pred)
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



    return

def load_file(file):
    isec_t = []
    values = {}
    #C = 1.0 
    
    with open(file, 'r') as pf1:
            tmp_pairs = pickle.load(pf1)
            metric = SetMetrics()
            X = []
            Y = []
            for pair in tmp_pairs:
                id = pair.get_id()
                value = pair.get_value()
                lemmas_text = pair.get_feature_text('lemmas')
                lemmas_hypo = pair.get_feature_hypo('lemmas')
                metric.set_text(lemmas_text)
                metric.set_hypo(lemmas_hypo)
                isec = metric.get_isec()
                isec_t.append(isec)
                if isec in values:
                    values[isec] += 1
                else:
                    values[isec] = 1
                X.append([isec])
                if value == 'TRUE':
                    Y.append(1)
                else:
                    Y.append(0)

            #svc = svm.SVC(kernel='linear', C=C).fit(X, Y)
            #clf = svm.SVC(kernel='linear')
            #clf.fit(X, Y)
            # get the separating hyperplane
            #print 'Weights asigned to the features: ', clf.coef_
            #print 'Constants in decision function: ', clf.intercept_
            #print 'number of support vector for each class: ', clf.n_support_


    return (isec_t, values, X, Y)

def stats(isec, value):
    amin = np.amin(isec)
    amax = np.amax(isec)
    ptp = np.ptp(isec)
    avg = np.average(isec)
    mean = np.mean(isec)
    med = np.median(isec)
    std = np.std(isec)
    var = np.var(isec)
    count = np.bincount(isec)
    (hist, bins) = np.histogram(isec, len(count))
    plt.hist(isec, sorted(value))
    plt.title("Histogram")
    plt.xlabel("Value")
    plt.ylabel("Frequency")
    plt.show()
    return (amin, amax, ptp, avg, mean, med, std, var, hist, bins, count)

if __name__ == '__main__':
    if len(sys.argv) != 3:
        print 'usage:./overlap_stats <pickle-dev> <pickle-test>'
        sys.exit(1)
    else:
        main(sys.argv[1:])

