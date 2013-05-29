import sys

class RTEEvalMetrics:
    def __init__(self):
        self.acc = 0.0
        self.prec = 0.0
        self.f1 = 0.0
        self.rec = 0.0
        self.matrix = [[0 for x in range(2)] for x in range(2)]
        return

    def compare(self, sys, gs):
        if sys == 'true' and gs == 'true':
            self.matrix[0][0] += 1#TP
        elif sys == 'true' and gs == 'false':
            self.matrix[0][1] += 1#FP
        elif sys == 'false' and gs == 'true':
            self.matrix[1][0] += 1#FN
        elif sys == 'false' and gs == 'false':
            self.matrix[1][1] += 1#TN
        return

    def get_accuracy(self):
        if (self.matrix[0][0] + self.matrix[0][1] + self.matrix[1][0] + self.matrix[1][1]) == 0:
            return 0
        else:
            self.acc = float(self.matrix[0][0] + self.matrix[0][1]) / (self.matrix[0][0] + self.matrix[0][1] + self.matrix[1][0] + self.matrix[1][1])
            return self.acc

    def get_precision(self):
        if self.matrix[0][0] + self.matrix[0][1] == 0:
            return 0
        else:
            self.prec = float(self.matrix[0][0]) / (self.matrix[0][0] + self.matrix[0][1]) #tp/tp+fp
            return self.prec

    def get_recall(self):
        if self.matrix[0][0] + self.matrix[1][0] == 0:
            return 0
        else:
            self.rec = float(self.matrix[0][0]) / (self.matrix[0][0] + self.matrix[1][0]) #tp/tp+fn
            return self.rec

    def get_f1(self):
        if self.prec + self.rec == 0:
            return 0
        else:
            self.f1 = 2 * ((self.prec * self.rec) / (self.prec + self.rec))
            return self.f1

    def print_matrix(self):
        print >> sys.stderr, '###########################################\n'
        print >> sys.stderr, '#####\tTRUE\t\tFALSE\n'
        print >> sys.stderr, '#TRUE\t%s\t\t%s\n'%(self.matrix[0][0], self.matrix[0][1])
        print >> sys.stderr, '#FALSE\t%s\t\t%s\n'%(self.matrix[1][0], self.matrix[1][1])
        print >> sys.stderr, '###########################################\n'
        return

    def get_matrix(self):
        return self.matrix

