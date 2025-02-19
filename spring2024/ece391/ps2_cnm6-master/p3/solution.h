#ifndef SOLUTION_H
#define SOLUTION_H
#include "spinlock_ece391.h"

// You may add up to 5 elements to this struct.
// The type of synchronization primitive you may use is SpinLock.
typedef struct zs_enter_exit_lock{
    spinlock_t lock; //Lock variable
    volatile unsigned int num_scientists; //0-4 scientists in lab
    volatile unsigned int num_zombies; //0-10 zombies in lab
    volatile unsigned int waiting_scientists; //0-infinity scientists can be waiting
    volatile unsigned int waiting_zombies; //0-infinity scientists can be waiting 
}zs_lock;


int zombie_enter(zs_lock* zs);

int zombie_exit(zs_lock* zs);

int scientist_enter(zs_lock* zs);

int scientist_exit(zs_lock* zs);



#endif /* SOLUTION_H */
