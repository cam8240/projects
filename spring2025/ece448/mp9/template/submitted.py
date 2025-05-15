'''
Replace each RuntimeError with code that does what's
specified in the docstring, then submit to autograder.
'''
import numpy as np

def utility_gradients(logit, reward):
    '''
    Calculate partial derivatives of expected rewards with respect to logits.

    @param:
    logit - player i plays move 1 with probability 1/(1+exp(-logit[i]))
    reward - reward[i,a,b] is reward to player i if player 0 plays a, and player 1 plays b

    @return:
    gradients - gradients[i]= dE[reward[i,:,:]]/dlogit[i]
    utilities - utilities[i] = E[reward[i,:,:]]
      where the expectation is computed over the distribution of possible moves by both players.
    '''
    logit = np.array(logit, dtype=float)
    reward = np.array(reward, dtype=float)

    p = 1/(1+np.exp(-logit))
    pA = np.array([1-p[0], p[0]])
    pB = np.array([1-p[1], p[1]])

    utilities = np.zeros(2)
    gradients = np.zeros(2)
    utilities[0] = pA @ reward[0] @ pB

    u0_defect = reward[0,0] @ pB
    u0_coop   = reward[0,1] @ pB
    d0 = p[0]*(1-p[0])

    gradients[0] = d0*(u0_coop - u0_defect)
    utilities[1] = pA @ reward[1] @ pB

    u1_defect = pA @ reward[1,:,0]
    u1_coop   = pA @ reward[1,:,1]
    d1 = p[1]*(1-p[1])
    gradients[1] = d1*(u1_coop - u1_defect)

    return gradients, utilities

def strategy_gradient_ascent(logit, reward, nsteps, learningrate):
    '''
    nsteps of a 2-player, 2-action episodic game, strategies learned
    using simultaneous gradient ascent.

    @param:
    logit - intial logits for the two players
    reward - reward[i,a,b] is reward to player i if player 0 plays a, and player 1 plays b
    nsteps - number of steps of ascent to perform
    learningrate - learning rate

    @return:
    path - path[t,i] is the logit of the i'th player's strategy after t steps of
      simultaneous gradient ascent (path[0,:]==logit).
    utilities (nsteps,2) - utilities[t,i] is the expected reward to player i on step t,
      where expectation is over the distribution of moves given by logits[t,:]
    '''
    logit = np.array(logit, dtype=float)
    path = np.zeros((nsteps, 2))
    utilities = np.zeros((nsteps, 2))

    for t in range(nsteps):
        path[t] = logit
        gradients, util = utility_gradients(logit, reward)
        utilities[t] = util
        logit = logit + learningrate * gradients
    return path, utilities

    

def mechanism_gradient(logit, reward):
    '''
    Calculate partial derivative of mechanism loss with respect to rewards.

    @param:
    logit - The goal is to make this pair of strategies a Nash equlibrium:
        player i plays move 1 with probability 1/(1+exp(-logit[i])), else move 0
    reward - reward[i,a,b] is reward to player i if player 0 plays a, and player 1 plays b

    @return:
    gradient - gradient[i,a,b]= derivative of loss w.r.t. reward[i,a,b]
    loss - half of the mean-squared strategy mismatch.
        Mean = average across both players.
        Strategy mismatch = difference between the expected reward that
        the player earns by cooperating (move 1) minus the expected reward that
        they earn by defecting (move 0).
    '''
    logit = np.array(logit, dtype=float)
    reward = np.array(reward, dtype=float)

    p = 1/(1+np.exp(-logit))
    pA = np.array([1-p[0], p[0]])
    pB = np.array([1-p[1], p[1]])

    u0_defect = reward[0,0] @ pB
    u0_coop   = reward[0,1] @ pB
    mismatch0 = u0_coop - u0_defect
    u1_defect = pA @ reward[1,:,0]
    u1_coop   = pA @ reward[1,:,1]

    mismatch1 = u1_coop - u1_defect
    loss = 0.5 * (mismatch0**2 + mismatch1**2)
    gradient = np.zeros_like(reward)

    gradient[0,1,:] = mismatch0 * pB
    gradient[0,0,:] = -mismatch0 * pB
    gradient[1,:,1] = mismatch1 * pA
    gradient[1,:,0] = -mismatch1 * pA

    return gradient, loss

def mechanism_gradient_descent(logit, reward, nsteps, learningrate):
    '''
    nsteps of gradient descent on the mean-squared strategy mismatch
    using simultaneous gradient ascent.

    @param:
    logit - The goal is to make this pair of strategies a Nash equlibrium:
        player i plays move 1 with probability 1/(1+exp(-logit[i])), else move 0.
    reward - Initial setting of the rewards.
        reward[i,a,b] is reward to player i if player 0 plays a, and player 1 plays b
    nsteps - number of steps of gradient descent to perform
    learningrate - learning rate

    @return:
    path - path[t,i,a,b] is the reward to player i of the moves (a,b) after t steps 
      of gradient descent (path[0,:,:,:] = initial reward).
    loss - loss[t] is half of the mean-squared strategy mismatch at iteration [t].
        Mean = average across both players.
        Strategy mismatch = difference between the expected reward that
        the player earns by cooperating (move 1) minus the expected reward that
        they earn by defecting (move 0).
    '''
    logit = np.array(logit, dtype=float)
    path = np.zeros((nsteps,)+reward.shape)
    loss = np.zeros(nsteps)
    reward_current = np.array(reward, dtype=float)
    
    for t in range(nsteps):
        path[t] = reward_current
        grad, loss_t = mechanism_gradient(logit, reward_current)
        loss[t] = loss_t
        reward_current = reward_current - learningrate * grad
    return path, loss

    
