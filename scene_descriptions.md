🎮 Main.tscn
Main (Node2D) [Main.gd]
├── Background (ColorRect)
│   └── [color: #1a1a2e, size: 1920x1080]
├── Camera2D
├── Characters (Node2D)
│   ├── Tess (instantiated from Tess.tscn)
│   └── BeardedFriend (instantiated from BeardedFriend.tscn)
├── Interactables (Node2D)
│   ├── Hearts (Node2D)
│   │   └── [Hearts spawned via script]
│   └── Items (Node2D)
│       └── [Items spawned via script]
├── Environment (Node2D)
│   ├── BathhouseRoom (instantiated from BathhouseRoom.tscn)
│   └── Lighting (Node2D)
└── UI (CanvasLayer)
	└── GameHUD (instantiated from GameHUD.tscn)

👤 Characters/Tess.tscn
Tess (Node2D) [Tess.gd extends Character]
├── Visual (ColorRect)
│   ├── [color: #8B4CB8 (Purple)]
│   ├── [size: 64x64]
│   └── [anchor_preset: CENTER]
├── Area2D
│   └── CollisionShape2D
│       └── [shape: RectangleShape2D(64x64)]
├── TouchResponder (Node) [TouchResponder.gd]
├── MovementComponent (Node2D)
│   └── TargetMarker (ColorRect)
│       ├── [color: #FFFFFF, alpha: 0.3]
│       ├── [size: 8x8]
│       └── [visible: false]
└── DialoguePoint (Marker2D)
	└── [position: Vector2(0, -40)]
	
	
	
❤️ Interactables/Heart.tscn
Heart (Node2D) [Heart.gd extends Interactable]
├── Visual (ColorRect)
│   ├── [color: #B84C4C (Red)]
│   ├── [size: 32x32]
│   └── [anchor_preset: CENTER]
├── Area2D
│   └── CollisionShape2D
│       └── [shape: RectangleShape2D(32x32)]
├── TouchResponder (Node) [TouchResponder.gd]
├── HeartGlow (ColorRect)
│   ├── [color: #FFAAAA, alpha: 0.0]
│   ├── [size: 40x40]
│   ├── [position: Vector2(-4, -4)]
│   └── [z_index: -1]
├── RepairState (Node)
│   └── [script: HeartRepairState.gd]
└── CollectionEffect (Node2D)
	├── Particles (Node2D)
	└── SoundPoint (Marker2D)
	
🏛️ Environments/BathhouseRoom.tscn
BathhouseRoom (Node2D) [BathhouseRoom.gd]
├── Background (ColorRect)
│   ├── [color: #2C1810]
│   └── [size: 1920x1080]
├── Architecture (Node2D)
│   ├── Walls (Node2D)
│   │   ├── LeftWall (ColorRect)
│   │   │   ├── [color: #3D2117, size: 50x1080]
│   │   │   └── [position: Vector2(0, 0)]
│   │   ├── RightWall (ColorRect)
│   │   │   ├── [color: #3D2117, size: 50x1080]
│   │   │   └── [position: Vector2(1870, 0)]
│   │   ├── TopWall (ColorRect)
│   │   │   ├── [color: #3D2117, size: 1920x50]
│   │   │   └── [position: Vector2(0, 0)]
│   │   └── BottomWall (ColorRect)
│   │       ├── [color: #3D2117, size: 1920x50]
│   │       └── [position: Vector2(0, 1030)]
│   └── BathStructure (Node2D)
│       ├── MainBath (ColorRect)
│       │   ├── [color: #1A0F0A, size: 400x200]
│       │   └── [position: Vector2(760, 440)]
│       ├── Water (ColorRect)
│       │   ├── [color: #4A90A4, alpha: 0.6]
│       │   ├── [size: 380x180]
│       │   └── [position: Vector2(770, 450)]
│       └── Steam (Node2D)
│           ├── SteamParticle1 (ColorRect)
│           │   ├── [color: #FFFFFF, alpha: 0.2]
│           │   ├── [size: 20x30]
│           │   └── [position: Vector2(800, 400)]
│           ├── SteamParticle2 (ColorRect)
│           │   ├── [color: #FFFFFF, alpha: 0.15]
│           │   ├── [size: 25x35]
│           │   └── [position: Vector2(950, 380)]
│           └── SteamParticle3 (ColorRect)
│               ├── [color: #FFFFFF, alpha: 0.1]
│               ├── [size: 30x40]
│               └── [position: Vector2(1100, 360)]
├── SpawnPoints (Node2D)
│   ├── PlayerSpawn (Marker2D)
│   │   └── [position: Vector2(960, 800)]
│   ├── HeartSpawn1 (Marker2D)
│   │   └── [position: Vector2(200, 600)]
│   ├── HeartSpawn2 (Marker2D)
│   │   └── [position: Vector2(1720, 600)]
│   └── ItemSpawn1 (Marker2D)
│       └── [position: Vector2(960, 200)]
├── WardBarrier (Node2D)
│   ├── BarrierField (ColorRect)
│   │   ├── [color: #FF6666, alpha: 0.3]
│   │   ├── [size: 1920x1080]
│   │   └── [visible: false]
│   ├── WardSymbols (Node2D)
│   │   ├── Symbol1 (ColorRect)
│   │   │   ├── [color: #FFAAAA, size: 40x40]
│   │   │   └── [position: Vector2(400, 300)]
│   │   ├── Symbol2 (ColorRect)
│   │   │   ├── [color: #FFAAAA, size: 40x40]
│   │   │   └── [position: Vector2(1520, 300)]
│   │   └── Symbol3 (ColorRect)
│   │       ├── [color: #FFAAAA, size: 40x40]
│   │       └── [position: Vector2(960, 150)]
│   └── BarrierCollision (StaticBody2D)
│       └── CollisionShape2D
│           └── [shape: RectangleShape2D(1920x1080)]
└── Lighting (Node2D)
	├── AmbientLight (ColorRect)
	│   ├── [color: #FFE4B5, alpha: 0.1]
	│   ├── [size: 1920x1080]
	│   └── [z_index: 10]
	├── WaterReflection (ColorRect)
	│   ├── [color: #87CEEB, alpha: 0.2]
	│   ├── [size: 380x180]
	│   ├── [position: Vector2(770, 450)]
	│   └── [z_index: 5]
	└── SteamGlow (ColorRect)
		├── [color: #F0F8FF, alpha: 0.05]
		├── [size: 600x400]
		├── [position: Vector2(660, 250)]
		└── [z_index: 3]

🎮 UI/GameHUD.tscn
GameHUD (Control) [GameHUD.gd]
├── [anchors_preset: PRESET_FULL_RECT]
├── TopBar (HBoxContainer)
│   ├── [anchors_preset: PRESET_TOP_WIDE]
│   ├── [size: 1920x80]
│   ├── HeartsCollected (Label)
│   │   ├── [text: "Hearts: 0"]
│   │   ├── [theme: large_font]
│   │   └── [modulate: #FFB6C1]
│   ├── VSeparator
│   ├── CurrentArea (Label)
│   │   ├── [text: "Area: Bathhouse Entry"]
│   │   ├── [theme: medium_font]
│   │   └── [modulate: #87CEEB]
│   └── Settings (Button)
│       ├── [text: "⚙"]
│       ├── [size: 60x60]
│       └── [flat: true]
├── BottomBar (VBoxContainer)
│   ├── [anchors_preset: PRESET_BOTTOM_WIDE]
│   ├── [size: 1920x120]
│   ├── InteractionHint (Label)
│   │   ├── [text: "Touch to interact"]
│   │   ├── [horizontal_alignment: CENTER]
│   │   ├── [theme: medium_font]
│   │   └── [modulate: #FFFFFF, alpha: 0.7]
│   └── ProgressBar (HBoxContainer)
│       ├── [size_flags_horizontal: EXPAND]
│       ├── HeartProgress (ProgressBar)
│       │   ├── [max_value: 100]
│       │   ├── [value: 0]
│       │   ├── [size: 400x20]
│       │   └── [tint_progress: #FF69B4]
│       └── ProgressLabel (Label)
│           ├── [text: "0/100"]
│           └── [modulate: #FFB6C1]
└── Feedback (Control)
	├── [anchors_preset: PRESET_CENTER]
	├── CollectionFeedback (Label)
	│   ├── [text: ""]
	│   ├── [horizontal_alignment: CENTER]
	│   ├── [theme: large_font]
	│   ├── [modulate: #TRANSPARENT]
	│   └── [z_index: 100]
	└── TouchEffect (ColorRect)
		├── [color: #FFFFFF, alpha: 0.0]
		├── [size: 40x40]
		├── [mouse_filter: IGNORE]
		└── [z_index: 50]
