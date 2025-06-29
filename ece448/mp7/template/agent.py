import numpy as np
import utils


class Agent:
    def __init__(self, actions, Ne=40, C=40, gamma=0.7, display_width=18, display_height=10):
        # HINT: You should be utilizing all of these
        self.actions = actions
        self.Ne = Ne  # used in exploration function
        self.C = C
        self.gamma = gamma
        self.display_width = display_width
        self.display_height = display_height
        self.reset()
        # Create the Q Table to work with
        self.Q = utils.create_q_table()
        self.N = utils.create_q_table()
        
    def train(self):
        self._train = True
        
    def eval(self):
        self._train = False

    # At the end of training save the trained model
    def save_model(self, model_path):
        utils.save(model_path, self.Q)
        utils.save(model_path.replace('.npy', '_N.npy'), self.N)

    # Load the trained model for evaluation
    def load_model(self, model_path):
        self.Q = utils.load(model_path)

    def reset(self):
        # HINT: These variables should be used for bookkeeping to store information across time-steps
        # For example, how do we know when a food pellet has been eaten if all we get from the environment
        # is the current number of points? In addition, Q-updates requires knowledge of the previously taken
        # state and action, in addition to the current state from the environment. Use these variables
        # to store this kind of information.
        self.points = 0
        self.s = None
        self.a = None
    
    def update_n(self, state, action):
        # TODO - MP11: Update the N-table. 
        self.N[state][action] += 1

    def update_q(self, s, a, r, s_prime):
        # TODO - MP11: Update the Q-table. 
        if s is None or a is None:
            return
        alpha = self.C / (self.C + self.N[s][a])
        max_q_s_prime = np.max(self.Q[s_prime])
        self.Q[s][a] += alpha * (r + self.gamma * max_q_s_prime - self.Q[s][a])    


    def act(self, environment, points, dead):
        '''
        :param environment: a list of [snake_head_x, snake_head_y, snake_body, food_x, food_y, rock_x, rock_y] to be converted to a state.
        All of these are just numbers, except for snake_body, which is a list of (x,y) positions 
        :param points: float, the current points from environment
        :param dead: boolean, if the snake is dead
        :return: chosen action between utils.UP, utils.DOWN, utils.LEFT, utils.RIGHT

        Tip: you need to discretize the environment to the state space defined on the webpage first
        (Note that [adjoining_wall_x=0, adjoining_wall_y=0] is also the case when snake runs out of the playable board)
        '''
        s_prime = self.generate_state(environment)

        # TODO - MP12: write your function here

        return utils.RIGHT

    def generate_state(self, environment):
        '''
        :param environment: a list of [snake_head_x, snake_head_y, snake_body, food_x, food_y, rock_x, rock_y] to be converted to a state.
        All of these are just numbers, except for snake_body, which is a list of (x,y) positions 
        '''
        # TODO - MP11: Implement this helper function that generates a state given an environment 

        head_x, head_y, body, food_x, food_y, rock_x, rock_y = environment

        food_dir_x = 1 if food_x < head_x else 2 if food_x > head_x else 0
        food_dir_y = 1 if food_y < head_y else 2 if food_y > head_y else 0

        left_blocked = (head_x - 1 <= 0) or \
                    ((rock_x == head_x - 1 or rock_x + 1 == head_x - 1) and rock_y == head_y)

        right_blocked = (head_x + 1 >= self.display_width - 1) or \
                        ((rock_x == head_x + 1 or rock_x + 1 == head_x + 1) and rock_y == head_y)

        if left_blocked and right_blocked:
            adjoining_wall_x = 1
        elif left_blocked:
            adjoining_wall_x = 1
        elif right_blocked:
            adjoining_wall_x = 2
        else:
            adjoining_wall_x = 0

        top_blocked = (head_y - 1 <= 0) or ((rock_y == head_y - 1) and (rock_x == head_x or rock_x + 1 == head_x))
        bottom_blocked = (head_y + 1 >= self.display_height - 1) or (rock_y == head_y + 1 and rock_x == head_x)

        if top_blocked and bottom_blocked:
            adjoining_wall_y = 1
        elif top_blocked:
            adjoining_wall_y = 1
        elif bottom_blocked:
            adjoining_wall_y = 2
        else:
            adjoining_wall_y = 0

        adjoining_body_top = 1 if (head_x, head_y - 1) in body else 0
        adjoining_body_bottom = 1 if (head_x, head_y + 1) in body else 0
        adjoining_body_left = 1 if (head_x - 1, head_y) in body else 0
        adjoining_body_right = 1 if (head_x + 1, head_y) in body else 0

        return (
            food_dir_x,
            food_dir_y,
            adjoining_wall_x,
            adjoining_wall_y,
            adjoining_body_top,
            adjoining_body_bottom,
            adjoining_body_left,
            adjoining_body_right
            )