# naive_bayes.py
# ---------------
# Licensing Information:  You are free to use or extend this projects for
# educational purposes provided that (1) you do not distribute or publish
# solutions, (2) you retain this notice, and (3) you provide clear
# attribution to the University of Illinois at Urbana-Champaign
#
# Created by Justin Lizama (jlizama2@illinois.edu) on 09/28/2018
# Last Modified 8/23/2023


"""
This is the main code for this MP.
You only need (and should) modify code within this file.
Original staff versions of all other files will be used by the autograder
so be careful to not modify anything else.
"""


import reader
import math
from tqdm import tqdm
from collections import Counter


'''
util for printing values
'''
def print_values(laplace, pos_prior):
    print(f"Unigram Laplace: {laplace}")
    print(f"Positive prior: {pos_prior}")

"""
load_data loads the input data by calling the provided utility.
You can adjust default values for stemming and lowercase, when we haven't passed in specific values,
to potentially improve performance.
"""
def load_data(trainingdir, testdir, stemming=False, lowercase=False, silently=False):
    print(f"Stemming: {stemming}")
    print(f"Lowercase: {lowercase}")
    train_set, train_labels, dev_set, dev_labels = reader.load_dataset(trainingdir,testdir,stemming,lowercase,silently)
    return train_set, train_labels, dev_set, dev_labels


"""
Main function for training and predicting with naive bayes.
    You can modify the default values for the Laplace smoothing parameter and the prior for the positive label.
    Notice that we may pass in specific values for these parameters during our testing.
"""
def naive_bayes(train_labels, train_data, dev_data, laplace=1.6, pos_prior=0.5, silently=False):
    print_values(laplace, pos_prior)

    pos_counts = Counter()
    neg_counts = Counter()
    
    total_pos_words = 0
    total_neg_words = 0

    for review, label in tqdm(zip(train_data, train_labels), total=len(train_labels), desc="Training Naïve Bayes", disable=silently):
        if label == 1:
            pos_counts.update(review)
            total_pos_words += len(review)
        else:
            neg_counts.update(review)
            total_neg_words += len(review)

    vocab = set(pos_counts.keys()).union(set(neg_counts.keys()))
    vocab_size = len(vocab)

    def word_prob(word, class_counts, total_class_words):
        return (class_counts[word] + laplace) / (total_class_words + laplace * vocab_size)

    log_pos_prior = math.log(pos_prior)
    log_neg_prior = math.log(1 - pos_prior)

    predictions = []

    for review in tqdm(dev_data, desc="Classifying Reviews", disable=silently):
        log_prob_pos = log_pos_prior
        log_prob_neg = log_neg_prior

        for word in review:
            log_prob_pos += math.log(word_prob(word, pos_counts, total_pos_words))
            log_prob_neg += math.log(word_prob(word, neg_counts, total_neg_words))

        predictions.append(1 if log_prob_neg < log_prob_pos else 0)

    return predictions
