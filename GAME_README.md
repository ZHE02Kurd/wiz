# 🎮 Magic Battle Royale Prototype

A mobile-first, top-down magic Battle Royale game built with Rojo for Roblox.

## 🚀 What's Implemented

### Core Systems
- ✅ **Mobile Controls**: Virtual joystick (left) and shoot button (right)
- ✅ **Combat System**: Spell casting with projectiles
- ✅ **Leveling System**: XP collection and level ups
- ✅ **Spell Fusion**: Combine elements to create powerful spells
- ✅ **Buff System**: Stat upgrades at odd levels
- ✅ **Map Generation**: Arena with walls, chests, and mana crystals

### Spell Elements
- **Basic**: Starting spell (10 damage, 0.5s cooldown)
- **Fire** 🔥: 25 damage, 1.2s cooldown
- **Water** 💧: 20 damage, 1.0s cooldown
- **Earth** 🪨: 30 damage, 1.5s cooldown
- **Lightning** ⚡: Fire + Water (40 damage, 2.0s cooldown)
- **Lava** 🌋: Fire + Earth (45 damage, 2.2s cooldown)
- **Nature** 🌿: Water + Earth (35 damage, 1.8s cooldown)

### Level Up System
- **Even Levels (2, 4, 6...)**: Choose between Fire, Water, or Earth
- **Odd Levels (3, 5, 7...)**: Choose between 3 random buffs:
  - +Projectile Speed
  - -Cooldown Reduction
  - +Max HP
  - +Damage
  - +Move Speed

## 🎯 How to Play

1. **Movement**: Use the left joystick to move your character
2. **Shooting**: Press the red button on the right to cast spells
3. **Collect Crystals**: Walk over blue glowing crystals for XP
4. **Open Chests**: Click on chests to spawn many crystals
5. **Level Up**: Choose upgrades when you level up
6. **Eliminate Players**: Deal damage to other players

## 🛠️ Testing the Prototype

1. Start Rojo server: `rojo serve`
2. Open Roblox Studio
3. Connect with Rojo plugin
4. Press Play
5. Move with joystick, shoot with button
6. Collect crystals to level up and test the spell fusion system

## 📁 Project Structure

```
src/
├── client/
│   ├── Controllers/
│   │   └── MobileController.luau    # Mobile input handling
│   ├── UI/
│   │   └── UIController.luau        # HUD, HP bar, XP bar, level up UI
│   └── init.client.luau
├── server/
│   ├── Services/
│   │   ├── PlayerDataService.luau   # Player stats, XP, leveling
│   │   ├── CombatService.luau       # Spell casting, projectiles
│   │   └── MapService.luau          # Arena, chests, crystals
│   └── init.server.luau
└── shared/
    ├── Data/
    │   └── Config.luau               # Game configuration
    ├── Systems/
    │   ├── SpellFusion.luau          # Spell combination logic
    │   └── LevelUpSystem.luau        # XP thresholds, choices
    └── Types/
        └── GameTypes.luau            # Type definitions
```

## 🎨 Mobile Optimization

- Large touch targets for mobile devices
- Virtual joystick for smooth movement
- Clear visual feedback
- Performance-optimized with ShadowMap lighting

## 🔜 What's Not Implemented (Yet)

The following are part of the design but not in this prototype:
- ❌ Zone shrinking / storm damage
- ❌ Matchmaking & lobby system
- ❌ Multiple game modes (Solo, Duos)
- ❌ Health potions & speed boots
- ❌ Hero system with unique abilities
- ❌ Metagame progression (coins, gems)
- ❌ Battle Pass
- ❌ Cosmetics & skins
- ❌ Spectating after death

## 📝 Notes

This is a **functional prototype** demonstrating:
1. Mobile touch controls
2. Real-time combat
3. Spell progression & fusion
4. Level-up choice system
5. Resource collection

Perfect for testing core gameplay mechanics before building out the full Battle Royale systems!
