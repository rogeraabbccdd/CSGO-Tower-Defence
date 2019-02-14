#if defined _Defence_included
 #endinput
#endif
#define _Defence_included

/**
 * Add new enemy type.
 *
 * @param name	Name of the enemy.
 * @return	True if successfully added.
 */
native bool Defence_AddEnemyType(char [] name);

/**
 * Called when an enemy spawn.
 *
 * @param name	Name of the enemy.
 * @param ent 	client index of the enemy.
 * @return	No return
 */
forward Action Defence_OnEnemySpawn(char [] name, int enemy);