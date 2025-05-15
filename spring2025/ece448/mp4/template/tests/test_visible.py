import unittest
from gradescope_utils.autograder_utils.decorators import weight
import numpy as np
import transformer

# First, here are some input variables, and the outputs that should result
XK=np.array([[0., 0., 0., 1., 0.],
             [1., 0., 0., 0., 0.],
             [1., 0., 0., 0., 0.],
             [0., 0., 0., 1., 0.],
             [0., 0., 0., 0., 1.],
             [0., 1., 0., 0., 0.],
             [1., 0., 0., 0., 0.],
             [1., 0., 0., 0., 0.]])
XQ=np.array([[0.5  , 0.125, 0.   , 0.25 , 0.125],
             [0.444, 0.111, 0.   , 0.222, 0.222]])
Y=np.array([[0., 0., 0., 0., 1.],
            [0., 0., 1., 0., 0.]])
WK=np.array([[0., 0., 0., 0., 1.],
             [0., 0., 0., 1., 0.],
             [1., 0., 0., 0., 0.],
             [0., 1., 0., 0., 0.],
             [0., 1., 0., 0., 0.]])
WQ=np.array([[0., 1., 0., 0., 0.],
             [0., 0., 0., 0., 1.],
             [1., 0., 0., 0., 0.],
             [1., 0., 0., 0., 0.],
             [0., 0., 0., 1., 0.]])
WO=np.array([[0., 0., 0., 0., 1.],
             [1., 0., 0., 0., 0.],
             [0., 0., 0., 0., 1.],
             [0., 0., 0., 0., 1.],
             [0., 1., 0., 0., 0.]])
WV=np.array([[0., 0., 0., 0., 1.],
             [0., 1., 0., 0., 0.],
             [0., 0., 1., 0., 0.],
             [0., 1., 0., 0., 0.],
             [1., 0., 0., 0., 0.]])
A=np.array([[0.155, 0.107, 0.107, 0.155, 0.155, 0.107, 0.107, 0.107],
            [0.15 , 0.107, 0.107, 0.15 , 0.15 , 0.12 , 0.107, 0.107]])
C=np.array([[0.155, 0.418, 0.   , 0.   , 0.427],
            [0.15 , 0.42 , 0.   , 0.   , 0.43 ]])
K=np.array([[0., 1., 0., 0., 0.],
            [0., 0., 0., 0., 1.],
            [0., 0., 0., 0., 1.],
            [0., 1., 0., 0., 0.],
            [0., 1., 0., 0., 0.],
            [0., 0., 0., 1., 0.],
            [0., 0., 0., 0., 1.],
            [0., 0., 0., 0., 1.]])
O=np.array([[0.244, 0.246, 0.161, 0.161, 0.188],
            [0.245, 0.247, 0.161, 0.161, 0.187]])
Q=np.array([[0.25 , 0.5  , 0.   , 0.125, 0.125],
            [0.222, 0.444, 0.   , 0.222, 0.111]])
V=np.array([[0., 1., 0., 0., 0.],
            [0., 0., 0., 0., 1.],
            [0., 0., 0., 0., 1.],
            [0., 1., 0., 0., 0.],
            [1., 0., 0., 0., 0.],
            [0., 1., 0., 0., 0.],
            [0., 0., 0., 0., 1.],
            [0., 0., 0., 0., 1.]])
L=np.array(3.5)
dO=np.array([[-0.   , -0.   , -0.   , -0.   , -5.324],
             [-0.   , -0.   , -6.221, -0.   , -0.   ]])
dWK=np.array([[ 0.019,  0.037,  0.   ,  0.01 ,  0.009],
              [ 0.005,  0.009,  0.   ,  0.002,  0.002],
              [ 0.   ,  0.   ,  0.   ,  0.   ,  0.   ],
              [ 0.013,  0.026,  0.   ,  0.007,  0.007],
              [-0.036, -0.073,  0.   , -0.019, -0.018]])
dWO=np.array([[ 0.075,  0.075, -0.101,  0.049, -0.098],
              [ 0.205,  0.207, -0.285,  0.135, -0.261],
              [ 0.   ,  0.   ,  0.   ,  0.   ,  0.   ],
              [ 0.   ,  0.   ,  0.   ,  0.   ,  0.   ],
              [ 0.209,  0.211, -0.292,  0.138, -0.267]])
dWQ=np.array([[ 0.   , -0.046,  0.   ,  0.009,  0.037],
              [ 0.   , -0.012,  0.   ,  0.002,  0.009],
              [ 0.   ,  0.   ,  0.   ,  0.   ,  0.   ],
              [ 0.   , -0.023,  0.   ,  0.005,  0.019],
              [ 0.   , -0.012,  0.   ,  0.002,  0.01 ]])
dWV=np.array([[-0.267,  0.209, -0.267, -0.267,  0.211],
              [-0.064,  0.055, -0.064, -0.064,  0.056],
              [ 0.   ,  0.   ,  0.   ,  0.   ,  0.   ],
              [-0.196,  0.149, -0.196, -0.196,  0.151],
              [-0.098,  0.075, -0.098, -0.098,  0.075]])


# TestSequence
class TestStep(unittest.TestCase):
    @weight(1)
    def test_softmax_size(self):
        O = transformer.softmax(np.array([[0,1,0,0,0],[0,0,1,0,0]]))
        self.assertEqual(O.shape[0], 2, msg='softmax output should have same size as its input!')
        self.assertEqual(O.shape[1], 5, msg='softmax output should have same size as its input!')
        
    @weight(1)
    def test_softmax_with_small_vector_input(self):
        hyp = transformer.softmax(np.array([0,1,0,0,0]))
        ref = np.exp([0,1,0,0,0])/np.sum(np.exp([0,0,1,0,0]))
        self.assertLess(np.average(np.abs(hyp-ref)),0.1,
                        msg='softmax output should be exp(z[j])/sum(exp(z))')
        
    @weight(1)
    def test_softmax_with_small_matrix_input(self):
        hyp = transformer.softmax(np.array([[0,1,0,0,0],[0,0,1,0,0]]))
        ref = np.exp([[0,1,0,0,0],[0,0,1,0,0]])/np.sum(np.exp([0,0,1,0,0]))
        self.assertLess(np.average(np.abs(hyp-ref)),0.1,
                        msg='softmax output should be exp(z[j]) over the row sum of exp(z)')
        
    @weight(1)
    def test_softmax_with_large_input(self):
        hyp = transformer.softmax(np.array([[990,991,990,990,990],[1000,1000,1001,1000,1000]]))
        ref = np.exp([[0,1,0,0,0],[0,0,1,0,0]])/np.sum(np.exp([0,0,1,0,0]))
        self.assertLess(np.average(np.abs(hyp-ref)),0.1,
                        msg='softmax needs to be able to process very large inputs')
        
    @weight(1)
    def test_K_calculation(self):
        A1, C1, K1, O1, Q1, V1 = transformer.forward(XK, XQ, WK, WO, WQ, WV)
        self.assertEqual(K1.shape[0], XK.shape[0], msg='K and XK should have same number of rows')
        self.assertEqual(K1.shape[1], WK.shape[1], msg='K and WK should have same number of columns')
        self.assertLess(np.average(np.abs(K - K1)), 0.1,msg='K is incorrect: see tests/test_visible.py')
        
    @weight(1)
    def test_Q_calculation(self):
        A1, C1, K1, O1, Q1, V1 = transformer.forward(XK, XQ, WK, WO, WQ, WV)
        self.assertEqual(Q1.shape[0], XQ.shape[0], msg='Q and XQ should have same number of rows')
        self.assertEqual(Q1.shape[1], WQ.shape[1], msg='Q and WQ should have same number of columns')
        self.assertLess(np.average(np.abs(Q-Q1)),0.1,'Q is incorrect: see tests/test_visible.py')
        
    @weight(1)
    def test_V_calculation(self):
        A1, C1, K1, O1, Q1, V1 = transformer.forward(XK, XQ, WK, WO, WQ, WV)
        self.assertEqual(V1.shape[0], XK.shape[0], msg='V and XK should have same number of rows')
        self.assertEqual(V1.shape[1], WV.shape[1], msg='V and WV should have same number of columns')
        self.assertLess(np.average(np.abs(V-V1)),0.1,'V is incorrect: see tests/test_visible.py')
        
    @weight(1)
    def test_A_calculation(self):
        A1, C1, K1, O1, Q1, V1 = transformer.forward(XK, XQ, WK, WO, WQ, WV)
        self.assertEqual(A1.shape[0], Q.shape[0], msg='A and Q should have same number of rows')
        self.assertEqual(A1.shape[1], K.shape[0], msg='A and K.T should have same number of columns')
        self.assertLess(np.average(np.abs(A1-A)),0.1,'A is incorrect: see tests/test_visible.py')
    
    @weight(1)
    def test_C_calculation(self):
        A1, C1, K1, O1, Q1, V1 = transformer.forward(XK, XQ, WK, WO, WQ, WV)
        self.assertEqual(C1.shape[0], A.shape[0], msg='C and A should have same number of rows')
        self.assertEqual(C1.shape[1], K.shape[1], msg='C and V should have same number of columns')
        self.assertLess(np.average(np.abs(C1-C)),0.1,'C is incorrect: see tests/test_visible.py')
        
    @weight(1)
    def test_O_calculation(self):
        A1, C1, K1, O1, Q1, V1 = transformer.forward(XK, XQ, WK, WO, WQ, WV)
        self.assertEqual(O1.shape[0], C.shape[0], msg='P and C should have same number of rows')
        self.assertEqual(O1.shape[1], WO.shape[1], msg='P and WO should have same number of columns')
        self.assertLess(np.average(np.abs(O1-O)),0.1,'O is incorrect: see tests/test_visible.py')
                    
    @weight(1)
    def test_loss_calculation(self):
        L1, dO1 = transformer.cross_entropy_loss(O, Y)
        y = np.argmax(Y, axis=1)
        self.assertAlmostEqual(L, -np.log(O[0,y[0]])-np.log(O[1,y[1]]), places=1,
                               msg='loss should be negative log probability of the correct answers')
        
    @weight(1)
    def test_loss_gradient(self):
        L1, dO1 = transformer.cross_entropy_loss(O, Y)
        self.assertEqual(dO1.shape[0], O.shape[0], 'dO and O should have the same shape')
        self.assertEqual(dO1.shape[1], O.shape[1], 'dO and O should have the same shape')
        self.assertLess(np.average(np.abs(dO1-dO)),0.1,'dO is incorrect: see tests/test_visible.py')
        
    @weight(1)
    def test_dWO(self):
        dWK1, dWO1, dWQ1, dWV1 = transformer.gradient(XK, XQ, Y, WK, WO, WQ, WV, A, C, K, O, Q, V)
        self.assertEqual(dWO1.shape[0], WO.shape[0], 'dWO and WO should have same number of rows')
        self.assertEqual(dWO1.shape[1], WO.shape[1], 'dWO and WO should have same number of columns')
        self.assertLess(np.average(np.abs(dWO1-dWO)),0.1,'dWO is incorrect: see tests/test_visible.py')
        
    @weight(1)
    def test_dWV(self):
        dWK1, dWO1, dWQ1, dWV1 = transformer.gradient(XK, XQ, Y, WK, WO, WQ, WV, A, C, K, O, Q, V)
        self.assertEqual(dWV1.shape[0], WV.shape[0], 'dWV and WV should have same number of rows')
        self.assertEqual(dWV1.shape[1], WV.shape[1], 'dWV and WV should have same number of columns')
        self.assertLess(np.average(np.abs(dWV1-dWV)),0.1,'dWV is incorrect: see tests/test_visible.py')

    @weight(1)
    def test_dWQ(self):
        dWK1, dWO1, dWQ1, dWV1 = transformer.gradient(XK, XQ, Y, WK, WO, WQ, WV, A, C, K, O, Q, V)
        self.assertEqual(dWQ1.shape[0], WQ.shape[0], 'dWQ and WQ should have same number of rows')
        self.assertEqual(dWQ1.shape[1], WQ.shape[1], 'dWQ and WQ should have same number of columns')
        self.assertLess(np.average(np.abs(dWQ1-dWQ)),0.1,'dWQ is incorrect: see tests/test_visible.py')

    @weight(1)
    def test_dWK(self):
        dWK1, dWO1, dWQ1, dWV1 = transformer.gradient(XK, XQ, Y, WK, WO, WQ, WV, A, C, K, O, Q, V)
        self.assertEqual(dWK1.shape[0], WK.shape[0], 'dWK and WK should have same number of rows')
        self.assertEqual(dWK1.shape[1], WK.shape[1], 'dWK and WK should have same number of columns')
        self.assertLess(np.average(np.abs(dWK1-dWK)),0.1,'dWK is incorrect: see tests/test_visible.py')

