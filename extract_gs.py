import pickle
import sys

def main(argv):
    gs = {}
    with open(argv[0], 'r') as pf:
        pairs = pickle.load(pf)
        for pair in pairs:
            id = pair.get_id()
            value = pair.get_value()
            gs[id] = value
        pickle.dump(gs, open(argv[1], "wb" ))
    return

if __name__ == '__main__':
    if len(sys.argv) != 2:
        sys.exit(0)
    else:
        main(sys.argv[1:])
