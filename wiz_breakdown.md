Step by step - 


This plan focuses on a **Vertical Slice** approach. The goal is to first build the absolute minimum "trunk" of the game (one player, one spell, one level-up) and then add features ("branches") until it's complete. This ensures you have a playable, testable game at every stage.

---

### Phase 1: 🏗️ Project Foundation & Core Architecture

This phase is about setting up the "empty rooms" and the rules that connect them, based on your "Core Gameplay Loop" and "Coding Standards" documents.

1.  **Initialize Project:**
    * Create the Roblox Place.
    * Implement the `Developer Coding Standards` from the start.

2.  **Create Game States:**
    * Build a main server-side **`GameManager`** module.
    * This module will manage the two global game states: `Intermission` and `MatchInProgress`.
    * It will also handle the main game timer (e.g., the 6-minute match timer).

3.  **Build the Two "Worlds":**
    * **The 3D Lobby:** Create the small, persistent 3D lobby map where all players first spawn.
    * **The Arena:** Create the separate, 1500x1500 stud arena map. For now, it can be a simple, flat baseplate.

4.  **Implement Basic Player Spawning:**
    * On `PlayerAdded`, spawn the player into the **3D Lobby**.
    * Create the core `GameManager` logic:
        * When the `Intermission` timer ends, teleport all queued players from the Lobby to the Arena.
        * When a player "dies" in the Arena, teleport them *back* to the Lobby.

---

### Phase 2: 🎮 The "Vertical Slice" (Core Gameplay)

This is the most critical phase. The goal is a **playable-but-simple** loop. Can one player join, level up, change their spell, and fight?

1.  **Player Stats & Leveling:**
    * Create a `PlayerData` module. On the server, track each player's **Health** (1000), **Level** (1), **XP** (0), `SpellCore` (e.g., `{}`), and `Buffs` (e.g., `{}`).
    * Create the **Mana Crystal** pickup (5 XP). When a player touches it, destroy it and add XP.
    * Implement the XP-to-Level curve. When a player's XP hits a threshold (e.g., 100 XP), set their Level to 2.

2.  **Basic Combat & Controls:**
    * Implement the mobile-first controls: Left joystick (movement) and Right "Shoot" button.
    * Create a `SpellModule`. When the player hits "Shoot," have the server fire a basic "Magic Missile" projectile (Level 1 spell) in the direction the character is facing.
    * Make the projectile apply damage. When a player's Health reaches 0, trigger the "elimination" logic (teleport back to lobby).

3.  **The Spell Evolution MVP:**
    * This is the *true* core loop.
    * **Even Levels:** When a player hits Level 2, have the server fire a `LevelUpChoiceSC` RemoteEvent.
    * **UI:** The client listens for this event and shows the Level Up UI with three choices: "Fire," "Water," and "Earth."
    * **Client-to-Server:** The player clicks "Fire," and the client fires a `LevelUpChoiceCS` RemoteEvent back with their choice.
    * **Server:** The server validates this choice, adds "Fire" to the player's `SpellCore` list (`{"Fire"}`), and tells the `SpellModule` to *change* this player's spell.
    * **Test:** The player's "Magic Missile" should now be **`Fire Ball`** (Level 2 spell).
    * **Odd Levels:** Repeat the process for Level 3, this time showing three random buffs (e.g., "+10% Max HP").

> **Vertical Slice Complete:** At the end of this phase, a player can join, run around, collect Mana, level up, choose "Fire," level up again, choose "+HP," and their spell is now a `Fire Ball` and they have more health. You have a game.

---

### Phase 3: 🗺️ Building the Battle Royale

Now, expand the "empty room" into the full game experience. This phase is about the Arena, the Storm, and the loot.

1.  **Build the Arena:**
    * Flesh out the 1500x1500 stud map with obstacles, trees, rocks, and buildings as described.
    * Implement the "fair" **Player Spawning** logic: all 20 players spawn inside the Phase 1 zone, 150 studs apart.

2.  **Implement the Storm:**
    * Create a `StormManager` on the server.
    * Using the 6-minute timer, program the exact 4-phase storm from your GDD (wait times, shrink times, damage per tick).
    * This system will control the "Safe Zone" and apply damage to players outside of it.

3.  **Implement Loot & Economy:**
    * Add **Chests** to the map.
    * When opened, make them drop `250 XP` (in crystals), 1 `Health Orb`, and a 25% chance of 1-3 `Gems`.
    * Code the `Health Orb` pickup (instantly heals 150 HP).
    * Code the `Gem` pickup (a temporary, in-match item).
    * Implement player "death" drops: they drop all held `Gems` and 2 `Health Orbs`.

---

### Phase 4: ✨ Content Expansion (The "Fun" Stuff)

The game works, but it's simple. This phase is about adding all the content that creates variety and "juice."

1.  **Full Spell System (The Big One):**
    * Systematically code all **20 spell combinations** from your list.
    * This will require a robust, data-driven `SpellModule` that can look at a `SpellCore` (e.g., `{"Fire", "Fire", "Water"}`) and know to execute the `Storm Front` spell with the correct stats.
    * Create all **20 unique Spell VFX** (visual effects). This is *critical* for game feel.

2.  **Full Buff System:**
    * Implement all the real passive buffs (`Rapid Cast`, `Velocity`, `Fortitude`, etc.).
    * This involves modifying the combat and player scripts to *read* from the player's `Buffs` list (e.g., `SpellModule` checks for `Rapid Cast` to reduce the cooldown).
    * Create all the UI icons for these buffs.

3.  **Heroes & Abilities:**
    * Create the "Novice" (default hero, no ability).
    * Code the Hero Ability ("Q") system (button, cooldown).
    * Implement the first 3 Heroes: **Kaelen** (Dash), **Terra** (Bulwark), and **Aquo** (Soothing Pool) along with their unique passives.

4.  **"Juice" (Audio & Visual Feedback):**
    * Implement *all* items from your "Game Feel" and "Audio" documents.
    * **Audio:** Add SFX for all 20 spells (cast, impact), UI clicks, level-ups, pickups, and the storm. Add the Lobby and Tension music.
    * **Visuals:** Add hit flashes, damage numbers, kill feedback (loot explosions), and level-up VFX.

---

### Phase 5: 🏆 The Metagame & Monetization

The *in-match* game is complete. Now, build the *out-of-match* loop that keeps players coming back.

1.  **Data Persistence:**
    * Use `DataStoreService` to save player data.
    * You need to save: **Coins**, **Gems**, **Unlocked Heroes**, and **Unlocked Cosmetics**.

2.  **Implement 3D Lobby Stations:**
    * Build the full 3D Lobby UI flow.
    * **Hall of Heroes:** Create the UI to select your hero.
    * **Collector's Vault:** Build the Shop UI.
    * **Tome of Legends:** Build the Battle Pass UI (even if the pass isn't implemented yet).

3.  **Economy & Post-Game:**
    * Implement the **Post-Match Summary** screen. When a player is teleported back to the lobby, show this UI.
    * Calculate their **Coin Reward** (Placement + Kills).
    * "Bank" any `Gems` they were holding.
    * Save these new currency values to their DataStore.

4.  **Monetization & Shop:**
    * Implement the **Hero Unlock** system (3,000 Coins or 250 Gems).
    * Integrate `MarketplaceService` to sell **Gems for Robux**.
    * Implement the **Cosmetics Chest** (50 Gems) and the cosmetic item-equipping system.

---

### Phase 6: 🚀 Polish, Testing & Launch

The game is now "feature complete." The final step is to make it stable, balanced, and ready for players.

1.  **Spectator Mode:**
    * Implement the "View Stand" spectator system. This is a complex but cool feature that will need its own logic for teleporting players and feeding them live game data.

2.  **Onboarding:**
    * Create a simple tutorial to explain the core loop: "Move," "Shoot," "Collect Mana," "Level Up."



### Game Concept

**High-Level Concept:** A Roblox mobile-first, half top-down(fixed-angle isometric view (like League of Legends)), magic-themed Battle Royale where players fight in a shrinking arena Players evolve a single, powerful spell by combining elements at level-up, and use unique hero abilities to be the last one standing. The last player standing wins.

### Core Gameplay Loop

1.  **Queue & Join:** The player solo enters a queue to join from 1 up to 20 solo-player main live lobby match.
2.  **Match Start:** All players spawn at random locations on the map, starting at Level 1 with their Hero's basic spell.
3.  **Scavenge & Fight:** Players move around the map to collect Mana(XP), find chests containing Mana(XP) and gems, and engage in combat with other players.
4.  **Survive & Level Up:** By defeating other players and collecting resources, the player levels up, increasing their health and power depending on what is picked from the choices. The arena shrinks over time, forcing players into a smaller and smaller area by a storm.

Even Levels exluding 8 (2, 4, 6...): Players choose 1 of 3 Elemental Essences (Fire, Water, or Earth) to add to their spell.

Odd Levels and 8, 9 (3, 5, 7...): Players choose 1 of 3 Passive Buffs (e.g., -Cooldown, +Projectile Speed).

The player's main spell automatically evolves based on the combination of Elements they've collected (as per your spell list). The arena shrinks, forcing combat.

5.  **Victory or Defeat:** The player fights to be the last one alive.
6.  **Return to Lobby:** After the match, the player receives rewards (gems, coins) based on their performance (placement, number of kills).
7.  **Metagame Progression:** In the lobby, the player uses the earned currency to unlock new playable characters customizations like wands, upgrade existing ones, or purchase cosmetic items like skins and wands.

---

### Detailed Game Systems & Rules

#### 1. Player & Controls

*   **Movement:** Controlled by a virtual joystick on the left side of the screen. The character moves in the direction the joystick is pushed. Virtual joystick (left screen) or WASD (desktop).
*   **Health (HP):** A finite amount of health. When it reaches zero, the player is eliminated from the match.
*   **Leveling:** Players start at Level 1. By collecting mana crystals scattered on the ground or dropped by defeated enemies or in chests, they gain XP. Reaching XP thresholds levels them up, which give them 3 options depending what level they reach for even number of levels such 2,4,6... they get the choices of water, fire and earth but for odd number of levels such 3,5,7... they get the choices of buffs like +projectile speed, +projectile speed, increases max HP and other boosts of other stats.

Players start at Level 1. Max level is 10.

Collecting Mana Crystals (from the ground, chests, or defeated players) grants XP.

Even Levels (2, 4, 6): The player is presented with a choice of 3 Elemental Essences: Fire, Water, or Earth. Their choice is added to their "Spell Core."

Odd Levels (3, 5, 7, 8, 9): The player is presented with a choice of 3 random Passive Buffs (e.g., +10% Max HP, -5% Spell Cooldown, +10% Projectile Speed, +15% Pickup Range, +5% Movement Speed).

Level 10 (Max): Provides a choice of 3 ultimate buffs (e.g., +25% All Damage, Heal 5% HP on Kill, Reset Ability Cooldowns on Kill).

#### 2. Spells & Combat

*   **Starting Spell:** Players have one main spell slot.
Choosing an Elemental Essence at an even level (e.g., "Fire") permanently evolves the spell in that slot (e.g., Magic Missile -> Fire Ball).

Choosing another element (e.g., "Fire" again) evolves it further (Fire Ball -> Explosive Salvo).
when the shoot button on the right side of the mobile screen opposite the joystick is pressed it then the spell fires in the direction of where the player is facing.
*   **Acquiring Spells:**
    *   Bulk mana crystals are found in chests scattered across the map.
    *   When a player opens a chest, mana crystals is thrown around in range of the chest. They can pick them up and level up and when certain xp threshold is met they are presented with choices of 3 options depending what level they reach for even number of levels such 2,4,6... they get the choices of water, fire and earth but for odd number of levels such 3,5,7... they get the choices of buffs like +projectile speed, +projectile speed, increases max HP and other boosts of other stats. 
    * Spells combine with the current one they have and evolve their spell(e.g., fire spell and water spell combined make up lighting ball, etc.).
    *   Players have a limited number of 1 spell slots.

    *   **Targeting:** Spells are aimed using where the character is facing, triggered using a button on the right side of the screen. The spell is cast when the player releases the Shoot button.
    
    Spells are fired from a "Shoot" button on the right side of the screen, launching in the direction the character is currently facing.
    *   **Cooldowns:** Each spell has a cooldown period after being used before it can be cast again. the default cooldown is 4 seconds for all spells This is a critical balancing mechanic (its one of options player can choose to buff when they level up). 
    *   **Variety:** Spells are the core of the game's variety and strategy. They fall into several categories:
        *   **Projectiles:** Fireballs, ice shards, poison bolts. Can be single-shot, multi-shot, or piercing.
        *   **Area of Effect (AoE):** Meteors, blizzards, toxic clouds that affect a specific area.
        *   **Melee/Close Range:** Magic swords, spinning scythes, or pushback waves that damage and repel nearby enemies.
*   **Hero Ability:** Each Hero has a unique "Q" ability (e.g., Dash, Shield) on a separate cooldown, controlled by a smaller button near the "Shoot" button.
Shields that block damage, temporary invisibility, or healing spells, etc.
*   **Spell Fusion (Advanced Mechanic):** core loop, leveling system, and spell list are all built around evolving a single spell by adding elements (e.g., Fire -> Fire+Fire -> Fire+Fire+Water).

#### 3. The Arena (Map)


These rules assume a square map size of approximately **1500 x 1500 studs**.

#### 🗺️ Storm Stages & Pacing (6-Minute Match)

| Phase | Total Duration | Wait Time | Shrink Time | Storm Damage (per sec) | Safe Zone Radius |
| :--- | :--- | :--- | :--- | :--- | :--- |
| **Phase 1** (Start) | 1:00 (60s) | 60s | --- | 1% (Safe) | 600 studs |
| **Phase 2** (Early) | 1:45 (105s) | 30s | 90s | 2.5% (20 HP) | 300 studs |
| **Phase 3** (Mid) | 1:30 (90s) | 15s | 75s | 5% (50 HP) | 100 studs |
| **Phase 4** (End) | 1:30 (90s) | 15s | 75s | 7.50% (100 HP) | 25 studs |
| **Total Time:** | **5:45** | | | | (Final circle closes to 0) |

**Detailed Breakdown:**

* **0:00 - 1:00 (Phase 1):** The match begins. The map is safe. At 1:00, the **Phase 1 Safe Zone** (600 stud radius) and the **Phase 2 Safe Zone** (300 stud radius) both appear. The storm begins to close in from the *edge of the map* towards the Phase 1 zone.
* **1:00 - 2:45 (Phase 2):** Players have 35s to see the next circle, then 90s to get inside the 300-stud radius. The storm closes from the Phase 1 radius to the Phase 2 radius, dealing **2.5% HP/sec**.
* **2:45 - 4:15 (Phase 3):** After a 15s wait, the storm closes from 300 studs to 100 studs over 75s. Damage is now a serious threat at **5% HP/sec**.
* **4:15 - 5:45 (Phase 4):** The final phase. After a 15s wait, the storm closes from 100 studs to 25 studs. Damage is lethal at **7.5% HP/sec**, forcing the final 1v1. After 5:45, the circle closes completely.

---

### 2. Player Spawning

To ensure fairness and a good start, all 20 players will be spawned according to these rules:

1.  **Spawn Inside:** All players **must** spawn inside the **Phase 1 Safe Zone** (the 600-stud radius circle).
2.  **Spawn Apart:** A spawn location is only valid if it is at least **150 studs** away from all other players. This prevents players from seeing each other or being able to attack immediately on spawning.
3.  **Spawn Safe:** The spawn system will raycast downwards from a random point. A spawn is only valid if it lands on "safe" ground (e.g., grass, rock, dirt). Spawns that land on "hazard" terrain (like water, lava, or inside a building) will be re-rolled.

This ensures all players have a fair start and a few seconds to find their bearings before seeking out a chest.

*   **Shrinking Zone:** A classic Battle Royale feature. A damaging "storm" or magical barrier slowly closes in from the edges of the map at set intervals. Players caught outside the safe zone take continuous damage. This forces confrontation and brings the game to a conclusion.
*   **Environment:**
    *   **Obstacles:** Trees, rocks, walls, and buildings that block movement and projectiles, providing cover. Some obstacles may be destructible.
    *   **Chests:** Spawn at set locations, dropping Mana (XP), a guaranteed Health Orb, and a rare chance of 1-3 Gems.
    *   **Resources:** Mana/XP crystals are scattered on the ground for collection.

#### 4. Items & Pickups

*   **Health Potions:** Dropped by defeated players or found in chests. Instantly restore a portion of health.
*   **Mana (XP):** Main resource for leveling.

*   **Gems (In-Match):** Found in chests (1-3) or looted from defeated players. Must be "banked" by surviving the match. If you die, you drop all Gems you are holding.

#### 5. Metagame & Progression (Outside of Matches)

*   **Currency:**
    *   **Coins (Soft Currency):** Earned by playing matches. Used to unlock and upgrade items and stuff.
    *   **Gems (Hard Currency):** Purchased with robux or earned in small amounts. Used for premium items like skins, special chests, or to speed up progression.
*   **Heroes/Characters:**
    *   A roster of unlockable characters clothes.
    *   Each hero often has a unique passive ability or a different starting spell, encouraging different playstyles (e.g., a tanky hero with more HP, a mage with faster cooldowns).
    *   The Novice (Default): No passive or active ability.

*   **Upgrades:** Players can spend coins to upgrade their favorite heroes items and clothes, which might grant permanent stat boosts (e.g., +5% starting HP, -2% spell cooldown). These upgrades are usually small to avoid a pure "pay-to-win" feel but still provide a sense of progression.
*   **Cosmetics:** Skins for heroes, different wand/staff appearances, custom death effects. These are the primary monetization driver and generally offer no gameplay advantage.
*   **other:** There are NO permanent stat upgrades. A new player and a veteran player have the same base stats.

Monetization is Cosmetic Only.

Cosmetics Chest: A "loot box" purchasable with Gems that contains Skins, Wands, Death Effects, etc.



#### 6. spells and combinations
*   **Spells:**
Level 2 Spells (1 Element)
**🔥 Fire Ball**

Description: The wizard sends out a ball of fire. Deals damage on impact and sets the target on fire.

**⛰️ Lump of dirt**

Description: The wizard throws a magically enhanced lump of dirt at your target. Hitting your enemy damages and slows them down.

**💧 Blob of water**

Description: The wizard throws a blob of water that deals damage upon impact. Some of the damage dealt replenishes your wizard's HP.

Level 4 Spells (2 Elements)
**🔥🔥 Explosive salvo**

Description: The wizard throws a large fireball that explodes when it hits an enemy or obstacle. The explosion deals damage and sets fire to all enemies within range.

**⛰️⛰️ Boulder**

Description: The wizard fires a magically enhanced boulder at your target, dealing damage and stunning your opponent.

**💧💧 Spray**

Description: The wizard shoots out loads of dense water droplets that scatter in a cone formation. The droplets deal damage to any enemies they hit. Some of the damage dealt replenishes your wizard's HP.

**🔥💧 Lightning ball**

Description: The wizard throws an electrical orb, which homes onto the nearest enemy on the way and doesn't disappear on impact. All enemies that get hit take damage in return.

**💧⛰️ Ice lance**

Description: The wizard fires a razor-sharp icicle that goes straight through any enemies in its way, dealing damage and slowing them down.

**🔥⛰️ Meteor**

Description: The wizard hurls a flaming meteorite at your target, dealing damage on impact and creating an area of burning oil. The oil slows opponents down and deals damage every second they are in it.

Level 6 Spells (3 Elements - Final Forms)
**🔥🔥🔥 Supernova**

Description: The wizard summons a mini copy of the Sun. The red-hot star moves forward slowly, burning all nearby enemies and dealing massive damage if touched. The star explodes when it reaches the end of its journey, hitting all opponents in a large area.

**💧💧💧 Tsunami**

Description: The wizard creates a giant wave that grows in size as it moves along, knocking down any enemies that get in its way. Some of the damage dealt replenishes your wizard's HP.

**⛰️⛰️⛰️ Stone ram**

Description: The wizard turns to stone and quickly flies forward. During flight, the wizard gets a defence boost, deals damage to anyone in his path and leaves them temporarily stunned. At the end of the flight, the stone breaks up into fragments which deal damage to anyone they hit.

**🔥🔥💧 Storm front**

Description: The wizard creates an area of unstable electricity, which slowly flies forward. Nearby enemies are struck by lightning and are dealt damage.

**🔥🔥⛰️ Cluster bomb**

Description: The wizard launches a fire bomb that deals damage on impact and explodes. Several fragments are sent flying out by the explosion which create an area of burning oil on the ground. The oil slows opponents down and deals damage every second they are in it.

**💧💧🔥 Thunderbolt**

Description: The wizard shoots out a thunderbolt. Lightning reaches maximum range in a flash, flying straight through all enemies in its path.

**💧💧⛰️ Avalanche**

Description: The wizard conjures a snowball that grows in size as it rolls. The bigger the snowball - the more damage dealt. Hitting your enemy stuns them. Some of the damage dealt replenishes your wizard's HP.

**⛰️⛰️🔥 Eruption**

Description: The wizard summons a giant smouldering boulder that rolls along the ground, leaving a trail of fire in its wake. The boulder deals massive damage on impact and stuns your enemy. Opponents caught in the trail of fire are slowed down and dealt damage over time.

**⛰️⛰️💧 Ice crystal**

Description: The wizard fires an ice crystal at your target. The crystal explodes on impact, dealing damage and stunning your enemy. The blast causes four shards to fly off in different directions, dealing damage and slowing enemies down.

**🔥💧⛰️ Elemental Storm**

Description: The wizard unites the power of all the elements, creating an elemental whirlwind. The whirlwind moves forwards, sucking in all nearby enemies. Any enemies caught up in the whirlwind cannot attack and are dealt damage.




---

### 8. Game Feel & Player Feedback ("Juice")

This section defines the implementation of audio-visual feedback to make actions feel impactful and responsive.

#### 1. Hit Feedback (Dealing Damage)
When your spell hits an enemy:
* **Audio:** A crisp "Impact" sound (unique to the spell) plays.
* **VFX (Damage Numbers):** White "damage numbers" pop up from the enemy, scaling in size based on damage (a `Supernova` hit should have much larger numbers than a `Lump of Dirt`). Critical hits will show as larger, yellow numbers.
* **VFX (Hit Flash):** The enemy's character model flashes bright white for one frame.

#### 2. Damage Feedback (Taking Damage)
When you are hit by an enemy:
* **Audio:** A clear "Damage Taken" sound (grunt or shield crack) plays.
* **Visual (Vignette):** A red, pulsing "vignette" (darkening at the edges of the screen) flashes briefly.
* **Visual (Screen Shake):** A very slight, short camera shake occurs. This is more pronounced for high-damage spells like `Boulder` or `Eruption`.
* **Visual (Directional):** A red directional indicator will flash at the edge of the screen, showing the direction the damage came from.

#### 3. Kill Feedback (Elimination)
When you successfully eliminate another player:
* **Audio (Global):** A loud, satisfying, and sharp "Elimination" sound (like a magical shatter or "squelch") plays, audible to both you and the defeated player.
* **VFX (Player Death):** The enemy player's model dissolves or explodes in a custom "death effect" (which is a cosmetic item).
* **VFX (Loot Burst):** All their dropped Gems, Health Orbs, and Mana burst out from their body in a rewarding "loot explosion."
* **UI:** A small notification appears on your screen: `[Player Name] Eliminated! (+10 Coins)`.

#### 4. Event Feedback
* **Level Up:**
    * **Audio:** A bright, rewarding "ding!" jingle.
    * **VFX:** A bright column of light or "energy swirl" effect surrounds your character for 1-2 seconds.
* **Pickup Feedback:**
    * **Audio:** A quick, high-pitched "tink" for Mana, "bloop" for Health, and "bling!" for Gems.
    * **VFX:** The 3D model for the pickup will animate, flying into the player.
* **Button Feedback (UI):**
    * All buttons will have "hover" (scale up, play sound) and "click" (scale down, play sound) states.
    * Primary buttons (like "Play" or "Queue Up") will have a more impactful sound and animation.

--


The goal is to create a 6 minute match where an average player reaches Level 4, and the Time-to-Kill (TTK) feels fast-paced but not instant.

---

### 1. Core Player Stats

* **Base Health (HP):** 1000
* **Base Movement Speed:** 16

### 2. Leveling & XP Curve

The goal is for an *average* player to hit Level 4. The curve is front-loaded to make this achievable. Reaching Level 6 is possible but requires aggressive play.

| Level | XP Needed for Next Level | Total XP to Reach this Level |
| :--- | :--- | :--- |
| **1** | 100 XP | 0 |
| **2** | 150 XP | 100 |
| **3** | 250 XP | 250 |
| **4** | 400 XP | 500 |
| **5** | 600 XP | 900 |
| **6** | 850 XP | 1500 |
| **7+**| (Levels beyond 6 are very rare) | |

#### XP Sources
* **Small Mana Crystal (Ground):** 5 XP
* **Chest Opened:** 250 XP
* **Player Elimination:** 400 XP

> **Balance Notes:** This model works perfectly. An average player can reach **Level 4 (500 total XP)** by opening just **two chests** or by getting **one kill** (400 XP) and some ground crystals.

### 3. Combat Balancing (Spells)

Since players will spend most of the match at Levels 2-4, these spells must be effective.

#### Level 2 Spells (Base = 1000 HP)

| Spell | Damage (Impact) | Cooldown | Special Effect |
| :--- | :--- | :--- | :--- |
| **🔥 Fire Ball** | 100 | 1.8s | **Burn:** 25 damage/sec for 3s (75 total). |
| **💧 Blob of Water** | 90 | 1.5s | **Siphon:** Heals 30% of damage dealt (~30 HP). |
| **⛰️ Lump of Dirt** | 75 | 2.2s | **Heavy:** Slows enemy by 25% for 2s. |

#### Level 4 Spells (Example)
* **⛰️⛰️ Boulder:** 175 Damage, 3.0s Cooldown, **Stun** (1 second)
* **🔥💧 Lightning Ball:** 120 Damage, 1.7s Cooldown, **Homing** + **Pierces**

> **Balance Notes:** The Time-to-Kill (TTK) at this level is ~7-10 hits, which allows for good duels. Level 6 spells (like `Supernova` @ 400+ damage) will be a massive power spike, but very few players will achieve them.

### 4. In-Match Economy & Drops

* **Chests:** 250 XP, 1 Health Orb, 25% chance of 1-3 Gems.
* **Player Elimination:** 400 XP, 2 Health Orbs, All held Gems.
* **Health Orb Value:** Instantly heals **150 HP** (15% of max health).

### 5. Match Pacing & Storm (New 6-Minute Timer)

This is the most critical change. The storm must be extremely fast and aggressive.

| Phase | Total Duration | Wait Time | Shrink Time | Storm Damage (per sec) | Safe Zone Radius |
| :--- | :--- | :--- | :--- | :--- | :--- |
| **Phase 1** (Start) | 1:00 (60s) | 60s | --- | 1% (Safe) | 600 studs |
| **Phase 2** (Early) | 1:45 (105s) | 30s | 90s | 2.5% (20 HP) | 300 studs |
| **Phase 3** (Mid) | 1:30 (90s) | 15s | 75s | 5% (50 HP) | 100 studs |
| **Phase 4** (End) | 1:30 (90s) | 15s | 75s | 7.50% (100 HP) | 25 studs |
| **Total Time:** | **5:45** | | | | (Final circle closes to 0) |

**Detailed Breakdown:**

* **0:00 - 1:00 (Phase 1):** The match begins. The map is safe. At 1:00, the **Phase 1 Safe Zone** (600 stud radius) and the **Phase 2 Safe Zone** (300 stud radius) both appear. The storm begins to close in from the *edge of the map* towards the Phase 1 zone.
* **1:00 - 2:45 (Phase 2):** Players have 35s to see the next circle, then 90s to get inside the 300-stud radius. The storm closes from the Phase 1 radius to the Phase 2 radius, dealing **2.5% HP/sec**.
* **2:45 - 4:15 (Phase 3):** After a 15s wait, the storm closes from 300 studs to 100 studs over 75s. Damage is now a serious threat at **5% HP/sec**.
* **4:15 - 5:45 (Phase 4):** The final phase. After a 15s wait, the storm closes from 100 studs to 25 studs. Damage is lethal at **7.5% HP/sec**, forcing the final 1v1. After 5:45, the circle closes completely.

> **Balance Notes:**
> * Players have **only 60 seconds** to find a chest before the first circle appears and the storm becomes a threat.
> * After 2.5 minutes, the storm damage becomes a major threat (50 HP/s), forcing the mid-game fights.
> * The game is forced to a conclusion in under 6 minutes. This is a very fast-paced, "arcade" style of Battle Royale.

This 6-minute model creates a game about fast looting, immediate decisions, and aggressive mid-game fights.

---




---

### Core Gameplay Loop

The server runs on a continuous, global "Game State" timer that is visible to all players. (e.g., `MATCH IN PROGRESS: 4:32` or `INTERMISSION: 1:59`).

1.  **Join Server:** The player joins the game and spawns in the **3D Lobby**. The server is in one of two states: "Match in Progress" or "Intermission."
2.  **Lobby State / Intermission:**
    * All players are in the 3D Lobby. This is the default "hub" for socializing, shopping, and customizing.
    * A **"View Stand"** physically overlooks the **Arena**. The Arena is always visible, even when empty.
    * Players can choose to queue for the next match in two ways:
        1.  **Physically:** By walking into the "View Stand" zone.
        2.  **Via UI:** By pressing a "Queue Up" button on their screen.
3.  **Match Start:**
    * A global "Intermission" timer counts down (e.g., 2 minutes).
    * When the timer hits 0, the server teleports **only the players who queued up** (from 1 to 20 players) to the Arena.
    * The 6-minute Battle Royale match begins.
4.  **Parallel States (During a Match):**
    * **Players in Arena:** Fight the 6-minute Battle Royale.
    * **Players in Lobby:** Can continue to socialize, shop, or go to the View Stand to spectate the *live* match happening in the Arena below.
5.  **Game End (Player Defeat):**
    * When a player in the Arena is eliminated, they are **immediately teleported back to the 3D Lobby**.
    * The "Post-Match Summary" screen appears for them.
    * They are now a "Lobby" player and can go to the View Stand to watch the rest of the match they just left.
6.  **Game End (Match Over):**
    * When the 6-minute timer ends (or a winner is found), any remaining players in the Arena are teleported back to the 3D Lobby.
    * The server's global state switches to "Intermission," and the 2-minute countdown timer begins for the *next* match. The loop (Step 2) repeats.

---

### UI Flow

#### 1. Pre-Game UI Flow (Lobby / Intermission State)
This is the default state of the game.

* **World:** Players are in the 3D Lobby.
* **On-Screen UI:**
    * **Top Center:** A global timer.
        * `MATCH IN PROGRESS: 4:32`
        * `INTERMISSION: 1:59`
    * **Top Right:** Currency display (Coins, Gems).
    * **Top Left:** Player Profile / Settings.
    * **Bottom Center (Contextual):**
        * If in the Lobby: A **"QUEUE UP"** button.
        * If in the View Stand: A **"LEAVE QUEUE"** button (player is auto-queued).
* **Physical Stations:**
    * **Hall of Heroes:** Opens the "Hero Selection" UI.
    * **Collector's Vault:** Opens the "Shop" UI.
    * **Tome of Legends:** Opens the "Battle Pass" UI.
    * **The View Stand:** A physical place to stand, spectate the Arena, and automatically be queued.

#### 2. Post-Game UI Flow
This flow begins for each player *individually* as their match ends.

1.  **Player Elimination:**
    * The player is killed in the Arena.
    * **Screen 1: Initial Result** appears:
        * `#7 / 18` (The total number is dynamic)
        * `KILLED BY: [Player Name]`
        * Button: `CONTINUE`
2.  **Teleport & Summary:**
    * Pressing `CONTINUE` teleports the player back to the **3D Lobby**.
    * **Screen 2: Post-Match Summary** appears over their screen:
        * `Placement: #7 / 18`
        * `Eliminations: 3`
        * `Coins Earned: +150`
        * `Gems Banked: +5`
        * Button: `RETURN TO LOBBY`
3.  **Back in Lobby:**
    * The player closes the summary and is now a normal "Lobby" player.
    * The global timer on their screen reads `MATCH IN PROGRESS: 3:45`.
    * They can now walk to the View Stand to spectate, or just wait for the Intermission to start.


---


This is a vital part of the design. The in-game economy dictates player motivation and the long-term "grind."

Here is the V1 Economy & Metagame balance sheet.

---

### 1. Currency Earn Rate (Per Match)

This formula is designed to reward both survival (placement) and aggression (kills) during the 6-minute, 1-20 player matches.

#### 💰 Coins (Soft Currency)
The formula for Coin rewards per match is:
**`Coins Earned = (Placement Bonus) + (Kill Bonus)`**

* **Placement Bonus:**
    * **1st Place (Winner):** 100 Coins
    * **2nd - 3rd Place:** 75 Coins
    * **4th - 10th Place:** 50 Coins
    * **11th - 20th Place:** 25 Coins

* **Kill Bonus:**
    * **Per Elimination:** 10 Coins

> **Example Scenarios:**
> * A skilled player gets **1st Place** with **3 kills**: (100) + (3 * 10) = **130 Coins**.
> * An average player gets **8th Place** with **1 kill**: (50) + (1 * 10) = **60 Coins**.
> * A new player gets **17th Place** with **0 kills**: (25) + (0 * 10) = **25 Coins**.

#### 💎 Gems (Hard Currency)
Free-to-play Gems are earned in two ways:

* **In-Match Banking:** Players find 1-3 Gems in chests and "bank" them by leaving the Arena (either by winning, dying, or being teleported back at the end). This is the primary "active" earn method.
* **Battle Pass (Free Track):** The free track of the Battle Pass will provide a total of **100 Gems** to all players who complete it.

---

### 2. Item & Hero Pricing

This pricing is based on the earn rates above, balanced to make new Heroes an achievable goal and cosmetics a premium purchase.

#### 🦸 Hero Pricing
* **Coin Price (Grind):** **3,000 Coins**
    * *Balance Note: This means a new hero takes ~50 average matches (at 60 Coins/match) to unlock, creating a solid "grind" goal.*
* **Gem Price (Skip):** **250 Gems**

#### 💅 Cosmetic & Pass Pricing
* **Premium Battle Pass:** **400 Gems**
    * *Note: The Premium Pass will contain ~500 Gems in its reward track, meaning players who complete it can earn back more than they spent.*
* **Cosmetics Chest:** **50 Gems**
* **Direct Purchase Skins (Featured Shop):**
    * **Standard Skin (Recolor):** 150 Gems
    * **Legendary Skin (New Model/VFX):** 600 Gems



---







### 🎨 1. Core UI Elements

This is the non-sexy, but *most critical* list. These are the building blocks of your entire user interface.

* **Health Bar:** A all players health bar (over head of the players).
* **XP Bar:** A bar showing progress to the next level (at the top of the screen).
* **Player Level Number:** A large, clear number (e.g., "Lv. 7").
* **Buttons (Standard):** A set of clean, cartoon-style buttons. You'll need:
    * `Button (Primary)`: (e.g., "Play," "Unlock," "Choose").
    * `Button (Secondary)`: (e.g., "Cancel," "Back").
    * `Button (Small/Icon)`: (e.g., for 'Settings' or 'Close Window').
* **Window/Panel Frames:** A background design for all your pop-up menus (like the Shop, Hero, or Level Up screen).
* **In-Game HUD Frame:** A stylized border or set of graphics that "hold" your spell icons and health bar.
* **Virtual Joystick:** The visual element for the "Move-to-Aim" stick.
* **Main Shoot Button:** The large button frame for the main spell.
* **Ability Button:** The smaller button frame for the 'Q' Hero Ability.
* **Cooldown Overlay:** The "pie-wipe" or "grayscale" visual that shows a button is on cooldown.

### 🪄 2. Spell & Ability Icons (The Core V1 Set)

This is the most important *visual* part of your game. Each icon must be high-contrast and easy to read as a tiny thumbnail.

#### Element Icons (for Level Up Screen)
* **Fire Essence:** (e.g., a simple flame)
* **Water Essence:** (e.g., a water droplet)
* **Earth Essence:** (e.g., a leaf or a small rock)

#### Spell Icons (20 total)
* **Fire (Red/Orange theme):**
    * `Fire Ball`
    * `Explosive Salvo`
    * `Meteor`
    * `Cluster Bomb`
    * `Eruption`
    * `Supernova`
* **Water (Blue/Cyan theme):**
    * `Blob of Water`
    * `Spray`
    * `Ice Lance`
    * `Ice Crystal`
    * `Avalanche`
    * `Tsunami`
* **Earth (Green/Brown theme):**
    * `Lump of Dirt`
    * `Boulder`
    * `Stone Ram`
* **Hybrid (Purple/Yellow/Electric theme):**
    * `Lightning Ball`
    * `Storm Front`
    * `Thunderbolt`
    * `Elemental Storm`

#### Hero Ability Icons (4 total)
* `Dash` (for Kaelen)
* `Bulwark` (for Terra)
* `Soothing Pool` (for Aquo)
* `Locked Ability` (a "padlock" icon for The Novice)

### 💪 3. Passive Buff Icons (The "Odd Levels")

These need to *visually explain* the buff at a glance.
* `Rapid Cast` (Cooldown): (e.g., a stopwatch or swirling arrow)
* `Spell Force` (Damage): (e.g., an exploding fist or magic spark)
* `Velocity` (Projectile Speed): (e.g., a "whoosh" or comet)
* `Magnitude` (AoE): (e.g., an expanding circle)
* `Critical Magic` (Crit): (e.g., a targeting reticle or starburst)
* `Fortitude` (HP): (e.g., a heart or a shield)
* `Fleet Foot` (Move Speed): (e.g., a winged boot)
* `Regeneration` (HP/s): (e.g., a green + sign)
* `Bulwark` (Damage Reduction): (e.g., a solid shield)
* `Mana Magnet` (Pickup Range): (e.g., a magnet)
* `Insight` (XP Gain): (e.g., an open book or a brain)

### 💰 4. Currency & Item Icons

These are for the HUD, the shop, and the end-of-match screen.
* **Coin:** (a gold coin, for your soft currency)
* **Gem:** (a bright crystal, for your hard currency)
* **Health Orb:** (a glowing green/red orb)
* **Mana Crystal:** (a glowing blue/purple crystal)
* **Cosmetics Chest:** (an ornate treasure chest, for the shop)

### 🌎 5. 3D In-Game Assets (VFX & Models)

This is the "visual stuff" that isn't UI. This is what will make your game look exciting and (on Roblox) *must* be performance-friendly.

* **VFX (Visual Effects):** This is your #1 priority. You need a 3D particle effect for *every single spell*.
    * **Example:** For `Cluster Bomb`, you need:
        1.  The `Fire Ball` projectile.
        2.  A large `Explosion` on impact.
        3.  The flying `Fragments` (visual only).
        4.  The `Burning Oil` ground effect (a "decal" or particle ring).
* **3D Models:**
    * **The 4 Heroes:** `Novice`, `Kaelen`, `Terra`, `Aquo` (as "low-poly, vibrant cartoon" models).
    * **The Map Assets:** Trees, rocks, walls, buildings.
    * **The Chest:** A 3D model of the treasure chest that can play an "open" animation.
* **Pickups:**
    * The 3D model for the `Health Orb`.
    * The 3D model for the `Mana Crystal`.
    * The 3D model for the `Gem`.





---

### 1. ➡️ Pre-Game UI Flow & 3D Lobby

The pre-game experience is now a 3D, interactive, social hub.

#### 1. The 3D Lobby
When a player loads the game, they do not see a menu. They spawn as their selected Hero in a small, 3D "Mage's Tower" or "Sanctuary" map.

* **Social Hub:** Players can see and interact with all other players who are also in the lobby (not in a match).
* **On-Screen UI:** The 3D lobby has a *minimal* UI:
    * **Top Right:** Currency display (Coins and Gems).
    * **Top Left:** Player Profile / Settings button.
    * **Bottom Right:** A "Jump to Lobby" button for players who get stuck or want to respawn at the main hub.

#### 2. Physical UI Locations
The old 2D menu buttons (`SHOP`, `HEROES`, `BATTLE PASS`) are now physical stations or NPCs in the 3D world:

* **The Hall of Heroes:** (Replaces `HEROES` screen)
    * **Location:** A room with magical podiums.
    * **Function:** Walking up to a podium opens the "Hero Selection & Customization" screen, allowing the player to select a hero, equip skins, wands, and death effects.
* **The Collector's Vault:** (Replaces `SHOP` screen)
    * **Location:** An NPC or a large, ornate vault.
    * **Function:** Interacting with this station opens the "Shop" UI, showing the Featured items, Cosmetics Chest, and Gem store.
* **The Tome of Legends:** (Replaces `BATTLE PASS` screen)
    * **Location:** A large, glowing book on a pedestal.
    * **Function:** Interacting with the book opens the "Battle Pass" UI, showing the reward tracks and challenges.

#### 3. Queuing for a Match

Players have two ways to enter a match:

* **1. The Main Portal (Quick Play)**
    * **Location:** The main, central feature of the lobby is a large, swirling "portal."
    * **Function:** Walking directly into this portal instantly queues the player for the next available match. Their screen shows a "Queueing..." UI, but they can still run around the lobby until the match is found.

* **2. The View Stand (Spectator Queue - Your New Feature)**
    * **Location:** A separate balcony or "grandstand" area overlooking a magical "viewing screen" or crystal ball.
    * **Function (This is the key flow):**
        1.  The player walks into the "View Stand" zone.
        2.  The game *immediately and automatically* queues them for the next match. A small UI element appears: "Queued for next match...".
        3.  Simultaneously, the game's "spectator system" activates. The player is **teleported to a live, in-progress match** as a spectator (flying camera or locked to a random player).
        4.  The player can now watch the *current* match unfold.
        5.  When their *new* match is ready, they are **automatically pulled** from the spectator server and teleported into their new game as a contestant.


---

### 1. 🎵 Sound Effects (SFX)

This is the moment-to-moment feedback that makes the game feel responsive.

#### Spells (The Top Priority)
Each of the 20 spells needs a unique, clear audio kit.
* **Casting Sound:** The sound the spell makes when *you* cast it (e.g., a "fwoosh" for `Fire Ball`).
* **Travel/Loop Sound:** (If needed) The sound the projectile makes as it flies (e.g., the "crackle" of `Storm Front` or the "rumble" of `Boulder`).
* **Impact Sound:** The sound the spell makes when it hits an enemy or a wall (e.g., a "splat" for `Blob of Water`, an "explosion" for `Explosive Salvo`).
* **Specialty Sounds:**
    * `Elemental Storm`: Needs a continuous "vortex" loop.
    * `Stone Ram`: Needs a "dash" sound and a "shatter" sound.
    * `Supernova`: Needs a "charge" loop and a "massive explosion."
    * `Boulder` / `Avalanche`: Need "rolling" sounds.

#### Player
* **Movement:** Footstep sounds (e.g., on grass, on stone).
* **Hit/Damage:** A clear "grunt" or "shield crack" sound when you take damage.
* **Death:** A distinct, final "disintegration" or "poof" sound.
* **Level Up:** A very satisfying, bright "ding!" or "power-up" jingle.
* **Buff Acquired:** A small, positive "chime" when selecting a passive buff.

#### Hero Abilities ('Q' Button)
* **Kaelen (`Dash`):** A sharp "whoosh" sound.
* **Terra (`Bulwark`):** A "magical shield" activation sound, and a "shatter" sound if it blocks a spell.
* **Aquo (`Soothing Pool`):** A "bubbling water" loop sound.

#### World & Items
* **Mana Crystal Pickup:** A quick, high-pitched "tink" or "sip" sound.
* **Health Orb Pickup:** A slightly lower-pitched, "bloop" or "heal" sound.
* **Gem Pickup:** A sharp, rewarding "bling!" or "gem" sound.
* **Chest Open:** A creaking "latch" sound followed by a magical "burst" as the items fly out.
* **The Storm:** A constant, low-frequency "wall of wind" or "magical energy" sound that gets louder as you get closer to it.
* **Storm Damage:** A "sizzle" or "zap" sound for every tick of damage you take while inside the storm.

#### UI (User Interface)
* **Primary Button Click:** A solid, chunky "click" (for "Play," "Unlock," "Select").
* **Secondary Button Click:** A lighter, "back" or "cancel" click.
* **Level-Up Ready:** A sound to alert the player they have a choice (when the 3 options appear).
* **Match Found:** A loud, clear "alert" or "horn" that pulls the player's attention.
* **Match Start:** A "gong" or "battle horn" to signal the match has begun.
* **Victory Fanfare:** A short, happy, triumphant jingle.
* **Defeat Fanfare:** A short, sad, "womp womp" style tune.
* **Cosmetics Chest Open:** A special, exciting "slot machine" or "treasure reveal" sound sequence.

---

### 2. 🎶 Music

* **Lobby/Menu:** An adventurous, magical, and slightly epic orchestral track. It should be catchy but not annoying, as players will hear it a lot.
* **In-Match (Phase 1):** A quiet, ambient, magical "exploration" track plays for the first 60 seconds (Phase 1).
* **In-Match (Phase 2+):** The music **fades out completely.** This is a common competitive choice. It makes the game more tense and allows players to use sound to their advantage (listening for enemy footsteps and spell casts).
* **In-Match (Tension):** A very subtle, low-frequency "heartbeat" or "tension" track can fade in when the storm is closing or when you are one of the last 3 players alive.

---

### 3. ✨ Visual Feedback (VFX)

This is just as important as audio. The player *must* be able to tell what spell was just used by its visual alone.

* **Spell VFX:** All 20 spells need unique, low-poly particle effects that match their theme (fire, water, earth).
* **Hero Ability VFX:**
    * `Dash`: A "streak" or "blur" effect.
    * `Bulwark`: A visible "bubble" or "magical barrier" around Terra.
    * `Soothing Pool`: A visible "glowing water" decal on the ground.
* **Player State VFX:**
    * **Level Up:** A bright flash of light or "energy swirl" around the player.
    * **Buffs/Debuffs:** A small, persistent particle effect at the player's feet. (e.g., a **green swirl** for "Heal," a **red flame** for "Burn," a **blue drip** for "Slow").
    * **Hit Impact:** A small "blood" or "magic" splat that shows the direction damage came from.
* **Item & World VFX:**
    * **Pickups:** All pickups (Mana, Health, Gem) must have a slight "glow" to be visible in the grass.
    * **Chest:** The chest should have a "shimmer" or "glow" when it's unopened. It needs a "burst" effect when opened.
    * **The Storm:** A massive, visible "wall" of purple/blue energy. Players inside the storm should have a "damage" effect on their screen (e.g., a sizzle or energy pulses at the edges).







### Technical & Design Considerations for a Remake

*   **Art Style:** a simple, low-poly, vibrant cartoon style. This is effective because it runs well on a wide range of devices and the characters/effects are easy to read on a small screen.
*   **Balancing:** The most critical design challenge. You need to ensure no single spell or hero is overwhelmingly powerful. This requires extensive playtesting and data analysis (cooldowns, damage numbers, projectile speed, AoE size, etc.).
*   **UI/UX:** Must be clean and intuitive for a mobile touch screen and desktop. Buttons need to be large enough, and status information (HP, cooldowns, map) must be visible without cluttering the screen.
    * Mobile: Needs a joystick for movement/rotation (Move-to-Aim), 1 main spell button, and two small buttons for the Hero's Active Ability.

    *   Desktop needs to have wasd and arrow keys for movement and rotation for spell button need to use E or Spacebar or left mouse click button and need G and Q for the two small Activateing Abilities Buttons. For a way to select the 3 option when leveling up we need 1,2,3 and Z,X,C or the players can use the mouse to select everything for the options and buttons on the right and joystick.
    Desktop: WASD/Arrows for movement/rotation. E, Spacebar, or Left Click for spell button. G or Q for the Hero's Active Ability. Level-up selection via 1,2,3 or mouse.








📜 Developer Coding Standards
1. Purpose
This document defines the official coding standards for the Magica project. Following these rules is not optional. The goal is to create a codebase that is consistent, readable, and maintainable by any developer on the team and the comments must be undersatandable by a 6 years old and the affect of changing one line of code on other files and codes sections, now and in the future. 

2. Naming Conventions
Clear naming is the first step to understandable code.

2.1. Files & Instances (Roblox Explorer)
Use PascalCase: All instances in the Roblox Explorer (Scripts, ModuleScripts, Folders, Models, Parts, UI elements) must use PascalCase.

✅ Good: MainMenu, SpellButton, ServerStorage, ClientScripts

❌ Bad: main menu, spell_button, serverstorage, clientscripts

Be Descriptive: Names must clearly state the object's purpose.

✅ Good: PlayerDataHandler (Script), FireballVFX (ParticleEmitter)

❌ Bad: Script (Script), Particles (ParticleEmitter)

Script Naming:

ModuleScripts: End with Module (e.g., SpellModule, DataModule).

LocalScripts: End with Client or Local (e.g., MovementClient, ShopLocal).

Server Scripts: End with Server or Handler (e.g., GameLoopServer, PlayerJoinHandler).

2.2. Variables (Luau)
Use camelCase for local variables: This is the standard for variables defined inside a function or script.

✅ Good: local playerHealth = 100

❌ Bad: local PlayerHealth = 100

❌ Bad: local player_health = 100

Use PascalCase for ModuleScripts: When requiring a ModuleScript, name the variable after the module.

✅ Good: local SpellModule = require(script.Parent.SpellModule)

Use UPPER_SNAKE_CASE for Constants: For values that never change (e.g., settings, base stats).

✅ Good: local MAX_PLAYERS = 20

✅ Good: local STORM_DAMAGE_PER_SECOND = 5

2.3. Functions
Use PascalCase for Module Functions: Functions inside a ModuleScript that will be called by other scripts.

✅ Good: function SpellModule:CastFireball(player, target)

Use camelCase for Local Functions: Functions defined locally inside a single script.

✅ Good: local function updatePlayerList(player)

3. Commenting
Comments explain why code exists, not just what it does.

File Headers: Every Script and ModuleScript must begin with a comment block explaining its purpose and locations and which other files and folders and codes and function it affects.

**all code** must be debug friendly to make it easier to recoganize any issues very important

Lua

--[[
    Name: SpellHandlerServer.lua
    Author: [Your Name]
    Date: [YYYY-MM-DD]
    location: relicatedStorage/server/mainMenu.server.lua
    affects: this file affects that file and this line of code etc

    Description: This server-side script handles all spell casting logic,
    damage calculation, and VFX replication for the Spell Evolution system.
]]--
Function Headers: Every major function must have a comment block explaining what it does, its parameters (@param), and what it returns (@return).

Lua

--- Calculates the total damage for a spell, including buffs.
--- @param player Player The player casting the spell.
--- @param spellData table The base spell's data table.
--- @return number The final calculated damage.
local function calculateSpellDamage(player, spellData)
    -- ...
end
Complex Logic: Do comment on every single line. Do comment on complex or "tricky" sections of code.

✅ Good: -- Calculate reduction based on player's 'Stone Skin' buff

❌ Bad: -- Get the player's health [Comment is obvious and useless]

local playerHealth = player.Character.Humanoid.Health

4. Code Structure & Best Practices
4.1. Services
Use game:GetService(): Always use GetService to get Roblox services. Never use dot notation (e.g., game.Workspace). This is more robust and error-proof.

Define at Top: All services must be defined in a block at the top of the script.

Lua

-- Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local ServerScriptService = game:GetService("ServerScriptService")
4.2. Local vs. Global
Always Use local: All variables must be defined as local unless you have an extraordinary reason for it to be global (you almost never do). This is critical for performance and preventing bugs.

4.3. ModuleScripts
Use Modules for Shared Code: If a function or table is needed by more than one script, it must be in a ModuleScript.

Structure: All modules should follow a standard table structure.

Lua

local MyModule = {}

function MyModule:MyFunction()
    -- ...
end

return MyModule
4.4. RemoteEvents & RemoteFunctions
Location: All RemoteEvent and RemoteFunction instances must be stored in a single Remotes folder in ReplicatedStorage.

Naming: Use PascalCase and a ClientToServer (CS) or ServerToClient (SC) suffix.

✅ Good: CastSpellCS (RemoteEvent)

✅ Good: LevelUpChoiceSC (RemoteEvent)

SECURITY IS #1:

NEVER trust the client. All data sent from a client to the server must be validated.

Validate ALL inputs: Before the server acts, check: Is this player argument the actual player who fired the remote? Is the cooldown ready? Is this a legal spell choice?

❌ Bad: -- Client sends: CastSpellCS:Fire("Supernova")

✅ Good: -- Client sends: CastSpellCS:Fire()

✅ Good: -- Server receives: "CastSpellCS" from [Player], checks [Player]'s current spell, checks cooldown, then casts it.

5. Performance
wait() vs. task.wait(): Always use task.wait(). It is the modern, more performant version.

Avoid while wait() do: Do not use while wait() do loops for game logic. Use event-based programming (e.g., player.CharacterAdded:Connect(...), .Heartbeat:Connect(...)).

Debounce: All events that can be spammed (like clicking a button or touching a part) must use a "debounce" check.










**future updates:** Kaelen (The Swift): Passive: Momentum (Dash resets on kill), Active: Dash (18s CD).

Terra (The Warden): Passive: Stone Skin (15-damage shield after 5s of no damage), Active: Bulwark (Blocks next spell, 22s CD).

Aquo (The Sage): Passive: Absorption (+20% healing), Active: Soothing Pool (Heals 12% HP over 3s, 25s CD).

battle pass: Battle Pass: A seasonal progression system for cosmetic rewards.