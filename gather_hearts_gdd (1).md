
# 🎮 Game Design Document: *Gather Hearts*

## 📌 Overview

**Title:** Gather Hearts  
**Developer:** Sean Miner (solo project)  
**Platform:** Web (HTML5)  
**Monetization:** Free – primarily made for one person, sharable as a small web project  
**Engine:** Godot 4.4  
**Tone:** Intimate, surreal, hand-drawn emotional fable  

---

## 🎭 Narrative Summary

**Premise:**  
Tess journeys through the **Cosmic Bathhouse** in search of the **Eldritch Empress**, encountering broken hearts, sleeping spirits, and ant minions. Ultimately, she discovers she *is* the Empress—fragmented and hidden from herself. To return to wholeness, she must gather and repair hearts, not just for others—but for herself.

**Epilogue:**  
In the credits, Tess is shown sharing cookies and whiskey with her bearded friend. The slumbering Empress rests behind them in the bath. Sometimes, even a cosmic being has to step out of herself and just be a person.

> Tagline: *"Still doesn’t like ants."*

---

## 🕹️ Gameplay

**Core Mechanics:**
- Light platforming
- Puzzle exploration
- Minor RPG elements (item-based decisions, no stats)
- No combat (or very light, metaphorical)
- Inventory of found/repaired hearts
- Thematic dialogue & text-based storytelling

**Loop:**
1. Explore themed bathhouse areas (sealed by Wards)
2. Collect and repair broken hearts
3. Unlock areas by interpreting emotional or symbolic “themes”
4. Deliver hearts to a dreaming Empress—eventually reclaiming her identity

---

## 🧩 Systems

### 💔 Heart Repair System

| Material        | Effect Multiplier | Symbolism                             |
|----------------|-------------------|----------------------------------------|
| Broken Heart   | ×⅓                | Base value, painful but incomplete     |
| Tape           | ×½                | Superficial fix                        |
| Sutures        | ×¾                | Earnest effort, imperfect repair       |
| Barbed Wire    | ×¾                | Painful coping, leaves damage          |
| Rose Thorns    | ×¾                | Beauty and hurt intertwined            |
| Scars          | ×1                | Healing acknowledged, not erased       |
| Kinagami       | ×2                | Sacred art of emotional restoration    |
| Thoughts & Prayers | ×0          | Empty gestures                         |

---

## 🧚 Characters

### **Tess**
- The protagonist. Curious, caring, a little tired.  
- Voice of gentle perseverance.
- Eventually revealed to be the spirit of the Empress herself.

### **The Eldritch Empress**
- An immense, divine, sleeping presence.  
- Exists in a state of rest and detachment.  
- Final merging point for Tess’s journey.

### **The Bearded Friend**
- Appears in the epilogue.
- Offers comfort and companionship.
- Represents the developer.

### **Guide Cats**
- Mysterious.
- Possibly helpful, possibly misleading.

---

## 🎨 Art Style

- Hand-drawn, sketchbook feel
- Text is entirely **handwritten**, saved as image assets
- Minimalist animation: occasional **looping frames**
- Dreamlike architecture (non-euclidean bathhouse zones)

---

## 🔊 Audio

- Gentle ambient **music**, dreamlike or melancholy
- Minimal **sound effects**: page turns, water drips, clicking hearts
- No voice acting

---

## 🎞️ Epilogue / Credits Sequence

**Scene Title:** *"Cookies & Whiskey"*  
**Tone:** Quiet. Intimate. Slightly whimsical. Deeply kind.

### Visuals:
- The Empress slumps gently over the bath, asleep.
- Tess and the Bearded Friend at a small round table, sharing cookies and whiskey.
- Gentle looped animations (cookie bite, sip, smile).

### Text:
1. *"Tess sometimes steps away from the Empress."*
2. *"She has cookies. She drinks whiskey. She laughs with a friend."*
3. *"That, too, is holy."*
4. *"Still doesn’t like ants."*
5. **"Thank you for being here."**

**Credits Roll:** Only the developer’s name.

---

## 🛠️ Input & Engine Notes

- **Input:** Touch-first (tap-to-interact); fallback to mouse for non-touch
- **Engine:** Godot 4.4
- **Visual Proxies (for prototyping):**
    - Tess = Purple `ColorRect`
    - Friend = Blue
    - Hearts = Red
    - Whiskey = Tan
    - Cookies = Brown
    - Gold = Yellow
    - Barbed Wire = Grey
    - Sutures = Magenta
    - Roses = Pink
    - Biopods = Green
    - Extra Sutures = Orange

Each of these will be a separate base scene, later swapped with final art.

---
