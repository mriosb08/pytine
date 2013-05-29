import re
import pickle
from metrics import VerbMetrics, SetMetrics
from rteTools import WNTools, VerbTools, Lin, RTETools, NounTools
class MLNModel(object):
    def __init__(self, v_predicates = [], a_predicates = []):
        self.v_predicates = v_predicates
        self.a_predicates = a_predicates
        return
    def verb_proc(self):
        self.v_predicates = []
        return
    def arg_proc(self):
        self.a_predicates = []
        return

    def args_syn_wn(self, lemmas_t, lemmas_h, score, id, type):
        result = 0
        wn = WNTools()
        tool = RTETools()
        
        tool.set_tokens(lemmas_t.split())
        tool.quit_punct()
        lemmas_t = tool.quit_sw()
        
        tool.set_tokens(lemmas_h.split())
        tool.quit_punct()
        lemmas_h = tool.quit_sw()

        (diff_ht, diff_th) = self.diff(lemmas_t, lemmas_h)
        expand_diff_ht = wn.expand_bow_syns(list(diff_ht))
        expand_diff_th = wn.expand_bow_syns(list(diff_th))
        
        if len(expand_diff_ht) != 0 and len(expand_diff_th) !=0:
            sim = SetMetrics(expand_diff_ht, expand_diff_th)
            if sim.cosine() > 0:
                result = 1
        else:
            result = 1

        predicate = '>arg_relsyn\n%s %s %s'%(id, type, result)

        return predicate

    def args_hyp_wn(self, lemmas_t, pos_t, lemmas_h, pos_h, score, id, type):
        result = 0
        wn = WNTools()
        tool = RTETools()
        tool.set_tokens(lemmas_t)
        tool.quit_punct()
        lemmas_t = tool.quit_sw()
        tool.set_tokens(lemmas_h)
        tool.quit_punct()
        lemmas_h = tool.quit_sw()
        (diff_ht, diff_th) = self.diff(lemmas_t, lemmas_h)
        #TODO
        predicate = '>hyp_relsyn\n%s %s'%(id, type, result)
        return predicate

    def args_direct(self, lemmas_t, pos_t, lemmas_h, pos_h, score, id, type):
        result = 0
        n = NounTools()
        tool = RTETools()
        tool.set_tokens(lemmas_t)
        tool.quit_punct()
        lemmas_t = tool.quit_sw()
        tool.set_tokens(lemmas_h)
        tool.quit_punct()
        lemmas_h = tool.quit_sw()
        (diff_ht, diff_th) = self.diff(lemmas_t, lemmas_h)
        sim_th = self.sim(lemmas_t, lemmas_h)
        return result

    def sim_dif(self, lemmas_t, lemmas_h):
        set_t = set(lemmas_t)
        set_h = set(lemmas_h)
        sim_dif = set_t ^ set_h #symetric difference
        return list(sim_dif)

    def sim(self, lemmas_t, lemmas_h):
        set_t = set(lemmas_t)
        set_h = set(lemmas_h)
        sim_th = set_t & set_h #intersection
        return list(sim_th)

    def diff(self, lemmas_t, lemmas_h):
        set_t = set(lemmas_t)
        set_h = set(lemmas_h)
        diff_ht = set_h - set_t #difference
        
        diff_th = set_t - set_h
        return (list(diff_ht), list(diff_th))

    def clean_str(self, string):
        string = re.sub('"', "$punct$", string)
        string = re.sub("'", "$punct$", string)
        #string = re.sub(',', "$punct$", string)
        #string = re.sub('-', "$punct$", string)
        #string = re.sub('_', "$punct$", string)
        #string = re.sub('@', "$punct$", string)
        #string = re.sub('\.', "$punct$", string)
        string = re.sub('\s+', " ", string)
        #string = re.sub('\(', "$punct$", string)
        #string = re.sub('\)', "$punct$", string)
        string = re.sub('/', "$punct$", string)
        string = re.sub(r'\\', "$punct$", string)
        string = re.sub('\*', "$punct$", string)
        return string

class ModelA(MLNModel):
    def __init__(self, v_predicates = [], a_predicates = []):
        super(ModelA, self).__init__(v_predicates, a_predicates)
        return

    def verb_proc(self, id, point, sep):
        self.v_predicates = []
        if 'verbs' in point:
            verbs = point['verbs']
            for i, verb in verbs.iteritems():
                lex_score = verb['lex']
                srl_score = verb['srl']
                combo_score = verb['combo']
                (vt, vh) = verb['tokens']
                #TODO VN isec, expand VO
                vt_tool = VerbTools(vt)
                vh_tool = VerbTools(vh)
                vt_classes = vt_tool.vn_classes()
                vh_classes = vh_tool.vn_classes()
                vt_classes.extend(vh_classes)
                set_classes = set(vt_classes)
                vt_vh_rel = vt_tool.verb_relations(vh)
                verb_sim = VerbMetrics(text_v=vt, hypo_v=vh)
                vn = verb_sim.vn_isec()
                d = verb_sim.direct()
                vo = verb_sim.vo()
                token_verb = '>token_verb\n%s %s "%s%s%s"'%(id, i, self.clean_str(vt), sep, self.clean_str(vh))
                sim_vn = '>sim_vn\n%s %s %s'%(id, i, vn)
                sim_vo = '>sim_vo\n%s %s %s'%(id, i, vo)
                sim_d = '>sim_d\n%s %s %s'%(id, i, d)
                str_classes = sep.join(set_classes)
                bow_vn = '>bow_vn\n%s %s "%s"'%(id, i, self.clean_str(str_classes))
                if srl_score > lex_score:
                    st = 1
                else:
                    st = 0
                strong_context = '>strong_con\n%s %s %s'%(id, i, st)
            
                #if str_classes != "": 
                self.v_predicates.append(bow_vn)
                self.v_predicates.append(strong_context)
                self.v_predicates.append(sim_vn)
                self.v_predicates.append(sim_vo)
                self.v_predicates.append(sim_d)
                self.v_predicates.append(token_verb)
            
        return self.v_predicates

    def arg_proc(self, id, point, sep):
        self.a_predicates = []
        if 'verbs' in point:
            verbs = point['verbs']
            for i, verb in verbs.iteritems():
                (vt, vh) = verb['tokens']
                if 'ARG' in verb:
                    args = verb['ARG']
                    for type,arg in args.items():
                        w_t = arg['wordform-t']
                        w_h = arg['wordform-h']
                        l_t = arg['lemma-t']
                        l_h = arg['lemma-h']
                        p_t = arg['pos-t']
                        p_h = arg['pos-h']
                        c_t = arg['chunk-t']
                        c_h = arg['chunk-h']
                        n_t = arg['ne-t']
                        n_h = arg['ne-h']
                        score = arg['score']

                        
                        token_arg = '>token_arg\n%s %s "%s%s%s"'%(id, type, self.clean_str(w_t), sep, self.clean_str(w_h))
                        lemma_arg = '>lemma_arg\n%s %s "%s%s%s"'%(id, type, self.clean_str(l_t), sep, self.clean_str(l_h))
                        pos_arg = '>pos_arg\n%s %s "%s%s%s"'%(id, type, self.clean_str(p_t), sep, self.clean_str(p_h))
                        #expand content words Lin
                        sw_tool = RTETools()
                        sw_tool.set_tokens(l_t.split())
                        sw_tool.quit_sw()
                        l_tsw = sw_tool.quit_punct()
                        sw_tool.set_tokens(l_h.split())
                        sw_tool.quit_sw()
                        l_hsw = sw_tool.quit_punct()

                        content_arg = '>cont_arg\n%s %s "%s%s%s"'%(id, type, self.clean_str(' '.join(l_tsw)), 
                                sep, self.clean_str(' '.join(l_hsw)))

                        sim_diff = self.sim_dif(l_tsw, l_hsw)
                        diff_arg = '>diff_arg\n%s %s "%s"'%(id, type, self.clean_str(' '.join(sim_diff)))

                        if score >= 0.4:
                            score_arg = '>sim_arg\n%s %s 1'%(id, type)
                        else: #TODO find threshold from data statistics mf
                            score_arg = '>sim_arg\n%s %s 0'%(id, type)


                        lin = Lin()
                        bow_t = lin.expand_bow(l_tsw)
                        bow_h = lin.expand_bow(l_hsw)
                        lin_arg = '>lin_arg\n%s %s "%s%s%s"'%(id, type, self.clean_str(' '.join(bow_t)), 
                                sep, self.clean_str(' '.join(bow_h)))

                        wn = WNTools()
                        wns_t = zip(l_t.split(), p_t.split())
                        wns_h = zip(l_h.split(), p_h.split())
                        bow_wnt = wn.expand_bow_tree(wns_t)
                        bow_wnh = wn.expand_bow_tree(wns_h)
                        wn_arg = '>wn_arg\n%s %s "%s%s%s"'%(id, type, self.clean_str(' '.join(bow_wnt)), 
                                sep, self.clean_str(' '.join(bow_wnh)))

                        rel_syn_args = self.args_syn_wn(l_t, l_h, score, id, type)                


                        self.a_predicates.append(token_arg)
                        self.a_predicates.append(score_arg)
                        self.a_predicates.append(lemma_arg)
                        self.a_predicates.append(rel_syn_args)
                        self.a_predicates.append(content_arg)
                        self.a_predicates.append(diff_arg)
                        self.a_predicates.append(pos_arg)
                        self.a_predicates.append(lin_arg)
                        self.a_predicates.append(wn_arg)
        return self.a_predicates

class ModelB(MLNModel):
    def __init__(self, v_predicates = [], a_predicates = []):
        super(ModelB, self).__init__(v_predicates, a_predicates)
        return

    def verb_proc(self, id, point, sep):
        self.v_predicates = []
        if 'verbs' in point:
            verbs = point['verbs']
            for i, verb in verbs.iteritems():
                lex_score = verb['lex']
                srl_score = verb['srl']
                combo_score = verb['combo']
                (vt, vh) = verb['tokens']
                #TODO VN isec, expand VO
                vt_tool = VerbTools(vt)
                i = '%s%s%s'%(self.clean_str(vt), sep, self.clean_str(vh))
                vh_tool = VerbTools(vh)
                vt_classes = vt_tool.vn_classes()
                vh_classes = vh_tool.vn_classes()
                vt_classes.extend(vh_classes)
                set_classes = set(vt_classes)
                vt_vh_rel = vt_tool.verb_relations(vh)
                verb_sim = VerbMetrics(text_v=vt, hypo_v=vh)
                vn = verb_sim.vn_isec()
                d = verb_sim.direct()
                vo = verb_sim.vo()
                #token_verb = 'TokenVerb(%s, "%s%s%s")'%(i, self.clean_str(vt), sep, self.clean_str(vh))
                sim_vn = '>sim_vn\n"%s" %s'%(i, vn)
                sim_vo = '>sim_vo\n"%s" %s'%(i, vo)
                sim_d = '>sim_d\n"%s" %s'%(i, d)
                str_classes = sep.join(set_classes)
                bow_vn = '>bow_vn\n"%s" "%s"'%(i, self.clean_str(str_classes))
                if srl_score > lex_score:
                    st = 1
                else:
                    st = 0
                strong_context = '>strong_con\n"%s" %s'%(i, st)

                verb_id = '>verb\n"%s" %s'%(i, id)
            
                #if str_classes != "": 
                self.v_predicates.append(bow_vn)
                self.v_predicates.append(strong_context)
                self.v_predicates.append(sim_vn)
                self.v_predicates.append(sim_vo)
                self.v_predicates.append(sim_d)
                #self.v_predicates.append(token_verb)
                self.v_predicates.append(verb_id)
            
        return self.v_predicates

    def arg_proc(self, id, point, sep):
        self.a_predicates = []
        n = 3 #levels in wn tree
        if 'verbs' in point:
            verbs = point['verbs']
            for i, verb in verbs.iteritems():
                i = '%s.%s'%(id, i)
                (vt, vh) = verb['tokens']
                if 'ARG' in verb:
                    args = verb['ARG']
                    for type,arg in args.items():
                        w_t = arg['wordform-t'].split()
                        w_h = arg['wordform-h'].split()
                        l_t = arg['lemma-t'].split()
                        l_h = arg['lemma-h'].split()
                        p_t = arg['pos-t'].split()
                        p_h = arg['pos-h'].split()
                        c_t = arg['chunk-t'].split()
                        c_h = arg['chunk-h'].split()
                        n_t = arg['ne-t'].split()
                        n_h = arg['ne-h'].split()
                        score = arg['score']
                        w_t.extend(w_h)
                        l_t.extend(l_h)
                        p_t.extend(p_h)
                        #TODO quit stop words

                        for j, word in enumerate(w_t):
                            word_arg = '>token_word\n"%s" %s "%s"'%(type, j,  self.clean_str(word))
                            lemma_arg = '>token_lemma\n"%s" %s "%s"'%(type, j, self.clean_str(l_t[j]))
                            pos_arg = '>token_pos\n"%s" %s "%s"'%(type, j, self.clean_str(p_t[j]))
                            lin = Lin()
                            sim_words = lin.expand_w(word)
                            wn = WNTools()
                            hyps = wn.get_mfs_hypernyms((l_t[j], p_t[j]))

                            self.a_predicates.append(word_arg)
                            self.a_predicates.append(lemma_arg)
                            self.a_predicates.append(pos_arg)
                            
                            for j, sim_word in enumerate(sim_words):
                                lin_arg = '>token_lin\n"%s" %s "%s"'%(type, j, self.clean_str(sim_word))
                                self.a_predicates.append(lin_arg)


                            for key, tree in hyps:
                                j = 0
                                for category in tree[:n]:
                                    hyp_arg = '>token_wn\n"%s" %s "%s"'%(type, j, self.clean_str(category))
                                    j += 1
                                    self.a_predicates.append(hyp_arg)

                        arg_id = '>arg\n"%s" "%s%s%s" %s'%(type, self.clean_str(vt), sep, self.clean_str(vh), id)
                        self.a_predicates.append(arg_id)
        return self.a_predicates


class ModelC(ModelB):
    def __init__(self,  v_predicates = [], a_predicates = [], backoff_predicates = []):
        super(ModelC, self).__init__(v_predicates, a_predicates)
        self.backoff_predicates = backoff_predicates
        self.pairs = {}
        return

    def set_pfile(self, p_file):
        with open(p_file, 'r') as pf:
            tmp_pairs = pickle.load(pf)
            for pair in tmp_pairs:
                id = pair.get_id()
                self.pairs[id] = pair #to hash
    
    def backoff(self, id_bo):
        self.backoff_predicates = []
        #TODO syntax and word based predicates
        if id_bo in self.pairs:            
            value = self.pairs[id_bo].get_value()
            #lemmas_text = self.pairs[id_bo].get_feature_text('lemmas')
            #lemmas_hypo = self.pairs[id_bo].get_feature_hypo('lemmas')
            #frames_text = pair.get_feature_text('frames')
            #frames_hypo = pair.get_feature_hypo('frames')
            #ne_text = pair.get_feature_text('ne')
            #ne_hypo = pair.get_feature_hypo('ne')
            pos_text = self.pairs[id_bo].get_feature_text('pos')
            pos_hypo = self.pairs[id_bo].get_feature_hypo('pos')
            #chunk_text = pair.get_feature_text('chunks')
            #chunk_hypo = pair.get_feature_hypo('chunks')
            #lemmas_text.extend(lemmas_hypo)
            pos_text.extend(pos_hypo)
            for word, pos in pos_text:
                lemma_predicate = '>token_back_lemma\n%s "%s"'%(id_bo, self.clean_str(word))
                pos_predicate = '>token_back_pos\n%s "%s"'%(id_bo, self.clean_str(pos))
                self.backoff_predicates.append(lemma_predicate)
                self.backoff_predicates.append(pos_predicate)
        return self.backoff_predicates

class ModelBASE(ModelB):
    def __init__(self,  v_predicates = [], a_predicates = [], baseline_predicates = []):
        super(ModelBASE, self).__init__(v_predicates, a_predicates)
        self.baseline_predicates = baseline_predicates
        self.pairs = {}
        return

    def set_pfile(self, p_file):
        with open(p_file, 'r') as pf:
            tmp_pairs = pickle.load(pf)
            for pair in tmp_pairs:
                id = pair.get_id()
                self.pairs[id] = pair #to hash

    def verb_proc(self, id, point, sep):
        self.v_predicates = []
        return self.v_predicates

    def arg_proc(self, id, point, sep):
        self.a_predicates = []
        return self.a_predicates

    def baseline(self, id_bo):
        self.baseline_predicates = []
        #TODO syntax and word based predicates
        if id_bo in self.pairs:            
            value = self.pairs[id_bo].get_value()
            lemmas_text = self.pairs[id_bo].get_feature_text('lemmas')
            lemmas_hypo = self.pairs[id_bo].get_feature_hypo('lemmas')
            metric = SetMetrics(text = lemmas_text, hypo = lemmas_hypo)
            isec = metric.get_isec()
            bo = '>overlap\n%s %s'%(id_bo, isec)
            self.baseline_predicates.append(bo)
        return self.baseline_predicates

class ModelBPLUS(ModelB):
    def __init__(self,  v_predicates = [], a_predicates = [], backoff_predicates = []):
        super(ModelBPLUS, self).__init__(v_predicates, a_predicates)
        self.backoff_predicates = backoff_predicates
        self.pairs = {}
        return

    def set_pfile(self, p_file):
        with open(p_file, 'r') as pf:
            tmp_pairs = pickle.load(pf)
            for pair in tmp_pairs:
                id = pair.get_id()
                self.pairs[id] = pair #to hash

    def backoff(self, id_bo):
        self.backoff_predicates = []
        #TODO syntax and word based predicates
        #TODO backoff with cosine metric instead of intersection
        if id_bo in self.pairs:            
            value = self.pairs[id_bo].get_value()
            lemmas_text = self.pairs[id_bo].get_feature_text('lemmas')
            lemmas_hypo = self.pairs[id_bo].get_feature_hypo('lemmas')
            metric = SetMetrics(text = lemmas_text, hypo = lemmas_hypo)
            isec = metric.get_isec()
            bo = '>overlap\n%s %s'%(id_bo, isec)
            self.backoff_predicates.append(bo)
        return self.backoff_predicates


class ModelFULL(ModelB):
    
    def __init__(self,  v_predicates = [], a_predicates = [], baseline_predicates = []):
        super(ModelFULL, self).__init__(v_predicates, a_predicates)
        self.baseline_predicates = baseline_predicates
        self.pairs = {}
        return

    def set_pfile(self, p_file):
        with open(p_file, 'r') as pf:
            tmp_pairs = pickle.load(pf)
            for pair in tmp_pairs:
                id = pair.get_id()
                self.pairs[id] = pair #to hash

    def baseline(self, id_bo):
        self.baseline_predicates = []
        #TODO syntax and word based predicates
        if id_bo in self.pairs:            
            value = self.pairs[id_bo].get_value()
            lemmas_text = self.pairs[id_bo].get_feature_text('lemmas')
            lemmas_hypo = self.pairs[id_bo].get_feature_hypo('lemmas')
            metric = SetMetrics(text = lemmas_text, hypo = lemmas_hypo)
            isec = metric.get_isec()
            bo = '>overlap\n%s %s'%(id_bo, isec)
            self.baseline_predicates.append(bo)
        return self.baseline_predicates

class ModelFULLW(ModelB):
    
    def __init__(self,  v_predicates = [], a_predicates = [], baseline_predicates = []):
        super(ModelFULLW, self).__init__(v_predicates, a_predicates)
        self.baseline_predicates = baseline_predicates
        self.pairs = {}
        return

    def set_pfile(self, p_file):
        with open(p_file, 'r') as pf:
            tmp_pairs = pickle.load(pf)
            for pair in tmp_pairs:
                id = pair.get_id()
                self.pairs[id] = pair #to hash

    def baseline(self, id_bo):
        self.baseline_predicates = []
        #TODO syntax and word based predicates
        if id_bo in self.pairs:
            value = self.pairs[id_bo].get_value()
            pos_text = self.pairs[id_bo].get_feature_text('pos')
            pos_hypo = self.pairs[id_bo].get_feature_hypo('pos')
            pos_text.extend(pos_hypo)
            for word, pos in pos_text:
                lemma_predicate = '>token_back_lemma\n%s "%s"'%(id_bo, self.clean_str(word))
                pos_predicate = '>toke_back_pos\n%s "%s"'%(id_bo, self.clean_str(pos))
                self.baseline_predicates.append(lemma_predicate)
                self.baseline_predicates.append(pos_predicate)
            
            lemmas_text = self.pairs[id_bo].get_feature_text('lemmas')
            lemmas_hypo = self.pairs[id_bo].get_feature_hypo('lemmas')
            metric = SetMetrics(text = lemmas_text, hypo = lemmas_hypo)
            isec = metric.get_isec()
            bo = '>overlap\n%s %s'%(id_bo, isec)
            self.baseline_predicates.append(bo)

        return self.baseline_predicates
