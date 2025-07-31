# Tess of Hearts

_A whimsical, hand-drawn game of collection and apotheosis._

---

## Overview

**Tess of Hearts** (also known as **Gather Hearts**) is a short, surreal, and emotionally resonant platformer adventure made with Godot 4.4. Journey as Tess through the mysterious Cosmic Bathhouse, repair broken hearts, and uncover the truth of your own identity. The game is designed for the web, touch-first, and is entirely free.

---

## Features

- **Light Platforming & Puzzle Exploration:** Traverse dreamy, non-euclidean bathhouse zones filled with secrets and symbolism.
- **Heart Repair System:** Find and mend broken hearts with a variety of materials, each with unique emotional significance.
- **Dual Resource Management:** Manage both energy (for movement/interactions) and courage (for ant areas).
- **Ant Infestation System:** Clear ant-infested areas with strategic courage management.
- **Thematic Dialogue:** Experience text-based storytelling through handwritten visuals.
- **Hand-Drawn Art:** Every asset is sketched and handwritten for an intimate, sketchbook feel.
- **Ambient Audio:** Dreamlike music and subtle effects set the mood.
- **Touch-First Input:** Designed for mobile and tablet, with mouse fallback.

---

## Technical Details

- **Engine:** Godot 4.4 (Forward Plus rendering)
- **Platform:** Web (HTML5) export
- **Resolution:** 1920x1080 (viewport)
- **Input:** Touch-first with mouse fallback
- **Architecture:** Node-based with autoload singletons for game state management

### Core Systems
- **GameManager:** Handles game state, heart collection, and area progression
- **GameData:** Manages player resources (energy, courage, inventory)
- **HeartRepairSystem:** Manages heart repair mechanics and material effects
- **InputManager:** Touch and mouse input handling
- **HandwrittenTextManager:** Displays handwritten text assets
- **DialogueSystem:** Manages character interactions and storytelling
- **EnergySystem:** Manages player energy for movement and interactions
- **CourageSystem:** Manages courage for ant area interactions

---

## Narrative

Tess journeys through the Cosmic Bathhouse in search of the sleeping Eldritch Empress, encountering broken hearts, dreaming spirits, and cryptic feline guides. In the end, Tess discovers she is the Empress—and that even cosmic beings need kindness and connection. The story concludes with Tess sharing cookies and whiskey with her bearded friend, a quiet moment of gratitude and rest.

> **Tagline:** "Still doesn't like ants."

---

## Resource Management Systems

### Energy Management System

**Energy Mechanics:**
- **Starting Energy:** 100 points
- **Energy Costs:**
  - Movement: 1 energy per action
  - Object interactions: 1 energy per action
  - Item collection: 1 energy per action
  - Character interactions: 1 energy per action
  - **Dialogue interactions: NO energy cost**

**Movement Speed Based on Energy:**
- **51-100 Energy:** Full speed (100%)
- **26-50 Energy:** 66% speed (reduced movement)
- **1-25 Energy:** 33% speed (slow movement)
- **0 Energy:** No movement possible

**Energy Restrictions:**
- **0 Energy:** No movement or interactions possible (except dialogue)
- **Low Energy:** Slower movement and limited interaction capability
- **Energy Display:** Real-time energy level shown in HUD with color coding

### Courage System

**Courage Mechanics:**
- **Starting Courage:** 100 points
- **Ant Area Penalties:**
  - Entering area: Courage cost = current ant count
  - Leaving area: Courage cost = current ant count
  - Stepping on ant: Courage cost = current ant count (before removal)
- **Dynamic Penalties:** Each ant removed reduces future penalties
- **Area Destruction:** Areas remove themselves when all ants are cleared

**Example Scenario** (4 ants):
1. Enter area: -4 courage (4 ants remain)
2. Step on ant: -4 courage (3 ants remain)
3. Step on ant: -3 courage (2 ants remain)
4. Step on ant: -2 courage (1 ant remains)
5. Step on ant: -1 courage (0 ants remain, area destroyed)
6. Leave area: No cost (area already destroyed)

---

## Heart Repair System

| Material            | Effect         | Symbolism                                 |
|---------------------|---------------|--------------------------------------------|
| Broken Heart        | ×⅓            | Base value, painful but incomplete         |
| Tape                | ×½            | Superficial fix                           |
| Sutures             | ×¾            | Earnest effort, imperfect repair           |
| Barbed Wire         | ×¾            | Painful coping, leaves damage              |
| Rose Thorns         | ×¾            | Beauty and hurt intertwined                |
| Scars               | ×1            | Healing acknowledged, not erased           |
| Kinagami            | ×2            | Sacred art of emotional restoration        |
| Thoughts & Prayers  | ×0            | Empty gestures                             |

### Heart Types
- **Broken Hearts:** Common, base value 10.0
- **Sleeping Hearts:** Uncommon, base value 15.0  
- **Cosmic Hearts:** Rare, base value 25.0

---

## Characters

- **Tess:** The curious, caring protagonist—ultimately the spirit of the Empress herself.
- **Eldritch Empress:** Sleeping, divine presence at the heart of the Cosmic Bathhouse.
- **Bearded Friend:** A gentle companion, appearing in the epilogue.
- **Guide Cats:** Mysterious and ambiguous helpers.

---

## Art & Audio

- **Art Style:** Hand-drawn, minimalist animation, handwritten text as images.
- **Audio:** Gentle, ambient music and subtle sound effects.
- **No Voice Acting.**

### Visual Assets
- Handwritten text images for all dialogue and UI elements
- Hand-drawn character sprites and environmental art
- Paper textures for backgrounds and UI elements
- Color-coded placeholder shapes for prototyping

---

## Controls

- **Touch:** Tap to interact and move.
- **Mouse:** Click for desktop play.
- **Visual Proxies:** Early builds use colored shapes for characters and items:
  - Tess = Purple
  - Friend = Blue
  - Hearts = Red
  - Whiskey = Tan
  - Cookies = Brown
  - Gold = Yellow
  - Barbed Wire = Grey
  - Sutures = Magenta
  - Roses = Pink
  - Biopods = Green

---

## Project Structure

```
TessOfHearts/
├── assets/           # Art, audio, and data files
│   ├── handwritten/  # Handwritten text images
│   │   ├── dialogue/ # Dialogue text images
│   │   ├── messages/ # System message images
│   │   ├── numbers/  # Number images
│   │   └── ui/       # UI element images
│   └── ...
├── scenes/           # Godot scene files
│   ├── interactables/# Interactive objects
│   ├── characters/   # Character scenes
│   └── ui/           # UI scenes
├── scripts/          # GDScript code
│   ├── autoload/     # Singleton scripts
│   ├── base/         # Base classes
│   └── ui/           # UI-specific scripts
└── textures/         # Texture assets
```

---

## Implemented Systems

### ✅ **Dialogue System** (Fully Implemented)
- **Proximity-based triggers** that activate when Tess enters specific areas
- **Handwritten text display** using image assets instead of text labels
- **Proper UI positioning and scaling** with automatic container sizing
- **Debug output** for troubleshooting and development
- **Auto-hide functionality** with fade animations
- **No energy cost** for dialogue interactions
- **Dialogue choice system** with handwritten button options
- **Dynamic choice availability** based on player inventory
- **Proper input handling** with mouse filter settings to prevent interference

**Available Dialogue:**
- `"tess_what_is_it"` - Tess asking what something is
- `"friend_hey_there"` - Friend greeting (proximity-based, 50 pixel range)
- `"cat_wisdom"` - Cat giving wisdom
- `"still_doesnt_like_ants"` - Something about not liking ants
- `"tess_come_over_here"` - Tess calling the friend during phone call animation

**Dialogue Choices:**
- `"eat_cookies"` - Eat cookies with the friend (requires cookies in inventory)
- `"drink_whiskey"` - Drink whiskey with the friend (requires whiskey in inventory)
- `"cookies_and_whiskey"` - Share both cookies and whiskey (requires both items)
- `"excuse_me"` - Ask the friend to leave temporarily
- `"never_mind"` - Cancel the dialogue interaction

**Usage:**
- Add `dialogue_trigger.tscn` to scenes and set dialogue keys
- Characters can trigger dialogue via `say_dialogue()` method
- Direct system calls via `DialogueSystem.show_dialogue()`
- Friend dialogue: Click friend while Tess is within 50 pixels
- Dialogue choices: Available options appear based on inventory and context
- Item consumption: Selecting certain choices consumes items from inventory

### ✅ **Energy Management System** (Fully Implemented)
- **Energy costs for actions**: Movement, interactions, and item collection
- **Movement speed scaling**: Speed reduces based on energy levels
- **Real-time energy display**: HUD shows current energy with color coding
- **Interaction restrictions**: Actions blocked when energy is depleted
- **Dialogue exceptions**: Dialogue interactions don't cost energy
- **Energy restoration**: Functions for testing and future mechanics

**Energy Costs:**
- Movement: 1 energy per action
- Object interactions: 1 energy per action
- Item collection: 1 energy per action
- Character interactions: 1 energy per action
- Dialogue interactions: NO energy cost

### ✅ **Courage System** (Fully Implemented)
- **Courage resource**: Separate from energy, used for ant area interactions
- **Ant area penalties**: Courage costs based on remaining ant count
- **Real-time courage display**: HUD shows current courage with color coding
- **Decreasing penalties**: Each ant removed reduces future courage costs
- **Area destruction**: Ant areas self-destruct when completely cleared

### ✅ **Ant Area System** (Fully Implemented)
- **Configurable ant areas**: Size, count, speed, and color customization
- **Individual ant management**: Each ant is a separate entity with collision
- **Random movement**: Ants move randomly within area bounds
- **Visual feedback**: Ants shrink and turn red when stepped on
- **Area clearing**: Areas turn green and self-destruct when cleared
- **Courage integration**: All interactions cost courage based on ant count
- **Dynamic sizing**: Visual indicators automatically match collision areas

**Ant Area Features:**
- **Configurable Properties**:
  - `ant_count`: Number of ants (5-15 typical)
  - `area_size`: Size of the area (100x80 to 200x150 typical)
  - `ant_speed`: Movement speed (20-35 pixels/sec typical)
  - `ant_color`: Visual color of ants (different brown shades)
- **Visual Indicators**: Automatically sized to match collision areas
- **Ant Counter**: Shows remaining ants when player is in area
- **Test Scene**: Multiple areas with different configurations for testing

### ✅ **Character System** (Fully Implemented)
- **Base character class** with movement and interaction capabilities
- **Touch/mouse input handling** with proper event management
- **Dialogue integration** for character interactions
- **Visual placeholder system** for prototyping
- **Energy cost integration** for movement and interactions
- **Movement speed scaling** based on energy levels
- **Friend movement echo system** with configurable delay
- **Visual feedback system** with hover highlighting and click animations

**Friend Movement System:**
- **Personality-based following**: Friend follows Tess with natural personality quirks
- **Minimum distance**: 50 pixels from Tess (comfortable following distance)
- **Speed reduction**: Gradually slows down as he gets closer to Tess (100% to 20% speed)
- **Drift system**: Sustained path variations lasting 3-8 seconds that cause sideways drift, falling behind, or speeding past
- **Exploration periods**: Brief 3-4 second exploration when Tess is idle
- **Pause behavior**: Short 0.5-1.0 second pauses for natural movement
- **Collision detection**: Stops when within 50 pixels of Tess
- **Natural movement patterns**: Friend feels like a companion with his own personality rather than just following

**Friend Dialogue System:**
- **Proximity-based dialogue**: Friend speaks when clicked while Tess is within 50 pixels
- **Direct distance checking**: Reliable detection using real-time distance calculation
- **Touch input integration**: Works with both touch and mouse input
- **Randomized responses**: Friend randomly chooses between "Hey there!" and "Tess, what is it?" when clicked
- **No energy cost**: Dialogue interactions don't consume energy
- **Visual feedback**: Friend flashes when touched to indicate interaction
- **Auto-fade dialogue**: Friend's dialogue automatically fades after 5 seconds
- **Dynamic dialogue options**: Shows available choices based on Tess's inventory (cookies, whiskey, etc.)
- **Item consumption**: Selecting dialogue options can consume items from inventory

**Character Visual Feedback:**
- **Hover highlighting**: Characters brighten (30% modulation) when mouse hovers over them
- **Click animations**: Characters briefly scale up (10%) and brighten (50%) when clicked
- **Visual feedback**: Helps players understand characters are interactive entities
- **Temporary effects**: All visual feedback is brief and non-intrusive

**Friend Departure System ("Excuse Me"):**
- **Dialogue choice**: Tess can say "Would you excuse me for a bit?" to dismiss the friend
- **Back-to point system**: Friend retraces their path to a previous stopping point (currently always returns to starting position)
- **Movement tracking**: Friend records stopping points when moving more than half-screen distance
- **Departure state**: Friend stops following Tess and stays at the back-to point
- **Departure timeout**: Friend automatically hides if they don't reach the target within 10 seconds
- **Close-enough detection**: Friend considers target reached if within 50 pixels

**Friend Summoning System (Phone Call):**
- **Keyboard input**: Press 'C' key to summon the friend (mapped to "call_friend" action)
- **Universal summoning**: Works regardless of friend's current state (following, departed, or off-screen)
- **State reset**: Resets departure flags and moves friend to Tess's position
- **Resume following**: Friend will follow Tess normally after being summoned
- **Phone call concept**: Thematic integration with the game's narrative
- **Call animation**: Tess plays a phone call animation when summoning the friend
- **Dialogue during call**: Tess displays "Come over here" dialogue during the call animation

### ✅ **Heart Repair System** (Fully Implemented)
- **Material-based repair mechanics** with multiplier system
- **Integration with game state management** for progress tracking
- **Multiple heart types** with different base values
- **Repair material effects** with symbolic significance

### ✅ **Handwritten Text System** (Fully Implemented)
- **Image-based text display** using handwritten font assets
- **Asset management** for handwritten fonts and text images
- **UI integration** for numbers, messages, and dialogue
- **Proper scaling and positioning** for different screen sizes

### ✅ **Interaction System** (Fully Implemented)
- **Base interactable class** with energy cost integration
- **Openable objects** (doors, containers) with proper state management
- **Collectable items** with energy costs and inventory integration
- **Character interactions** with dialogue system integration
- **Touch and mouse input** support for all interaction types

### ✅ **UI System** (Fully Implemented)
- **Real-time resource displays** for energy and courage with color coding
- **Inventory management** with visual feedback
- **Handwritten text integration** for authentic aesthetic
- **Responsive design** for different screen sizes
- **Debug information** for development and testing
- **UI button accessibility** with proper mouse filter settings for input detection
- **Consumption and crafting buttons** for item usage and heart repair
- **Dynamic button enabling/disabling** based on available resources

---

## Development Status

**Current Status:** Core systems fully implemented and functional
- ✅ Dialogue system with proximity triggers and handwritten text
- ✅ Energy management system with movement and interaction costs
- ✅ Courage system for ant area interactions
- ✅ Ant area system with configurable properties and self-destruction
- ✅ Character movement and interaction with resource restrictions
- ✅ Heart repair mechanics with material effects
- ✅ Handwritten text display system
- ✅ Complete UI framework with resource displays
- ✅ Interaction system with energy costs
- ✅ Openable and collectable systems

**Next Steps:**
- Final art asset integration
- Audio implementation
- Level design and progression
- Web export optimization
- Energy restoration mechanics (items, rest areas, etc.)
- Additional dialogue content and character interactions

---

## Testing

### Test Scenes Available:
- **`scenes/test_dialogue.tscn`**: Dialogue system testing with multiple triggers
- **`scenes/test_energy.tscn`**: Energy system testing with comprehensive instructions
- **`scenes/test_ant_areas.tscn`**: Ant area system testing with multiple configurations
- **`scenes/test_friend_movement.tscn`**: Friend movement echo system testing

### Testing Features:
- Four dialogue triggers with different dialogue keys
- Character interaction testing
- Energy cost verification for all interaction types
- Movement speed testing at different energy levels
- Courage system testing with ant areas
- Visual indicators for trigger areas
- Ant area clearing and destruction testing
- Friend movement echo with configurable delay

---

## Play

Coming soon as a web build!

---

## Credits

**Developer, Art, Design:** Sean Miner  
Made with [Godot 4.4](https://godotengine.org/)

---

**Thank you for being here.**
