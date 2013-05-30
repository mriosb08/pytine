import string
from bsddb3 import db
import itertools
from nltk.corpus import wordnet


class RTETools:
    """Tools for quit stop words and quit punctuation.
        Input:
            tokens: list of tokens
    """
    def __init__(self, tokens = []):
        self.tokens = tokens
        self.sw = {'a':1, 'about':1, 'above':1, 'above':1, 'across':1, 'after':1, 'afterwards':1, 'again':1, 'against':1, 'all':1, 'almost':1, 'alone':1, 'along':1, 'already':1, 'also':1,'although':1,'always':1,'am':1,'among':1, 'amongst':1, 'amoungst':1, 'amount':1,  'an':1, 'and':1, 'another':1, 'any':1,'anyhow':1,'anyone':1,'anything':1,'anyway':1, 'anywhere':1, 'are':1, 'around':1, 'as':1,  'at':1, 'back':1,'be':1,'became':1, 'because':1,'become':1,'becomes':1, 'becoming':1, 'been':1, 'before':1, 'beforehand':1, 'behind':1, 'being':1, 'below':1, 'beside':1, 'besides':1, 'between':1, 'beyond':1, 'bill':1, 'both':1, 'bottom':1,'but':1, 'by':1, 'call':1, 'can':1, 'cannot':1, 'cant':1, 'co':1, 'con':1, 'could':1, 'couldnt':1, 'cry':1, 'de':1, 'describe':1, 'detail':1, 'do':1, 'done':1, 'down':1, 'due':1, 'during':1, 'each':1, 'eg':1, 'eight':1, 'either':1, 'eleven':1,'else':1, 'elsewhere':1, 'empty':1, 'enough':1, 'etc':1, 'even':1, 'ever':1, 'every':1, 'everyone':1, 'everything':1, 'everywhere':1, 'except':1, 'few':1, 'fifteen':1, 'fify':1, 'fill':1, 'find':1, 'fire':1, 'first':1, 'five':1, 'for':1, 'former':1, 'formerly':1, 'forty':1, 'found':1, 'four':1, 'from':1, 'front':1, 'full':1, 'further':1, 'get':1, 'give':1, 'go':1, 'had':1, 'has':1, 'hasnt':1, 'have':1, 'he':1, 'hence':1, 'her':1, 'here':1, 'hereafter':1, 'hereby':1, 'herein':1, 'hereupon':1, 'hers':1, 'herself':1, 'him':1, 'himself':1, 'his':1, 'how':1, 'however':1, 'hundred':1, 'ie':1, 'if':1, 'in':1, 'inc':1, 'indeed':1, 'interest':1, 'into':1, 'is':1, 'it':1, 'its':1, 'itself':1, 'keep':1, 'last':1, 'latter':1, 'latterly':1, 'least':1, 'less':1, 'ltd':1, 'made':1, 'many':1, 'may':1, 'me':1, 'meanwhile':1, 'might':1, 'mill':1, 'mine':1, 'more':1, 'moreover':1, 'most':1, 'mostly':1, 'move':1, 'much':1, 'must':1, 'my':1, 'myself':1, 'name':1, 'namely':1, 'neither':1, 'never':1, 'nevertheless':1, 'next':1, 'nine':1, 'no':1, 'nobody':1, 'none':1, 'noone':1, 'nor':1, 'not':1, 'nothing':1, 'now':1, 'nowhere':1, 'of':1, 'off':1, 'often':1, 'on':1, 'once':1, 'one':1, 'only':1, 'onto':1, 'or':1, 'other':1, 'others':1, 'otherwise':1, 'our':1, 'ours':1, 'ourselves':1, 'out':1, 'over':1, 'own':1,'part':1, 'per':1, 'perhaps':1, 'please':1, 'put':1, 'rather':1, 're':1, 'same':1, 'see':1, 'seem':1, 'seemed':1, 'seeming':1, 'seems':1, 'serious':1, 'several':1, 'she':1, 'should':1, 'show':1, 'side':1, 'since':1, 'sincere':1, 'six':1, 'sixty':1, 'so':1, 'some':1, 'somehow':1, 'someone':1, 'something':1, 'sometime':1, 'sometimes':1, 'somewhere':1, 'still':1, 'such':1, 'system':1, 'take':1, 'ten':1, 'than':1, 'that':1, 'the':1, 'their':1, 'them':1, 'themselves':1, 'then':1, 'thence':1, 'there':1, 'thereafter':1, 'thereby':1, 'therefore':1, 'therein':1, 'thereupon':1, 'these':1, 'they':1, 'thickv':1, 'thin':1, 'third':1, 'this':1, 'those':1, 'though':1, 'three':1, 'through':1, 'throughout':1, 'thru':1, 'thus':1, 'to':1, 'together':1, 'too':1, 'top':1, 'toward':1, 'towards':1, 'twelve':1, 'twenty':1, 'two':1, 'un':1, 'under':1, 'until':1, 'up':1, 'upon':1, 'us':1, 'very':1, 'via':1, 'was':1, 'we':1, 'well':1, 'were':1, 'what':1, 'whatever':1, 'when':1, 'whence':1, 'whenever':1, 'where':1, 'whereafter':1, 'whereas':1, 'whereby':1, 'wherein':1, 'whereupon':1, 'wherever':1, 'whether':1, 'which':1, 'while':1, 'whither':1, 'who':1, 'whoever':1, 'whole':1, 'whom':1, 'whose':1, 'why':1, 'will':1, 'with':1, 'within':1, 'without':1, 'would':1, 'yet':1, 'you':1, 'your':1, 'yours':1, 'yourself':1, 'yourselves':1, 'the':1}
        return

    def set_tokens(self, tokens = []):
        self.tokens = tokens
        return

    def get_tokens(self):
        return self.tokens

    def quit_sw(self, sw = {}):
        """Quit stop words
            Input: 
                sw: dictionary with a different stop word list
            Output:
                list of tokens witout sw
        """
        if sw:
            self.sw = sw
        tmp = []
        for token in self.tokens:
            if token not in self.sw:
                tmp.append(token)
        self.tokens = tmp
        return self.tokens

    def quit_punct(self):
        """Quit punctuation
            Output:
                list of tokens without punctuation
        """
        tmp = ' '.join(self.tokens)
        tmp_np = tmp.translate(None, string.punctuation)
        self.tokens = tmp_np.split()
        return self.tokens


class SRLTools:
    """Tools for SRL frames for a given part text or hypo.
    Input:
        tokens: list with word tokens
        tokens_frames: list with SRL tags
        tokens_verbs: list with verb targets
    """
    def __init__(self, tokens = [], tokens_frames = [], tokens_verbs = []):
        self. tokens = tokens
        self.tokens_frames = tokens_frames
        self.tokens_verbs = tokens_verbs
        self.__extract_verbs() #Extracts the verbs from the frames and tokens
        return
   #setters
    def set_tokens(self, tokens = []):
        self.tokens = tokens
        return

    def set_frames(self, tokens_frames = []):
        self.tokens_frames = tokens_frames
        return

    def set_verbs(self, token_verbs = []):
        self.tokens_verbs = tokens_verbs
        return
    #getters
    def get_token(self):
        return self.tokens

    def get_frames(self):
        return self.tokens_frames

    def get_verbs(self):
        return self.tokens_verbs

    def get_words_frame(self):
        """Attachs words to the SRL tags frames.
        Output:
            dictionary of tag-chunk pairs, where the chunk is the start and end positions of a span. 
        """
        frames = {}
        verb = ''
        for pairs in self.tokens_frames:
            frame = []
            for pair in pairs:
                (range_span, tag) = pair
                (start, end) = range_span
                if tag.startswith('V'):
                    verb = ' '.join(self.tokens[start:end])
                else:
                    frame.append((tag, self.tokens[start:end]))
            frames[verb] = frame
        return frames

    def __extract_verbs(self):
        """Attaches the verbs from th tokens to the SRL tags"""
        self.tokens_verbs = []
        for pairs in self.tokens_frames:
            for pair in pairs:
                (range_span, tag) = pair
                if tag.startswith('V'):
                    (start, end) = range_span
                    verb = ' '.join(self.tokens[start:end])
                    self.tokens_verbs.append((verb, range_span))

class WNTools:
    """Tools for extract information from WordNet for nouns
    Input:
        wn_file: file path to WordNet
    """
    def __init__(self, wn_file = 'data/wn_hyper.db'):
        self.wn_file = wn_file
        self.wn_DB = db.DB()
        self.wn_DB.open(wn_file, None, db.DB_BTREE, db.DB_DIRTY_READ)
        self.syns = []
        return

    def get_mfs_hypernyms(self, wns = (), sense = '01'):
        """Returns the hypernym tree for a noun.
        Input:
            wns: tuple with word-PoS 
            sense: string with the sense default '01' first sense in WordNet
        Ouput:
            list of tuples with word-hypernyms 
        """
        result = []
        (lemma, pos) = wns
        pos = self.__wn_poscode(pos)
        key = lemma + '.' + pos + '.' + sense
        if pos.startswith('n'):
            data = self.wn_DB.get(key)
            if data:
                tmp = data.split()
                result.append((key, tmp))
            else:
                result.append((key, []))
        return result

    def expand_bow_tree(self, bow = [], sense = '01'):
        """Expands nouns in a list with hypernyms to form a bag of words
        Input:
            bow: list with tuples with word-PoS
            sense: string with the sense default '01' first sense in WordNet
        Output:
            list with a bag of words
        """
        result = []
        for lemma, pos in bow:
            result.append(lemma)
            
            pos = self.__wn_poscode(pos)
            key = lemma + '.' + pos + '.' + sense
            
            if pos.startswith('n'):
                data = self.wn_DB.get(key)
                if data:
                    tmps = data.split()
                    for tmp in tmps:
                        result.append(tmp)
        return result

    def get_synset(self, word = ''):
        """Returns the synsets for a given word.
        Input:
            word: string with the token
        Output:
            list with synsets
        """
        syns = wordnet.synsets(word)
        self.syns = [l.name for s in syns for l in s.lemmas]
        return self.syns

    def expand_bow_syns(self, bow = []):
        """Expand words in a list with synsets to form a bag of words.
        Input:
            bow: list with tokens
        Output:
            list with tokens plus synsets
        """
        for word in bow:
            syns = wordnet.synsets(word)
            self.syns = [l.name for s in syns for l in s.lemmas]
            self.syns.append(word)
        return self.syns

    def __wn_poscode(self, tag):
        if tag.startswith('NN'):
            return 'n'
        elif tag.startswith('VB'):
            return 'v'
        elif tag.startswith('JJ'):
            return 'a'
        elif tag.startswith('RB'):
            return 'r'
        else:
            return tag.lower()

class Lin:
    """Lin thesaurus for extract similar words
    Input:
        dk_file: file path for the thesaurus db
    """

    def __init__(self, dk_file = 'data/sims.db'):
        self.dk_DB = db.DB()
        self.dk_DB.open(dk_file, None, db.DB_BTREE, db.DB_DIRTY_READ)
        self.words = []
        return

    def n_similar_words(self, word = '', n_words = 20):
        """Extracts the N similar words for a given word.
        Input:
            word: string with the word for query
            n_words: number of similar words to retrieve, default 20
        Output:
            list of tuples word-sim_score for the given word
        """
        data = self.dk_DB.get(word)
        if data:
            self.words = []
            word_pairs = data.split()
            for i in xrange(n_words):
                try:
                    (word, score) = word_pairs[i].split('=')
                except:
                    word = ''
                    score = 0.0
                self.words.append((word, float(score)))
        return self.words

    def expand_w(self, word = '', n_words = 20):
        """Expands the given word with n similar words to form a bag of words.
        Input:
            word: string with the word for query
            n_words: number of similar words to retrieve, default 20
        Output:
            list with a bag of words
        """
        self.words = []
        data = self.dk_DB.get(word)
        self.words.append(word)
        if data:
            word_pairs = data.split()
            for i in xrange(n_words):
                try:
                    (sim_word, score) = word_pairs[i].split('=')
                    self.words.append(sim_word)
                except:
                    sim_word = ''
        return self.words

    def expand_bow(self, bow = [], n_words = 20):
        """Expands a list of tokens with n similar words.
        Input:
            bow: list of tokens
            n_words: number of similar words to retrieve, default 20
        Output:
            list with a bag of words
        """
        self.words = []
        for word in bow:
            data = self.dk_DB.get(word)
            self.words.append(word)
            if data:
                word_pairs = data.split()
                for i in xrange(n_words):
                    try:
                        (sim_word, score) = word_pairs[i].split('=')
                        self.words.append(sim_word)
                    except:
                        sim_word = ''
        return self.words


class VerbTools:
    """Tools for extract information from verbs
    Input:
        verb: string with the verb
        vn_file: file path for verbnet db
        vo_file: file path for verbocean db
        direct_file: file path for direct db
        vn_strict: strict comparison of vn classes default 1
    """
    def __init__(self, verb = '', vn_file = 'data/vn_classes.db'
            , vo_file = 'data/verbocean.db', direct_file = 'data/DIRECT_verbs_1000.db', vn_strict = 1):
        self.verb = verb
        self.verb_h = ''
        self.vn_file = vn_file
        self.vn_DB = db.DB()
        self.vn_DB.open(vn_file, None, db.DB_BTREE, db.DB_DIRTY_READ)
        self.vo_DB = db.DB()
        self.vo_DB.open(vo_file, None, db.DB_BTREE, db.DB_DIRTY_READ)
        self.vo_relations = ('can-result-in'
                ,'happens-before'
                ,'low-vol'
                ,'opposite-of'
                ,'similar'
                ,'stronger-than'
                ,'unk')
        self.vn_strict = vn_strict
        self.classes = []
        return

    def set_verb(self, verb):
        self.verb = verb
        return

    def get_voRelations(self):
        return self.vo_relations

    def vn_classes(self):
        """Extract verbnet classes
        Output:
            list of classes if sctrict the tag for the class is different
        """
        value = self.vn_DB.get(self.verb)
        if value:
            if self.vn_strict == 1:
                self.classes = value.split()
            else:
                tmp = value.split()
                for tmp_cl in tmp:
                    (verb, cl) = tmp_cl.split('-', 1)
                    self.classes.append(verb)
        return self.classes

    def verb_relations(self, verb_h = ''):
        """Extract relations from verbocean
        Input:
            verb_h: second verb to compare with
        Output:
            list of relations between verbs
        """
        key = self.verb + ' ' + self.verb_h
        value = self.vo_DB.get(key)
        if value:
            (relation_vo, score) = value.split()
            return (relation_vo, score)
        else:
            return (None, None)


class NounTools:
    """Tools to extract information from nouns
    Input:
        noun_t: string with noun from text
        noun_h: string with noun from hypo
        direct_file: file path for direc noun db
    """
    def __init__(self, noun_t = '', noun_h = '', direct_file = 'data/DIRECT_nouns_1000.db'):
        self.noun_t = noun_t
        self.noun_h = noun_h
        self.direct_DB = db.DB()
        self.direct_DB.open(direct_file, None, db.DB_BTREE, db.DB_DIRTY_READ)
        return
    
    def set_nount(self, noun_t = ''):
        self.noun_t = noun_t
        return

    def set_nounh(self, noun_h = ''):
        self.noun_h = noun_h
        return
    
    def direct(self):
        """Computes entialment directional relation between a pair of nouns (e.g. koala => animal, true).
        Output:
            1: if the nouns hold a directional entialment relation
            0: oz
        """
        if self.noun_t == self.noun_h:
            return 1
        else:
             key_th = self.noun_t + '|||' + self.noun_h
             key_ht = self.noun_h + '|||' + self.noun_t
             value_th = self.direct_DB.get(key_th)
             value_ht = self.direct_DB.get(key_ht)
             if value_th > value_ht:
                 return 1
             else:
                 return 0

