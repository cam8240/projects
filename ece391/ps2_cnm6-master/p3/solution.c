#include "solution.h"

/*
zombie_enter
Description: Attempts to enter the lab as a zombie, waiting until conditions allow entry without violating lab rules.
Inputs: Takes a pointer to zs_lock representing the lab's current state.
Return Value: Returns 0 on successful entry or -1 on failure.
*/
int zombie_enter(zs_lock* zs) {
    // Immediate lock and increment upon entry to avoid race condition
    spinlock_lock_ece391(&zs->lock);
    zs->waiting_zombies++;
    spinlock_unlock_ece391(&zs->lock);
    
    while (1) {
        spinlock_lock_ece391(&zs->lock);
        // Check conditions for a zombie to enter the lab
        if (zs->num_scientists == 0 && zs->waiting_scientists == 0 && zs->num_zombies < 10) {
            zs->num_zombies++; // A zombie enters the lab
            zs->waiting_zombies--; // Decrement the waiting counter for zombies  
            spinlock_unlock_ece391(&zs->lock);
            return 0; // Success
        }
        spinlock_unlock_ece391(&zs->lock);
    }
    // The loop exits only upon successful entry
    return -1; // Failure, should be unreachable
}


/*
zombie_exit
Description: Marks a zombie's exit from the lab, decreasing the count of zombies present.
Inputs: Takes a pointer to zs_lock representing the lab's current state.
Return Value: Returns 0 on successful exit or -1 if no zombies are present to exit.
*/
int zombie_exit(zs_lock* zs) {
    spinlock_lock_ece391(&zs->lock);
    // Check if there are zombies in the lab to exit
    if (zs->num_zombies > 0) {
        zs->num_zombies--; // Decrement zombies upon exit
        spinlock_unlock_ece391(&zs->lock);
        return 0; // Success
    }
    spinlock_unlock_ece391(&zs->lock);
    return -1;
}


/*
scientist_enter
Description: Attempts to enter the lab as a scientist, waiting until conditions allow entry without violating lab rules.
Inputs: Takes a pointer to zs_lock representing the lab's current state.
Return Value: Returns 0 on successful entry or -1 on failure.
*/
int scientist_enter(zs_lock* zs) {
    // Immediate lock and increment upon entry to avoid race condition
    spinlock_lock_ece391(&zs->lock);
    zs->waiting_scientists++;
    spinlock_unlock_ece391(&zs->lock);

    while (1) {
        spinlock_lock_ece391(&zs->lock);
        // Scientists can enter if there are no zombies in the lab and the number of scientists is below the maximum
        if (zs->num_zombies == 0 && zs->num_scientists < 4) {
            zs->num_scientists++; // A scientist enters the lab
            zs->waiting_scientists--; // Decrement the waiting counter for scientists  
            spinlock_unlock_ece391(&zs->lock);
            return 0; // Success
        }
        spinlock_unlock_ece391(&zs->lock);
    }
    // The loop exits only upon successful entry
    return -1; // Failure, should be unreachable
}


/*
scientist_exit
Description: Marks a scientist's exit from the lab, decreasing the count of scientists present.
Inputs: Takes a pointer to zs_lock representing the lab's current state.
Return Value: Returns 0 on successful exit or -1 if no scientists are present to exit.
*/
int scientist_exit(zs_lock* zs) {
    spinlock_lock_ece391(&zs->lock);
    // Check if there are scientists in the lab to exit
    if (zs->num_scientists > 0) {
        zs->num_scientists--; //Decrement scientists upon exit
        spinlock_unlock_ece391(&zs->lock);
        return 0; // Success
    }
    spinlock_unlock_ece391(&zs->lock);
    return -1;
}
