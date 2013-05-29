#!/usr/bin/python
import os
import xml.etree.ElementTree as ET
from optparse import OptionParser
import pickle
from thb_models import *
def main():
    parser = OptionParser(usage="usage: %prog [options]", version="%prog 1.0")
    parser.add_option("-x", "--xml-file", action="store", dest="xml_file"
            , help="xml file generated by TINE for extract predicates")
    parser.add_option("-a", "--atom-file", action="store", dest="atom_file"
            , help="atoms file for output predicates")
    parser.add_option("-m", "--model", action ="store", default="ModelA"
            , dest="model", help="model for create predicates default [ModelA] note: use corresponding pml file")
    parser.add_option("-p", "--pickle-file", action="store", dest="p_file"
            , help="pickle file with features used in a MLN-Model with a backoff strategy")
    #TODO add alchemy to run test and train phases

    (options, args) = parser.parse_args()
    if not options.xml_file and not options.atom_file:
        parser.error("wrong number of options")
    
    points = load_xml(options.xml_file)
    #print points
    extract_predicates(points, options.atom_file, options.model, options.p_file)
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

def extract_predicates(points, a_file, model_name, p_file):
    with open(a_file, 'w') as o:
        gs = {}
        subset = {}
        true_rate = 0
        false_rate = 0
        model = getObj(model_name)
        z_t = 0
        z_f = 0
        query = 'entailment'

        if hasattr(model, 'backoff') or hasattr(model, 'baseline')  and p_file:
            model.set_pfile(p_file)

        for id, point in points.items():
            value = int(point['value'])
            task = point['task']
            if value == 1:
                value = 'TRUE'
                true_rate += 1
            else:
                value = 'FALSE'
                false_rate += 1
            gs[id] = value
            verb_predicates = []
            arg_predicates = []
            backoff_predicates = []
            baseline_predicates = []

            verb_predicates = model.verb_proc(id, point, '|||')
            arg_predicates = model.arg_proc(id, point, '|||')
            #print >>o, '//#%s'%id
            if verb_predicates and arg_predicates:
                print >>o, '>>'
                for v_pred in verb_predicates:
                    print >>o, v_pred
                for a_pred in arg_predicates:
                    print >>o, a_pred
                subset[id] = 1
                dec(o, query, value, id)
            elif hasattr(model, 'backoff') and p_file:
                print >>o, '>>'
                backoff_predicates = model.backoff(id)
                for b_pred in backoff_predicates:
                    print >>o, b_pred
                dec(o, query, value, id)
                if value == 'TRUE':
                    z_t += 1
                else:
                    z_f += 1
            if hasattr(model, 'baseline') and p_file:
                print >>o, '>>'
                baseline_predicates = model.baseline(id)
                for ba_pred in baseline_predicates:
                    print >>o, ba_pred
                dec(o, query, value, id)
            #print >>o, '//#%s'%id
            
        dump_data(gs, subset, a_file)
        print 'stats model(%s):'%model_name
        print 'total pairs: ', len(gs.keys())
        print 'total true: ', true_rate
        print '\ttrue pairs No aligned: ', z_t
        print '\ttrue pairs aligned: ', (true_rate - z_t)
        print 'total false: ', false_rate
        print '\tfalse pairs No aligned:', z_f
        print '\tfalse pairs aligned: ', (false_rate - z_f)
    return

def dec(f, query, value, id):
    decision = '>%s\n%s "%s"\n'%(query, id, value)
    print >>f, decision
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

