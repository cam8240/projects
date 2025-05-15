import unittest, submitted
from gradescope_utils.autograder_utils.decorators import weight
import numpy as np

# TestSequence
class TestStep(unittest.TestCase):
    def setUp(self):
        self.reward = np.array([[[-10,2],[-1,1]],[[-10,-1],[2,1]]])
            
    @weight(5)
    def test_utility_gradients_return_value_sizes(self):
        gradients, utilities = submitted.utility_gradients(np.log([9,9]), self.reward)
        self.assertEqual(gradients.shape, (2,), 'gradients should be a length-2 numpy array')
        self.assertEqual(utilities.shape, (2,), 'utilities should be a length-2 numpy array')
        
    @weight(5)
    def test_utility_gradients_at_equilibrium(self):
        gradients, utilities = submitted.utility_gradients(np.log([9,9]), self.reward)
        self.assertAlmostEqual(gradients[0], 0.00, 1, 'gradients should be 0 at equilibrium')
        self.assertAlmostEqual(gradients[1], 0.00, 1, 'gradients should be 0 at equilibrium')
        self.assertAlmostEqual(utilities[0], 0.8, 1, 'utilities should be 0.8 at chicken equilibrium')
        self.assertAlmostEqual(utilities[1], 0.8, 1, 'utilities should be 0.8 at chicken equilibrium')
        
    @weight(5)
    def test_utility_gradients_off_equilibrium(self):
        gradients, utilities = submitted.utility_gradients(np.log([10,9]), self.reward)
        self.assertLess(gradients[1], 0.00, 'A above equilibrium should give B negative gradient')
        gradients, utilities = submitted.utility_gradients(np.log([9,8]), self.reward)
        self.assertGreater(gradients[0], 0.00, 'B below equilibrium should give A positive gradient')
        gradients, utilities = submitted.utility_gradients(np.log([9,10]), self.reward)
        self.assertLess(gradients[0], 0.00, 'B above equilibrium should give A negative gradient')
        gradients, utilities = submitted.utility_gradients(np.log([8,9]), self.reward)
        self.assertGreater(gradients[1], 0.00, 'A below equilibrium should give B positive gradient')

    @weight(5)
    def test_strategy_gradient_ascent_return_value_sizes(self):
        path, utilities = submitted.strategy_gradient_ascent(np.log([9,9]), self.reward, 1000, 0.1)
        self.assertEqual(path.shape, (1000,2), 'path should be an nsteps-by-2 numpy array')
        self.assertEqual(utilities.shape, (1000,2), 'utilities should be an nsteps-by-2 numpy array')
                
    @weight(5)
    def test_strategy_gradient_ascent_from_equilibrium(self):
        path, utilities = submitted.strategy_gradient_ascent(np.log([9,9]), self.reward, 1000, 0.1)
        self.assertAlmostEqual(path[-1,0], np.log(9), 1, 'ascent from equilibrium should not move')
        self.assertAlmostEqual(path[-1,1], np.log(9), 1, 'ascent from equilibrium should not move')
        
    @weight(5)
    def test_strategy_gradient_ascent_from_nonequilibrium(self):
        path, utilities = submitted.strategy_gradient_ascent(np.log([10,9]), self.reward, 1000, 0.1)
        self.assertGreater(path[-1,0], 3, 'A above equilibrium should converge to positive A logit')
        self.assertLess(path[-1,1], -3, 'A above equilibrium should converge to negative B logit')
        path, utilities = submitted.strategy_gradient_ascent(np.log([9,8]), self.reward, 1000, 0.1)
        self.assertGreater(path[-1,0], 3, 'B below equilibrium should converge to positive A logit')
        self.assertLess(path[-1,1], -3, 'B below equilibrium should converge to negative B logit')
        path, utilities = submitted.strategy_gradient_ascent(np.log([9,10]), self.reward, 1000, 0.1)
        self.assertLess(path[-1,0], -3, 'B above equilibrium should converge to negative A logit')
        self.assertGreater(path[-1,1], 3, 'B above equilibrium should converge to positive B logit')
        path, utilities = submitted.strategy_gradient_ascent(np.log([8,9]), self.reward, 1000, 0.1)
        self.assertLess(path[-1,0], -3, 'A below equilibrium should converge to negative A logit')
        self.assertGreater(path[-1,1], 3, 'A below equilibrium should converge to positive B logit')
        
    @weight(5)
    def test_mechanism_gradient_at_equilibrium(self):
        gradient, loss = submitted.mechanism_gradient(np.log([9,9]), self.reward)
        self.assertAlmostEqual(loss, 0.0, places=1, msg='loss should be 0 at equilibrium')
        for i in range(2):
            for a in range(2):
                for b in range(2):
                    self.assertAlmostEqual(gradient[i,a,b],0.0, places=1,
                                           msg='gradient[%d,%d,%d] should be zero'%(i,a,b))

        
    @weight(5)
    def test_mechanism_gradient_off_equilibrium(self):
        gradient, loss = submitted.mechanism_gradient(np.log([8,8]), self.reward)
        self.assertGreater(loss, 0, 'off equilibrium, loss should be positive')
        for b in range(2):
            self.assertLess(gradient[0,0,b],0,'gradient[0,0,%d] should be negative'%(b))
            self.assertGreater(gradient[0,1,b],0,'gradient[0,1,%d] should be positive'%(b))
            self.assertLess(gradient[1,b,0],0,'gradient[1,%d,0] should be negative'%(b))
            self.assertGreater(gradient[1,b,1],0,'gradient[1,%d,1] should be positive'%(b))
            
    @weight(5)
    def test_mechanism_gradient_descent_from_equilibrium(self):
        path, loss = submitted.mechanism_gradient_descent(np.log([9,9]), self.reward, 1000, 0.1)
        self.assertAlmostEqual(loss[-1], 0.0, places=1, msg='loss should converge to 0')
        for i in range(2):
            for a in range(2):
                for b in range(2):
                    self.assertAlmostEqual(path[-1,i,a,b],self.reward[i,a,b], places=1,
                                           msg='path should not change if target=equilibrium')

        
    @weight(5)
    def test_mechanism_gradient_descent_from_off_equilibrium(self):
        path, loss = submitted.mechanism_gradient_descent(np.log([8,8]), self.reward, 1000, 0.1)
        self.assertAlmostEqual(loss[-1], 0.0, places=1, msg='loss should converge to 0')
        g, u = submitted.utility_gradients(np.log([8,8]), path[-1,:,:,:])
        self.assertAlmostEqual(g[0], 0.0, places=1, msg='after convergence, gradient should be 0')
        self.assertAlmostEqual(g[1], 0.0, places=1, msg='after convergence, gradient should be 0')
