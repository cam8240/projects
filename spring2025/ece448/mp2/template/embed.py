import numpy as np

def initialize(data, dim):
    '''
    Initialize embeddings for all distinct words in the input data.
    Most of the dimensions will be zero-mean unit-variance Gaussian random variables.
    In order to make debugging easier, however, we will assign special geometric values
    to the first two dimensions of the embedding:

    (1) Find out how many distinct words there are.
    (2) Choose that many locations uniformly spaced on a unit circle in the first two dimensions.
    (3) Put the words into those spots in the same order that they occur in the data.

    Thus if data[0] and data[1] are different words, you should have

    embedding[data[0]] = np.array([np.cos(0), np.sin(0), random, random, random, ...])
    embedding[data[1]] = np.array([np.cos(2*np.pi/N), np.sin(2*np.pi/N), random, random, random, ...])

    ... and so on, where N is the number of distinct words, and each random element is
    a Gaussian random variable with mean=0 and standard deviation=1.

    @param:
    data (list) - list of words in the input text, split on whitespace
    dim (int) - dimension of the learned embeddings

    @return:
    embedding - dict mapping from words (strings) to numpy arrays of dimension=dim.
    '''
    unique_words = list(dict.fromkeys(data))
    N = len(unique_words)
    
    embedding = {}

    for i, word in enumerate(unique_words):
        emb = np.zeros(dim)
        emb[0] = np.cos(2 * np.pi * i / N)
        emb[1] = np.sin(2 * np.pi * i / N)
        if dim > 2:
            emb[2:] = np.random.randn(dim - 2)
        embedding[word] = emb

    return embedding



def gradient(embedding, data, t, d, k):
    '''
    Calculate gradient of the skipgram NCE loss with respect to the embedding of data[t]

    @param:
    embedding - dict mapping from words (strings) to numpy arrays.
    data (list) - list of words in the input text, split on whitespace
    t (int) - data index of word with respect to which you want the gradient
    d (int) - choose context words between t-d and t-d, not including t
    k (int) - compare each context word to k words chosen uniformly at random from the data

    @return:
    g (numpy array) - loss gradients with respect to embedding of data[t]
    '''
    def sigmoid(x):
        return 1.0 / (1.0 + np.exp(-x))
    
    g = np.zeros_like(embedding[data[t]])
    N = len(data)
    
    context_indices = [t + c for c in range(-d, d + 1) if c != 0 and 0 <= t + c < N]
    
    v_t = embedding[data[t]]
    for c in context_indices:
        v_c = embedding[data[c]]
        sigma_tc = sigmoid(np.dot(v_t, v_c))
        g += (1 - sigma_tc) * v_c

        unique_words = list(set(data))
        for _ in range(k):
            w_i = np.random.choice(unique_words)
            v_i = embedding[w_i]
            sigma_ti = sigmoid(np.dot(v_t, v_i))
            g -= (sigma_ti / k) * v_i
    
    return g


           
def sgd(embedding, data, learning_rate, num_iters, d, k):
    '''
    Perform num_iters steps of stochastic gradient descent.

    @param:
    embedding - dict mapping from words (strings) to numpy arrays.
    data (list) - list of words in the input text, split on whitespace
    learning_rate (scalar) - scale the negative gradient by this amount at each step
    num_iters (int) - the number of iterations to perform
    d (int) - context width hyperparameter for gradient computation
    k (int) - noise sample size hyperparameter for gradient computation

    @return:
    embedding - the updated embeddings
    '''
    for _ in range(num_iters):
        t = np.random.randint(len(data))
        g = gradient(embedding, data, t, d, k)
        embedding[data[t]] -= learning_rate * g
    return embedding
