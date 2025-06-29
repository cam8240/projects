import numpy as np

def load_vocabulary(vocabularyfile):
    '''
    @param:
    vocabularyfile (str) - name of a file that contains a list of unique words
    @return:
    vocabulary (list) - list of those words, in the same order they had in the file
    '''
    with open(vocabularyfile) as f:
        return f.read().strip().split()

def load_data(datafile, vocabulary):
    '''
    Load data from a datafile.
    
    @param:
    datafile (str) - the input filename, one sentence per line
    vocabulary (list) - a list of words in the vocabulary, length V

    @return:
    sentences - a list of N sentences, each of which is a list of T words. 
    embeddings - a list of N numpy arrays, each of size T[n]-by-V
      embeddings[n][t,:] is one-hot embedding of the t'th word in the n'th sentence.
    '''
    
    word2int = { w:i for i,w in enumerate(vocabulary) }

    embeddings = []
    sentences = []
    with open(datafile) as f:
        for line in f:
            sentence = line.strip().split()
            X = np.zeros((len(sentence), len(vocabulary)))
            for i,w in enumerate(sentence):
                X[i,word2int[w]] = 1
            sentences.append(sentence)
            embeddings.append(X)
    return sentences, embeddings

def define_task(embeddings):
    '''
    Split the lexical embeddings into XK, XQ, and Y.

    @param:
    embeddings - a T-by-V array, where T is length of the sentence, and V is size of vocabulary

    @return:
    XK - a (T-2)-by-V array, with embeddings that are used to generate key and value vectors
    XQ - a 2-by-V array, with embeddings that are used to generate query vectors
    Y - a 2-by-V array, with embeddings that are the output targets for the transformer
    '''
    XK = embeddings[:-2,:]
    XQ = np.array([np.average(embeddings[:-2,:],axis=0),np.average(embeddings[:-1,:],axis=0)])
    Y = embeddings[-2:,:]
    return XK, XQ, Y

def load_model(modelfile):
    '''
    Load a model from a text file.

    @param:
    modelfile (str) - name of the file to which model should be saved
    @return:
    WK - numpy array, size V-by-d where V is vocabulary size, d is embedding dimension
    WO - numpy array, size d-by-V where V is vocabulary size, d is embedding dimension
    WQ - numpy array, size V-by-d where V is vocabulary size, d is embedding dimension
    WV - numpy array, size V-by-d where V is vocabulary size, d is embedding dimension
    '''
    model = np.loadtxt(modelfile)
    WK = model[:int(model.shape[0]/4)]
    WO = model[int(model.shape[0]/4):int(2*model.shape[0]/4)].T
    WQ = model[int(2*model.shape[0]/4):int(3*model.shape[0]/4)]
    WV = model[int(3*model.shape[0]/4):]
    return WK, WO, WQ, WV
                                    
def save_model(modelfile, WK, WO, WQ, WV):
    '''
    Save a model to a text file

    @param:
    modelfile (str) - name of the file to which model should be saved
    WK - numpy array, size V-by-d where V is vocabulary size, d is embedding dimension
    WO - numpy array, size d-by-V where V is vocabulary size, d is embedding dimension
    WQ - numpy array, size V-by-d where V is vocabulary size, d is embedding dimension
    WV - numpy array, size V-by-d where V is vocabulary size, d is embedding dimension
    '''
    with open(modelfile, 'w') as f:
        f.write('\n'.join(' '.join([[x for x in row] for row in WK])))
        f.write('\n'.join(' '.join([[x for x in row] for row in WO.T])))
        f.write('\n'.join(' '.join([[x for x in row] for row in WQ])))
        f.write('\n'.join(' '.join([[x for x in row] for row in WV])))
