from metrics import SetMetrics, VerbMetrics, VectorMetrics
from rteTools import SRLTools, Lin, WNTools
import sys

class TineVN:
    def __init__(self, frames_text = {}, tokens_text = [],  frames_hypo = {}, tokens_hypo = [], sim_type = 'Lin', verbose = 1):
        self.srl_t = SRLTools()
        self.srl_h = SRLTools()
        self.verb_net = VerbMetrics()
        self.arg_sim = SetMetrics()
        self.lin = Lin()
        self.wn = WNTools()
        self.frames_hypo = frames_text
        self.frames_text = frames_hypo
        self.tokens_hypo = tokens_hypo
        self.tokens_text = tokens_text
        self.args_text = {}
        self.args_hypo = {}
        self.verbs_text = []
        self.verbs_hypo = []
        self.tine_score = 0
        self.verb_score = 0
        self.arg_score = 0
        self.sim_type = sim_type
        self.verbose = verbose
        #self.pos_text = pos_text
        #self.pos_hypo = pos_hypo
        return

    def get_tine_score(self, frames_text = {}, tokens_text = [], frames_hypo = {}, tokens_hypo = []):
        if frames_text:
            self.frames_text = frames_text
        if frames_hypo:
            self.frames_hypo = frames_hypo
        if tokens_text:
            self.tokens_text = tokens_text
        if tokens_hypo:
            self.tokens_hypo = tokens_hypo

        self.srl_t.set_frames(self.frames_text)
        self.srl_h.set_frames(self.frames_hypo)

        self.srl_t.set_tokens(self.tokens_text)
        self.srl_h.set_tokens(self.tokens_hypo)

        self.args_text = self.srl_t.get_words_frame()
        self.args_hypo = self.srl_h.get_words_frame()
        sum_verb = 0
        num_verbs_h = len(self.args_text.keys())
        self.__p_stderr('TINE VerbNet\n')
        self.__p_stderr('T: %s \n H: %s\n'%(self.args_text, self.args_hypo))
        self.__p_stderr('T: %s \n H: %s\n'%(self.args_text.keys(), self.args_hypo.keys()))

        for verb_t, args_t in self.args_text.items():
            for verb_h, args_h in self.args_hypo.items():
                sim_verbs = self.__simVerbs(verb_t, verb_h)
                if sim_verbs == 1:
                    self.__p_stderr('verbs(%s, %s)\n'%(verb_t, verb_h))
                    args_score = self.__simArgs(args_t, args_h)
                    sum_verb += args_score                    
        self.tine_score = float(sum_verb) / num_verbs_h
        self.__p_stderr('score:%s\n'%(self.tine_score))
        return self.tine_score

    def __simVerbs(self, verb_t = '', verb_h = ''):
        if verb_t == verb_h:
            return 1
        self.verb_net.set_text_verb(verb_t)
        self.verb_net.set_hypo_verb(verb_h)
        isec = self.verb_net.vn_isec()
        if isec == 0:
            vo = self.verb_net.vo()
            return vo
        else:
            return isec
        return isec


    def __simArgs(self, args_t = [], args_h = []):
        sum_args = 0
        num_args_h = len(args_h)
        for tag_t, tokens_t in args_t:
            for tag_h, tokens_h in args_h:
                if tag_t == tag_h:
                    expand_t = []
                    expand_h = []
                    if self.sim_type == 'Lin':
                        expand_t = self.lin.expand_bow(tokens_t)
                        expand_h = self.lin.expand_bow(tokens_h)
                    elif self.sim_type == 'WN':
                        expand_t = self.wn.expand_bow_tree(tokens_t)
                        expand_h = self.wn.expand_bow_tree(tokens_h)
                    self.arg_sim.set_text(expand_t)
                    self.arg_sim.set_hypo(expand_h)
                    self.arg_score = self.arg_sim.cosine()
                    self.__p_stderr('\t[%s|%s] %s %s\n'%(tag_t, self.arg_score, expand_t, expand_h))
                    sum_args += self.arg_score
        if num_args_h == 0:
            return 0
        else:
            self.verb_score = float(sum_args) / num_args_h
            return self.verb_score

    def __p_stderr(self, text = ''):
        if self.verbose == 1:
            sys.stderr.write(text)
        return

    def get_verb_score(self):
        return self.verb_score

    def get_arg_score(self):
        return self.arg_score


