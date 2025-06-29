"""
Part 2: This is the simplest version of viterbi that doesn't do anything special for unseen words
but it should do better than the baseline at words with multiple tags (because now you're using context
to predict the tag).
"""

import math
from collections import defaultdict, Counter
from math import log

# Note: remember to use these two elements when you find a probability is 0 in the training data.
epsilon_for_pt = 1e-5
emit_epsilon = 1e-5   # exact setting seems to have little or no effect


def training(sentences):
    """
    Computes initial tags, emission words and transition tag-to-tag probabilities
    :param sentences:
    :return: intitial tag probs, emission words given tag probs, transition of tags to tags probs
    """
    init_prob = defaultdict(lambda: 0) # {init tag: #}
    emit_prob = defaultdict(lambda: defaultdict(lambda: 0)) # {tag: {word: # }}
    trans_prob = defaultdict(lambda: defaultdict(lambda: 0)) # {tag0:{tag1: # }}
    
    # TODO: (I)
    # Input the training set, output the formatted probabilities according to data statistics.
    
    for sentence in sentences:
        for i, (word, tag) in enumerate(sentence):
            if i == 0:
                init_prob[tag] += 1
            else:
                prev_tag = sentence[i-1][1]
                trans_prob[prev_tag][tag] += 1
            emit_prob[tag][word] += 1

    total_sentences = len(sentences)
    for tag in init_prob:
        init_prob[tag] /= total_sentences

    for tag in emit_prob:
        total_words_for_tag = sum(emit_prob[tag].values())
        V = len(emit_prob[tag])
        denom = total_words_for_tag + emit_epsilon * (V + 1)
        for word in list(emit_prob[tag].keys()):
            emit_prob[tag][word] = (emit_prob[tag][word] + emit_epsilon) / denom
        emit_prob[tag]["<UNK>"] = emit_epsilon / denom

    for tag in trans_prob:
        total_transitions = sum(trans_prob[tag].values())
        for next_tag in trans_prob[tag]:
            trans_prob[tag][next_tag] /= total_transitions

    return init_prob, emit_prob, trans_prob

def viterbi_stepforward(i, word, prev_prob, prev_predict_tag_seq, emit_prob, trans_prob):
    """
    Does one step of the viterbi function
    :param i: The i'th column of the lattice/MDP (0-indexing)
    :param word: The i'th observed word
    :param prev_prob: A dictionary of tags to probs representing the max probability of getting to each tag at in the
    previous column of the lattice
    :param prev_predict_tag_seq: A dictionary representing the predicted tag sequences leading up to the previous column
    of the lattice for each tag in the previous column
    :param emit_prob: Emission probabilities
    :param trans_prob: Transition probabilities
    :return: Current best log probs leading to the i'th column for each tag, and the respective predicted tag sequences
    """
    log_prob = {} # This should store the log_prob for all the tags at current column (i)
    predict_tag_seq = {} # This should store the tag sequence to reach each tag at column (i)

    # TODO: (II)
    # implement one step of trellis computation at column (i)
    # You should pay attention to the i=0 special case.

    for tag in emit_prob:
        max_log_prob = float('-inf')
        best_prev_tag = None
        
        for prev_tag in prev_prob:
            transition_prob = trans_prob[prev_tag][tag] if tag in trans_prob[prev_tag] else epsilon_for_pt
            if word in emit_prob[tag]:
                current_emit = emit_prob[tag][word]
            else:
                current_emit = emit_prob[tag]["<UNK>"]
            
            current_log_prob = prev_prob[prev_tag] + log(transition_prob) + log(current_emit)
            
            if current_log_prob > max_log_prob:
                max_log_prob = current_log_prob
                best_prev_tag = prev_tag

        log_prob[tag] = max_log_prob
        predict_tag_seq[tag] = prev_predict_tag_seq[best_prev_tag] + [tag]

    return log_prob, predict_tag_seq

def viterbi_1(train, test, get_probs=training):
    '''
    input:  training data (list of sentences, with tags on the words). E.g.,  [[(word1, tag1), (word2, tag2)], [(word3, tag3), (word4, tag4)]]
            test data (list of sentences, no tags on the words). E.g.,  [[word1, word2], [word3, word4]]
    output: list of sentences, each sentence is a list of (word,tag) pairs.
            E.g., [[(word1, tag1), (word2, tag2)], [(word3, tag3), (word4, tag4)]]
    '''
    init_prob, emit_prob, trans_prob = get_probs(train)
    
    predicts = []
    
    for sen in range(len(test)):
        sentence=test[sen]
        length = len(sentence)
        log_prob = {}
        predict_tag_seq = {}
        # init log prob
        for t in emit_prob:
            if t in init_prob:
                log_prob[t] = log(init_prob[t])
            else:
                log_prob[t] = log(epsilon_for_pt)
            predict_tag_seq[t] = []

        # forward steps to calculate log probs for sentence
        for i in range(length):
            log_prob, predict_tag_seq = viterbi_stepforward(i, sentence[i], log_prob, predict_tag_seq, emit_prob,trans_prob)
            
        # TODO:(III) 
        # according to the storage of probabilities and sequences, get the final prediction.
        # Backtrace to get the final prediction
        best_final_tag = max(log_prob, key=log_prob.get)
        best_sequence = predict_tag_seq[best_final_tag]
        
        tagged_sentence = list(zip(sentence, best_sequence))
        predicts.append(tagged_sentence)

    return predicts