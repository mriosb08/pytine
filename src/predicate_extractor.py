#!/usr/bin/python
import os
import xml.etree.ElementTree as ET
from optparse import OptionParser
import pickle
from mln_models import *
import importlib

def main():
    parser = OptionParser(usage="usage: %prog [options]", version="%prog 1.0")
    parser.add_option("-x", "--xml-file", action="store", dest="xml_file"
            , help="xml file generated by TINE for extract predicates")
    parser.add_option("-d", "--db-file", action="store", dest="db_file"
            , help="db file for output predicates")
    parser.add_option("-t", "--type", action="store", default="train"
            , dest="type", help="type of input file [test|train]  default: train")
    parser.add_option("-q", "--query", action="store", default="Entailment"
            , dest="query", help="query for alchemy default: Entailment")
    parser.add_option("-m", "--model", action ="store", default="ModelA"
            , dest="model", help="model for create predicates default [ModelA] note: use corresponding mln file")
    parser.add_option("-p", "--pickle-file", action="store", dest="p_file"
            , help="pickle file with features used in a MLN-Model with a backoff strategy")
    #TODO add alchemy to run test and train phases

    (options, args) = parser.parse_args()
    if not options.xml_file and not options.db_file:
        parser.error("wrong number of options")
    
    points = load_xml(options.xml_file)
    #print points
    extract_predicates(points, options.db_file, options.type, options.query, options.model, options.p_file)
    return

def load_xml(xml_file):
    points = {}
    tree = ET.parse(xml_file)
    for pair in tree.findall('./pair'):
        id = pair.attrib['id']
        value = pair.attrib['entailment']
        task = pair.attrib['task']
        points.setdefault(id, {})
        points[id]['value'] = value
        points[id]['task'] = task
        for node in pair.getchildren():
            if node.tag == 'T':
                points[id]['T'] = node.text
            if node.tag == 'H':
                points[id]['H'] = node.text
            if node.tag == 'F':
                points[id]['F'] = float(node.text)
            if node.tag == 'A':
                points[id]['prec'] = float(node.attrib['precision'])
                points[id]['rec'] = float(node.attrib['recall'])
                points[id]['A'] = float(node.text)
            if node.tag == 'TINE':
                points[id]['tine'] = float(node.text)
            if node.tag == 'alignment':
                points[id]['alignment'] = float(node.attrib['score'])
                verbs = {}
                for vtov in node.getchildren():
                    if vtov.tag == 'v2v':
                        vid = vtov.attrib['id']
                        verbs.setdefault(vid, {})
                        args = {}
                        verbs[vid]['lex'] = float(vtov.attrib['lex'])
                        verbs[vid]['srl'] = float(vtov.attrib['srl'])
                        verbs[vid]['combo'] = float(vtov.attrib['combo'])
                        for v in vtov.getchildren(): 
                            if v.tag == 'T':
                                for targets in v.getchildren():
                                    if targets.tag == 'vt':
                                        vt = targets.text
                                    if targets.tag == 'vh':
                                        vh = targets.text
                                verbs[vid]['tokens'] = (vt, vh)
                            if v.tag == 'ARG':
                                arg_type = v.attrib['type']
                                args.setdefault(arg_type, {})
                                args[arg_type]['score'] = float(v.attrib['score'])
                                for features in v.getchildren():
                                    name = features.tag
                                    args[arg_type][name] = features.text
                                verbs[vid]['ARG'] = args
                    points[id]['verbs'] = verbs
    return points

def load_class(full_class_string):
    """
    dynamically load a class from a string
    the user can develop new models in  by extending the base class
    """
    class_data = full_class_string.split(".")
    module_path = ".".join(class_data[:-1])
    class_str = class_data[-1]
    module = importlib.import_module(module_path)
    # Finally, we retrieve the Class
    return getattr(module, class_str)


def extract_predicates(points, db_file, type, query, model_name, p_file):
    with open(db_file, 'w') as o:
        gs = {}
        subset = {}
        true_rate = 0
        false_rate = 0
        #model = getObj(model_name) deprecated
        loaded_class = load_class(model_name)
        model = loaded_class()

        z_t = 0
        z_f = 0

        if hasattr(model, 'backoff') or hasattr(model, 'baseline')  and p_file:
            model.set_pfile(p_file)

        for id, point in points.items():
            value = int(point['value'])
            task = point['task']
            if value == 1:
                value = 'true'
                true_rate += 1
            else:
                value = 'false'
                false_rate += 1
            gs[id] = value
            verb_predicates = []
            arg_predicates = []
            backoff_predicates = []
            baseline_predicates = []

            verb_predicates = model.verb_proc(id, point, '|||')
            arg_predicates = model.arg_proc(id, point, '|||')

            if verb_predicates and arg_predicates:
                for v_pred in verb_predicates:
                    print >>o, v_pred
                for a_pred in arg_predicates:
                    print >>o, a_pred
                subset[id] = 1
            elif hasattr(model, 'backoff') and p_file:
                    backoff_predicates = model.backoff(id)
                    for b_pred in backoff_predicates:
                        print >>o, b_pred
                    if value == 'true':
                        z_t += 1
                    else:
                        z_f += 1
            if hasattr(model, 'baseline') and p_file:
                baseline_predicates = model.baseline(id)
                for ba_pred in baseline_predicates:
                    print >>o, ba_pred

            if type == 'train' and (verb_predicates or arg_predicates or backoff_predicates or baseline_predicates):
                decision = '%s("%s", %s)'%(query, value, id)
                print >>o, decision
                print >>o, '//#%s'%id
        dump_data(gs, subset, db_file)
        print 'stats model(%s):'%model_name
        print 'total pairs: ', len(gs.keys())
        print 'total true: ', true_rate
        print '\ttrue pairs No aligned: ', z_t
        print '\ttrue pairs aligned: ', (true_rate - z_t)
        print 'total false: ', false_rate
        print '\tfalse pairs No aligned:', z_f
        print '\tfalse pairs aligned: ', (false_rate - z_f)
    return

def dump_data(gs, subset, name):
    (fileName, fileExtension) = os.path.splitext(name)
    pickle.dump(gs, open('%s.gs.pickle'%fileName, "wb" ))
    pickle.dump(subset, open('%s.subset.pickle'%fileName, "wb" ))

def getObj(class_name):
    object = globals()[class_name]
    return object()                    

if __name__ == '__main__':
    main()

