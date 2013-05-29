import pickle
from metrics import SetMetrics, VerbMetrics, VectorMetrics, NEMetrics
from rteTools import Lin, SRLTools, WNTools
import sys

class Edistance:
    def __init__(self, frames_text = {}, tokens_text = [], chunks_text = [],  frames_hypo = {}, tokens_hypo = [], chunks_hypo = [], e_type = 'simple', verbose = 1, entailment = -1):
        self.e_type = e_type
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
        self.chunks_hypo = chunks_hypo
        self.chunks_text = chunks_text
        self.args_text = {}
        self.args_hypo = {}
        self.verbs_text = []
        self.verbs_hypo = []
        self.edit_score = 0
        self.verb_score = 0
        self.chunk_score = 0
        self.oper_type = {'del':0, 'in':0, 'sub':0}
        self.verbose = verbose
        self.entailment = entailment
        return


    def get_edistance_micai(self, frames_text = {}, tokens_text = [], chunks_text = [],  frames_hypo = {}, tokens_hypo = [], chunks_hypo = [], entailment = -1):
        if frames_text:
            self.frames_text = frames_text
        if frames_hypo:
            self.frames_hypo = frames_hypo
        if tokens_text:
            self.tokens_text = tokens_text
        if tokens_hypo:
            self.tokens_hypo = tokens_hypo
        if chunks_text:
            self.chunks_text = chunks_text
        if chunks_hypo:
            self.chunks_hypo = chunks_hypo
        if entailment:
            self.entailment = entailment

        self.srl_t.set_frames(self.frames_text)
        self.srl_h.set_frames(self.frames_hypo)

        self.srl_t.set_tokens(self.tokens_text)
        self.srl_h.set_tokens(self.tokens_hypo)

        self.args_text = self.srl_t.get_words_frame()
        self.args_hypo = self.srl_h.get_words_frame()
        sum_verb = 0
        num_verbs_h = len(self.args_text.keys())
        self.__p_stderr('###V(%s)###\nT:%s\nH:%s\n'%(self.entailment, ' '.join(tokens_text), ' '.join(tokens_hypo)))
        self.edit_score = 0
        for verb_t, args_t in self.args_text.items():
            for verb_h, args_h in self.args_hypo.items():
                sim_verbs = self.__simVerbs(verb_t, verb_h)
                if sim_verbs == 1:
                    #sim verbs
                    self.__p_stderr('\tverbs(%s, %s)\n'%(verb_t, verb_h))
                    if self.e_type == 'simple':
                        self.edit_score += self.__simpleARG(args_t, args_h)
        self.edit_score = float(self.edit_score) / num_verbs_h
        self.__p_stderr('\ted_score(%s)\n'%(self.edit_score))
        if self.edit_score == 0.0:
            self.edit_score = self.__back_off_order(self.chunks_text, self.chunks_hypo)
        #if edit_score == 0 go for chunk backoff
        return self.edit_score

    def __simpleARG(self, args_t = [], args_h = []):
        score = 1.0
        oper_sum = 0
        tags_t = self.__extract_tags(args_t)
        tags_h = self.__extract_tags(args_h)
        self.oper_type = {'del':0, 'in':0, 'sub':0}
        #look for sub
        for tag_t, tokens_t in tags_t.items():
            for tag_h, tokens_h in tags_h.items():
                if tag_t == tag_h: # same tag
                    if ' '.join(tokens_t) != ' '.join(tokens_h):
                        self.oper_type['sub'] += 1 #subtitution
                        self.__p_stderr('\t\toper(sub): [%s] %s -> %s\n'%(tag_t, tokens_t, tokens_h))
                        oper_sum += 1
        #look for insertion
        for tag_t, tokens_t in tags_t.items():
            if not tag_t in tags_h: # insertion
                self.oper_type['in'] += 1
                self.__p_stderr('\t\toper(in): [%s] %s\n'%(tag_t, tags_t[tag_t]))
                oper_sum += 1
        #look for deletion
        for tag_h, tokens_h in tags_h.items():
            if not tag_h in tags_t: # deletion
                self.oper_type['del'] += 1
                self.__p_stderr('\t\toper(del): [%s] %s\n'%(tag_h, tags_h[tag_h]))
                oper_sum += 1

        self.__p_stderr('num oper: %s\n'%self.oper_type)
        self.__p_stderr('sum oper: %s\n'%oper_sum)
        if oper_sum == 0:
            return 0
        else:
            score = score / float(oper_sum)
            self.__p_stderr('simp_score: %s\n'%score)
            return score

    def __extract_tags(self, args):
        tags = {}
        for tag, tokens in args:
            tags[tag] = tokens
        return tags


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

    def __back_off_order(self, chunks_t = [], chunks_h = []):
        score = 0
        sum_ch = 0
        self.__p_stderr('chunk back-off\n')
        chunks_t = chunks_t.pos()
        chunks_h = chunks_h.pos()
        for i, chunk_h in enumerate(chunks_h):
            try: 
                (node_t, tag_t) = chunks_t[i]
                (node_h, tag_h) = chunk_h
                if tag_t == tag_h:
                    (word_t, pos_t) = node_t
                    (word_h, pos_h) = node_h
                    if word_t == word_h:
                        sum_ch += 1.0
                        self.__p_stderr('\t[%s]: %s\n'%(tag_t, word_t))
                    else:
                        sum_ch += 0.5
                        self.__p_stderr('\t[%s|%s]: %s %s \n'%(tag_t,  sum_ch, word_t, word_h))
            except:
                sum_ch += 0.0

        score = float(sum_ch) / len(chunks_h)
        return score

    def __p_stderr(self, text = ''):
        if self.verbose == 1:
            sys.stderr.write(text)
        return

