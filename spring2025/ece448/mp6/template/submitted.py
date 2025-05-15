'''
This is the module you'll submit to the autograder.

There are several function definitions, here, that raise RuntimeErrors.  You should replace
each "raise RuntimeError" line with a line that performs the function specified in the
function's docstring.
'''
import numpy as np

epsilon = 1e-3

def compute_transition(model):
    '''
    Parameters:
    model - the MDP model returned by load_MDP()

    Output:
    P - An M x N x 4 x M x N numpy array. P[r, c, a, r', c'] is the probability that the agent will move from cell (r, c) to (r', c') if it takes action a, where a is 0 (left), 1 (up), 2 (right), or 3 (down).
    '''

    M, N = model.M, model.N
    P = np.zeros((M, N, 4, M, N))

    left_turn = {0: 3, 1: 0, 2: 1, 3: 2}
    right_turn = {0: 1, 1: 2, 2: 3, 3: 0}

    action_deltas_val = [(0, -1), (-1, 0), (0, 1), (1, 0)]
    
    for r in range(M):
        for c in range(N):
            if model.TS[r, c]:
                continue
            
            for a in range(4):
                prob_intended = model.D[r, c, 0]
                prob_left = model.D[r, c, 1]
                prob_right = model.D[r, c, 2]
                
                dr, dc = action_deltas_val[a]
                r_new, c_new = r + dr, c + dc
                if r_new < 0 or c_new < 0 or r_new >= M or c_new >= N or model.W[r_new, c_new]:
                    r_new, c_new = r, c
                P[r, c, a, r_new, c_new] += prob_intended
                
                a_right = right_turn[a]
                dr, dc = action_deltas_val[a_right]
                r_new, c_new = r + dr, c + dc
                if r_new < 0 or c_new < 0 or r_new >= M or c_new >= N or model.W[r_new, c_new]:
                    r_new, c_new = r, c
                P[r, c, a, r_new, c_new] += prob_right

                a_left = left_turn[a]
                dr, dc = action_deltas_val[a_left]
                r_new, c_new = r + dr, c + dc
                if r_new < 0 or c_new < 0 or r_new >= M or c_new >= N or model.W[r_new, c_new]:
                    r_new, c_new = r, c
                P[r, c, a, r_new, c_new] += prob_left

    return P

def compute_utility(model, u_cur_val, P):
    '''
    Parameters:
    model - The MDP model returned by load_MDP()
    u_cur_val - The current utility function, which is an M x N array
    P - The precomputed transition matrix returned by compute_transition()

    Output:
    u_next_val - The updated utility function, which is an M x N array
    '''

    M, N = model.M, model.N
    u_next_val = np.zeros((M, N))

    for r in range(M):
        for c in range(N):
            if model.TS[r, c]:
                u_next_val[r, c] = model.R[r, c]
            else:
                action_vals = []
                for a in range(4):
                    expected_val = np.sum(P[r, c, a] * u_cur_val)
                    action_vals.append(expected_val)
                u_next_val[r, c] = model.R[r, c] + model.gamma * max(action_vals)
    return u_next_val

def value_iterate(model):
    '''
    Parameters:
    model - The MDP model returned by load_MDP()

    Output:
    U - The utility function, which is an M x N array
    '''

    P = compute_transition(model)
    M, N = model.M, model.N
    u_cur_val = np.zeros((M, N))
    for _ in range(1000):
        u_next_val = compute_utility(model, u_cur_val, P)
        if epsilon > np.max(np.abs(u_next_val - u_cur_val)):
            return u_next_val
        u_cur_val = u_next_val
    return u_cur_val

def policy_evaluation(model):
    '''
    Parameters:
    model - The MDP model returned by load_MDP();
    
    Output:
    U - The converged utility function, which is an M x N array
    '''

    M, N = model.M, model.N
    u_cur_val = np.zeros((M, N))
    for _ in range(1000):
        u_next_val = np.zeros((M, N))
        for r in range(M):
            for c in range(N):
                if model.TS[r, c]:
                    u_next_val[r, c] = model.R[r, c]
                else:
                    u_next_val[r, c] = model.R[r, c] + model.gamma * np.sum(model.FP[r, c] * u_cur_val)
        if epsilon > np.max(np.abs(u_next_val - u_cur_val)):
            return u_next_val
        u_cur_val = u_next_val
    return u_cur_val
