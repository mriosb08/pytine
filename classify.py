#!/usr/bin/python
from optparse import OptionParser
import pickle
from sklearn.neighbors import KNeighborsClassifier
from sklearn.svm import SVC
from sklearn.tree import DecisionTreeClassifier
from sklearn.ensemble import RandomForestClassifier
from sklearn.naive_bayes import GaussianNB
from sklearn.lda import LDA
from sklearn.qda import QDA
from sklearn.metrics import precision_score
from sklearn.metrics import recall_score
from sklearn.metrics import confusion_matrix
from sklearn.metrics import f1_score

names = ["Nearest Neighbors", "Linear SVM", "RBF SVM", "Decision Tree","Random Forest", "Naive Bayes", "LDA", "QDA"]

classifiers = {'Nearest Neighbors':KNeighborsClassifier(3),
        'Linear SVM':SVC(kernel="linear", C=0.025),
        'RBF SVM':SVC(gamma=2, C=1),
        'Decision Tree':DecisionTreeClassifier(max_depth=5),
        'Random Forest':RandomForestClassifier(max_depth=5, n_estimators=10, max_features=1),
        'Naive Bayes':GaussianNB(),
        'LDA':LDA(),
        'QDA':QDA()}



def main():
    parser = OptionParser(usage="usage: %prog [options]", version="%prog 1.0")
    parser.add_option("-t", "--test-pickle-file", action="store", dest="test_file",
            help="Pickle file with features from the test dataset")
    parser.add_option("-p", "--train-pickle-file", action="store", dest="train_file",
            help="Pickle file with features from the train dataset")
    parser.add_option("-c", "--classifier", action="store", dest="classifier",
            help="classifier used over the data names: %s"%''.join(names))

    (options, args) = parser.parse_args()
    if not options.test_file or not options.train_file or not options.classifier:
        parser.error("wrong number of options")

    test_data = pickle.load(open(options.test_file, 'rb' ))
    train_data = pickle.load(open(options.train_file, 'rb'))
    (X_test, y_test) = extractFeatures(test_data)
    (X_train, y_train) = extractFeatures(train_data)
    print options.classifier
    if options.classifier in classifiers:
        clf = classifiers[options.classifier]
        clf.fit(X_train, y_train)
        y_pred = clf.predict(X_test)
        #acc = accuracy_score(y_test, y_pred)
        prec = precision_score(y_test, y_pred)
        recall = recall_score(y_test, y_pred)
        f1 = f1_score(y_test, y_pred)
        matrix = confusion_matrix(y_test, y_pred)
        score = clf.score(X_test, y_test)
        print 'SCORE: ', score
        #print 'ACC: ', acc
        print 'PREC: ', prec
        print 'REC: ', recall
        print 'F1: ', f1
        print 'MATRIX: \n', matrix

    return

def extractFeatures(data = {}):
    X = []
    y = []
    for id, features in data.items():
        temp = []
        for name, feature in features.items():
            if name == 'value':
                if feature == 'TRUE':
                    y.append(1)
                else:
                    y.append(0)
            else:
                temp.append(feature)
        X.append(temp)
    return (X, y)

if __name__ == '__main__':
    main()
