from collections import defaultdict, Counter

def baseline(train, test):
    '''
    input:  training data (list of sentences, with tags on the words).
            Each sentence is a list of (word, tag) pairs.
            test data (list of sentences, no tags on the words).
            Each sentence is a list of words.
    output: list of sentences, each sentence is a list of (word, tag) pairs.
    '''
    word_tag_counts = {}
    tag_counts = {}
    
    for sentence in train:
        for word, tag in sentence:
            if word not in word_tag_counts:
                word_tag_counts[word] = {}
            word_tag_counts[word][tag] = word_tag_counts[word].get(tag, 0) + 1
            tag_counts[tag] = tag_counts.get(tag, 0) + 1

    most_common_tag = max(tag_counts, key=tag_counts.get)

    result = []
    for sentence in test:
        tagged_sentence = []
        for word in sentence:
            if word in word_tag_counts:
                tag = max(word_tag_counts[word], key=word_tag_counts[word].get)
            else:
                tag = most_common_tag
            tagged_sentence.append((word, tag))
        result.append(tagged_sentence)

    return result