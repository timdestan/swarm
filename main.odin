package swarm

import "core:math"
import rl "vendor:raylib"

SCREEN_WIDTH :: 800
SCREEN_HEIGHT :: 1080
TITLE :: "Swarm"

PLAYER_SPEED :: 250
PLAYER_SIZE :: 48 // display width and hitbox
PLAYER_H :: 64 // display height (sprite is 48×64)
PLAYER_HALF :: PLAYER_SIZE / 2
PLAYER_Y_MIN :: FORMATION_Y + FORMATION_ROWS_MAX * FORMATION_SPACING_Y + 80
PLAYER_LIVES :: 3
RESPAWN_DELAY :: 1.8
INVINCIBLE_TIME :: 1.5

BULLET_SPEED :: 500
ROCKET_SPEED :: 280
BULLET_W :: 4
BULLET_H :: 20
MAX_BULLETS :: 16
SHOOT_COOLDOWN :: 0.18

ENEMY_SIZE :: 30
ENEMY_HALF :: ENEMY_SIZE / 2
FORMATION_ROWS_BASE :: 5
FORMATION_ROWS_MAX :: 8
FORMATION_COLS :: 8
MAX_ENEMIES :: FORMATION_ROWS_MAX * FORMATION_COLS
FORMATION_Y :: 120
FORMATION_SPACING_X :: 72
FORMATION_SPACING_Y :: 65
FORMATION_X_START :: (SCREEN_WIDTH - (FORMATION_COLS - 1) * FORMATION_SPACING_X) / 2
ENTER_DURATION :: 1.2 // seconds to fly entry path
GROUP_STAGGER :: 1.5 // seconds between each group entering

WAVE_CLEAR_DELAY :: 2.5
DRIFT_RANGE :: 50.0
DRIFT_PERIOD :: 4.0

MAX_ENEMY_BULLETS :: 48
ENEMY_BULLET_SPEED :: 270.0
ENEMY_FIRE_MIN :: 2.5
ENEMY_FIRE_MAX :: 6.5

DIVE_SPEED :: 340.0
DIVE_FIRE_MIN :: 0.6
DIVE_FIRE_MAX :: 1.2
DIVE_TIMER_MIN :: 5.0
DIVE_TIMER_MAX :: 14.0
MAX_ACTIVE_DIVERS :: 2
RETURN_DURATION :: 1.6

MAX_PARTICLES :: 48
MAX_BLASTS :: 8
BLAST_DURATION :: 0.45
MAX_HIT_FLASHES :: 16
HIT_FLASH_DURATION :: 0.18
STAR_COUNT :: 150

POWERUP_DROP_CHANCE :: 18 // percent chance on enemy kill
POWERUP_SPEED :: 280.0
POWERUP_SIZE :: 18
POWERUP_HALF :: POWERUP_SIZE / 2
MAX_POWERUPS :: 8
DOUBLE_SHOT_DURATION :: 12.0 // seconds
DOUBLE_SHOT_SPREAD :: 10 // horizontal offset between the two shots
DOUBLE_SHOT_SCORE :: 50
SCORE_BONUS_AMOUNT :: 500
EXPLODING_SHOT_DURATION :: 10.0
EXPLODING_SHOT_RADIUS :: 130.0
EXPLODING_SHOT_SCORE :: 75
SEEKING_SHOT_DURATION :: 10.0
SEEKING_SHOT_SCORE :: 150
SEEKING_TURN_RATE :: 6.5 // radians per second

// Boss
BOSS_HP_BASE :: 40
BOSS_SIZE :: 80           // display size
BOSS_HALF :: f32(36)      // hitbox half-size
BOSS_SCORE :: 1000
BOSS_FIRE_RATE_HIGH :: 1.0  // volley every 1 s above 50% HP
BOSS_FIRE_RATE_LOW :: 0.5   // volley every 0.5 s below 50% HP
BOSS_SPREAD_HIGH :: 7     // shots per volley when hp > 50%
BOSS_SPREAD_LOW :: 11     // shots per volley when hp <= 50%
BOSS_SPREAD_STEP :: 18.0  // degrees between shots

// Extra lives
EXTRA_LIFE_THRESHOLD_START :: 10_000
EXTRA_LIFE_GAP_START       :: 10_000 // gap between first and second award
EXTRA_LIFE_GAP_INCREASE    :: 5_000  // each award widens the next gap by this much
EXTRA_LIFE_FLASH_DURATION  :: 2.5

// Level progression
WAVES_PER_LEVEL :: 3      // waves per level, last is always boss
NUM_LEVELS :: 2           // defined levels (loops after all complete)
LEVEL_CLEAR_DELAY :: 3.5

PLAYER_START_POS :: rl.Vector2{SCREEN_WIDTH / 2, SCREEN_HEIGHT - 80}

// ---- Level / Wave Data ----

Wave_Config :: struct {
	is_boss:         bool,
	rows:            int,
	variant_weights: [4]int, // Standard, Aggressive, Heavy, Burst
	boss_hp:         int,
}

// Each level is WAVES_PER_LEVEL waves; last wave is always the boss.
LEVEL_DATA := [NUM_LEVELS][WAVES_PER_LEVEL]Wave_Config{
	{ // Level 1
		{rows = 3, variant_weights = {100, 0, 0, 0}},
		{rows = 4, variant_weights = {70, 30, 0, 0}},
		{is_boss = true, boss_hp = BOSS_HP_BASE},
	},
	{ // Level 2
		{rows = 5, variant_weights = {50, 30, 20, 0}},
		{rows = 6, variant_weights = {30, 30, 20, 20}},
		{is_boss = true, boss_hp = BOSS_HP_BASE + 15},
	},
}

// ---- Types ----

Powerup_Type :: enum {
	Double_Shot,
	Score_Bonus,
	Exploding_Shot,
	Seeking_Shot,
}

Powerup :: struct {
	pos:   rl.Vector2,
	type:  Powerup_Type,
	alive: bool,
}

Enemy_State :: enum {
	Waiting,
	Entering,
	Formation,
	Diving,
	Returning,
}

Star :: struct {
	pos:           rl.Vector2,
	speed:         f32,
	size:          f32,
	twinkle_phase: f32,
	twinkle_speed: f32,
	color:         rl.Color,
}

Player :: struct {
	pos: rl.Vector2,
	vel: rl.Vector2,
	src: rl.Rectangle,
}

Player_Bullet :: struct {
	pos:        rl.Vector2,
	vel:        rl.Vector2,
	is_rocket:  bool,
	is_seeking: bool,
	alive:      bool,
}

Enemy_Variant :: enum {
	Standard,
	Aggressive,
	Heavy,
	Burst,
	Boss,
}

Enemy :: struct {
	pos:         rl.Vector2,
	slot:        rl.Vector2,
	enter_from:  rl.Vector2,
	enter_ctrl:  rl.Vector2,
	src:         rl.Rectangle,
	alive:       bool,
	state:       Enemy_State,
	enter_t:     f32,
	enter_delay: f32,
	fire_timer:  f32,
	dive_timer:  f32,
	dive_vel:    rl.Vector2,
	wave:        int,
	variant:     Enemy_Variant,
	burst_count: int,
	burst_timer: f32,
	hp:          int,
	max_hp:      int,
	sway_t:      f32, // boss-only: independent time for smooth oscillation
}

Enemy_Bullet :: struct {
	pos:   rl.Vector2,
	vel:   rl.Vector2,
	alive: bool,
}

Particle :: struct {
	pos:      rl.Vector2,
	vel:      rl.Vector2,
	lifetime: f32,
	max_life: f32,
	size:     f32,
}

Blast :: struct {
	pos:   rl.Vector2,
	t:     f32, // 0 = just spawned, 1 = finished
	alive: bool,
}

Hit_Flash :: struct {
	pos:   rl.Vector2,
	t:     f32, // 0 = just spawned, 1 = finished
	alive: bool,
}

Game_State :: struct {
	player:               Player,
	lives:                int,
	player_dead:          bool,
	respawn_timer:        f32,
	invincible_timer:     f32,
	bullets:              [MAX_BULLETS]Player_Bullet,
	enemy_bullets:        [MAX_ENEMY_BULLETS]Enemy_Bullet,
	shoot_timer:          f32,
	enemies:              [MAX_ENEMIES]Enemy,
	drift_time:           f32,
	particles:            [MAX_PARTICLES]Particle,
	stars:                [STAR_COUNT]Star,
	wave:                 int,
	wave_clear_timer:     f32,
	game_over:            bool,
	score:                int,
	powerups:             [MAX_POWERUPS]Powerup,
	blasts:               [MAX_BLASTS]Blast,
	hit_flashes:          [MAX_HIT_FLASHES]Hit_Flash,
	double_shot_timer:    f32,
	exploding_shot_timer: f32,
	seeking_shot_timer:   f32,
	paused:               bool,
	volume:               f32,
	quit_game:            bool,
	save_timer:           f32,
	show_fps:             bool,
	level:                int,
	level_wave:           int, // 0-indexed within current level
	boss_wave:            bool,
	level_clear_pending:  bool, // true while clearing a boss wave
	extra_life_threshold: int,
	extra_life_gap:       int,
	extra_life_flash:     f32,
}

// ---- Main ----

main :: proc() {
	rl.InitWindow(SCREEN_WIDTH, SCREEN_HEIGHT, TITLE)
	defer rl.CloseWindow()
	rl.SetTargetFPS(60)

	rl.InitAudioDevice()
	defer rl.CloseAudioDevice()

	rl.SetExitKey(.KEY_NULL)

	music := rl.LoadMusicStream("assets/xeon5.ogg")
	defer rl.UnloadMusicStream(music)
	rl.SetMusicVolume(music, 0.6)
	rl.PlayMusicStream(music)

	player_sheet := rl.LoadTexture("assets/modular_ships.png")
	defer rl.UnloadTexture(player_sheet)
	enemy_sheet := rl.LoadTexture("assets/ships_biomech.png")
	defer rl.UnloadTexture(enemy_sheet)
	saucer_sheet := rl.LoadTexture("assets/ships_saucer.png")
	defer rl.UnloadTexture(saucer_sheet)

	state := init_game(0.6)
	load_settings(&state)

	for !rl.WindowShouldClose() && !state.quit_game {
		rl.UpdateMusicStream(music)
		rl.SetMusicVolume(music, state.volume)
		update(&state, rl.GetFrameTime())
		draw(&state, player_sheet, enemy_sheet, saucer_sheet)
	}
}

// ---- Init ----

init_game :: proc(volume: f32) -> Game_State {
	s: Game_State
	s.player = Player {
		pos = PLAYER_START_POS,
		src = {152, 336, 48, 64},
	}
	s.lives = PLAYER_LIVES
	s.wave = 1
	s.level = 1
	s.level_wave = 0
	config := LEVEL_DATA[0][0]
	s.enemies = init_wave(config, 1)
	s.boss_wave = config.is_boss
	s.extra_life_threshold = EXTRA_LIFE_THRESHOLD_START
	s.extra_life_gap = EXTRA_LIFE_GAP_START
	for &star in s.stars {star = random_star(spread = true)}
	s.volume = volume
	return s
}

// ---- Update ----

update :: proc(s: ^Game_State, dt: f32) {
	update_settings_menu(s, dt)

	if rl.IsKeyPressed(.F11) {
		s.show_fps = !s.show_fps
	}

	if s.paused do return

	if s.game_over {
		if rl.IsKeyPressed(.R) {s^ = init_game(s.volume)}
		return
	}

	// --- Stars ---
	for &star in s.stars {
		star.pos.y += star.speed * dt
		if star.twinkle_speed > 0 {star.twinkle_phase += star.twinkle_speed * dt}
		if star.pos.y > SCREEN_HEIGHT {star = random_star(spread = false)}
	}

	// --- Player movement & shooting (blocked while dead) ---
	if !s.player_dead {
		vel := rl.Vector2{}
		if rl.IsKeyDown(.RIGHT) || rl.IsKeyDown(.D) do vel.x += PLAYER_SPEED
		if rl.IsKeyDown(.LEFT) || rl.IsKeyDown(.A) do vel.x -= PLAYER_SPEED
		if rl.IsKeyDown(.UP) || rl.IsKeyDown(.W) do vel.y -= PLAYER_SPEED
		if rl.IsKeyDown(.DOWN) || rl.IsKeyDown(.S) do vel.y += PLAYER_SPEED
		s.player.vel = vel
		s.player.pos.x += vel.x * dt
		s.player.pos.y += vel.y * dt
		s.player.pos.x = clamp(s.player.pos.x, PLAYER_HALF, SCREEN_WIDTH - PLAYER_HALF)
		s.player.pos.y = clamp(s.player.pos.y, PLAYER_Y_MIN, SCREEN_HEIGHT - PLAYER_HALF)

		s.shoot_timer -= dt
		if (rl.IsKeyDown(.SPACE) || rl.IsKeyDown(.LEFT_CONTROL)) && s.shoot_timer <= 0 {
			rocket := s.exploding_shot_timer > 0
			seeking := s.seeking_shot_timer > 0
			if s.double_shot_timer > 0 {
				spawn_bullet(
					&s.bullets,
					{s.player.pos.x - DOUBLE_SHOT_SPREAD, s.player.pos.y},
					s.player.vel,
					rocket,
					seeking,
				)
				spawn_bullet(
					&s.bullets,
					{s.player.pos.x + DOUBLE_SHOT_SPREAD, s.player.pos.y},
					s.player.vel,
					rocket,
					seeking,
				)
			} else {
				spawn_bullet(&s.bullets, s.player.pos, s.player.vel, rocket, seeking)
			}
			s.shoot_timer = SHOOT_COOLDOWN
		}
	}

	// --- Respawn sequence ---
	if s.player_dead {
		s.respawn_timer -= dt
		if s.respawn_timer <= 0 {
			if s.lives <= 0 {
				s.game_over = true
			} else {
				s.player_dead = false
				s.player.pos = PLAYER_START_POS
				s.invincible_timer = INVINCIBLE_TIME
			}
		}
	}
	if s.invincible_timer > 0 {s.invincible_timer -= dt}

	// --- Powerup timers ---
	if s.double_shot_timer > 0 {s.double_shot_timer -= dt}
	if s.exploding_shot_timer > 0 {s.exploding_shot_timer -= dt}
	if s.seeking_shot_timer > 0 {s.seeking_shot_timer -= dt}

	// --- Update & collect powerups ---
	for &p in s.powerups {
		if !p.alive do continue
		p.pos.y += POWERUP_SPEED * dt
		if p.pos.y > SCREEN_HEIGHT + POWERUP_HALF {
			p.alive = false
			continue
		}
		if !s.player_dead &&
		   abs(p.pos.x - s.player.pos.x) < PLAYER_HALF &&
		   abs(p.pos.y - s.player.pos.y) < PLAYER_HALF {
			p.alive = false
			switch p.type {
			case .Double_Shot:
				s.double_shot_timer = DOUBLE_SHOT_DURATION
				s.score += DOUBLE_SHOT_SCORE
			case .Score_Bonus:
				s.score += SCORE_BONUS_AMOUNT
			case .Exploding_Shot:
				s.exploding_shot_timer = EXPLODING_SHOT_DURATION
				s.score += EXPLODING_SHOT_SCORE
			case .Seeking_Shot:
				s.seeking_shot_timer = SEEKING_SHOT_DURATION
				s.score += SEEKING_SHOT_SCORE
			}
		}
	}

	// --- Player bullets ---
	for &b in s.bullets {
		if !b.alive do continue

		if b.is_seeking {
			update_seeking_bullet(s, &b, dt)
		}

		b.pos.x += b.vel.x * dt
		b.pos.y += b.vel.y * dt
		if b.pos.y < -BULLET_H ||
		   b.pos.x < -BULLET_W ||
		   b.pos.x > SCREEN_WIDTH + BULLET_W {b.alive = false}
	}

	// --- Particles ---
	for &p in s.particles {
		if p.lifetime <= 0 do continue
		p.pos.x += p.vel.x * dt
		p.pos.y += p.vel.y * dt
		p.lifetime -= dt
	}

	// --- Blasts ---
	for &bl in s.blasts {
		if !bl.alive do continue
		bl.t += dt / BLAST_DURATION
		if bl.t >= 1 {bl.alive = false}
	}

	// --- Hit flashes ---
	for &hf in s.hit_flashes {
		if !hf.alive do continue
		hf.t += dt / HIT_FLASH_DURATION
		if hf.t >= 1 {hf.alive = false}
	}

	// --- Enemies ---
	s.drift_time += dt
	drift_offset := math.sin(s.drift_time * math.TAU / DRIFT_PERIOD) * f32(DRIFT_RANGE)

	for &e in s.enemies {
		if !e.alive do continue

		// Small burst logic
		if e.burst_count > 0 {
			e.burst_timer -= dt
			if e.burst_timer <= 0 {
				fire_enemy_bullet(&s.enemy_bullets, e.pos, s.player.pos)
				e.burst_count -= 1
				if e.burst_count > 0 {
					e.burst_timer = 0.12
				}
			}
		}

		switch e.state {
		case .Waiting:
			e.enter_delay -= dt
			if e.enter_delay <= 0 {e.state = .Entering}

		case .Entering:
			e.enter_t += dt / ENTER_DURATION
			if e.enter_t >= 1 {
				e.enter_t = 1
				e.state = .Formation
				e.fire_timer = rand_fire_timer(e.wave)
			}
			base := bezier2(e.enter_t, e.enter_from, e.enter_ctrl, e.slot)
			// Boss enters straight to slot; regular enemies sway with drift
			x_off := e.variant == .Boss ? f32(0) : drift_offset * e.enter_t
			e.pos = {base.x + x_off, base.y}

		case .Formation:
			if e.variant == .Boss {
				// Use a private timer so sway always starts at centre (sin(0)=0)
				// and is independent of how long the session has been running.
				e.sway_t += dt
				e.pos.x = e.slot.x + math.sin(e.sway_t * math.TAU / 5.5) * 210
				e.pos.y = e.slot.y + math.sin(e.sway_t * math.TAU / 8.0) * 18
				e.fire_timer -= dt
				if e.fire_timer <= 0 {
					enemy_fire(s, &e)
					hp_frac := f32(e.hp) / f32(e.max_hp)
					e.fire_timer = BOSS_FIRE_RATE_LOW if hp_frac < 0.5 else BOSS_FIRE_RATE_HIGH
				}
			} else {
			e.pos = {e.slot.x + drift_offset, e.slot.y}
			e.fire_timer -= dt
			if e.fire_timer <= 0 {
				enemy_fire(s, &e)
				e.fire_timer = rand_fire_timer(e.wave)
			}
			if !s.player_dead {
				e.dive_timer -= dt
				if e.dive_timer <= 0 {
					active := 0
					for other in s.enemies {
						if other.alive && (other.state == .Diving || other.state == .Returning) {
							active += 1
						}
					}
					if active < MAX_ACTIVE_DIVERS {
						dx := s.player.pos.x - e.pos.x + f32(rl.GetRandomValue(-60, 60))
						dy := s.player.pos.y - e.pos.y + 250 // aim past player
						l := math.sqrt(dx * dx + dy * dy)

						spd := f32(DIVE_SPEED)
						switch e.variant {
						case .Aggressive:
							spd *= 1.4 // Fast Diver
						case .Heavy:
							spd *= 0.75 // Heavy Marksman is slower
						case .Standard, .Burst, .Boss:
						}

						e.dive_vel = {dx / l * spd, dy / l * spd}
						e.fire_timer =
							DIVE_FIRE_MIN +
							f32(rl.GetRandomValue(0, 100)) /
								100.0 *
								(DIVE_FIRE_MAX - DIVE_FIRE_MIN)
						e.state = .Diving
					} else {
						e.dive_timer = rand_dive_timer()
					}
				}
			}
		} // end else (non-boss)

		case .Diving:
			e.pos.x += e.dive_vel.x * dt
			e.pos.y += e.dive_vel.y * dt
			e.fire_timer -= dt
			if e.fire_timer <= 0 && e.pos.y < s.player.pos.y {
				enemy_fire(s, &e)
				e.fire_timer =
					DIVE_FIRE_MIN +
					f32(rl.GetRandomValue(0, 100)) / 100.0 * (DIVE_FIRE_MAX - DIVE_FIRE_MIN)
			}
			// Off the bottom (or far off sides): loop back from top
			if e.pos.y > f32(SCREEN_HEIGHT) + 60 ||
			   e.pos.x < -80 ||
			   e.pos.x > f32(SCREEN_WIDTH) + 80 {
				e.pos = {e.slot.x, -70}
				e.enter_from = e.pos
				e.enter_ctrl = {e.slot.x + f32(rl.GetRandomValue(-140, 140)), e.slot.y * 0.35}
				e.enter_t = 0
				e.state = .Returning
			}

		case .Returning:
			e.enter_t += dt / RETURN_DURATION
			if e.enter_t >= 1 {
				e.enter_t = 1
				e.pos = e.slot
				e.state = .Formation
				e.fire_timer = rand_fire_timer(e.wave)
				e.dive_timer = rand_dive_timer()
			} else {
				e.pos = bezier2(e.enter_t, e.enter_from, e.enter_ctrl, e.slot)
			}
		}
	}

	// --- Enemy bullets ---
	for &b in s.enemy_bullets {
		if !b.alive do continue
		b.pos.x += b.vel.x * dt
		b.pos.y += b.vel.y * dt
		if b.pos.y > SCREEN_HEIGHT + 20 {b.alive = false}
	}

	// --- Enemy bullet / player collision ---
	if !s.player_dead && s.invincible_timer <= 0 {
		for &b in s.enemy_bullets {
			if !b.alive do continue
			if abs(b.pos.x - s.player.pos.x) < PLAYER_HALF &&
			   abs(b.pos.y - s.player.pos.y) < PLAYER_HALF {
				b.alive = false
				s.lives -= 1
				s.player_dead = true
				s.respawn_timer = RESPAWN_DELAY
				spawn_explosion(&s.particles, s.player.pos)
				break
			}
		}
	}

	// --- Diving enemy / player body collision ---
	if !s.player_dead && s.invincible_timer <= 0 {
		for &e in s.enemies {
			if !e.alive || e.state != .Diving do continue
			if abs(e.pos.x - s.player.pos.x) < f32(PLAYER_HALF + ENEMY_HALF) &&
			   abs(e.pos.y - s.player.pos.y) < f32(PLAYER_HALF + ENEMY_HALF) {
				e.alive = false
				s.lives -= 1
				s.player_dead = true
				s.respawn_timer = RESPAWN_DELAY
				spawn_explosion(&s.particles, s.player.pos)
				spawn_explosion(&s.particles, e.pos)
				break
			}
		}
	}

	// --- Player bullet / enemy collision ---
	for &b in s.bullets {
		if !b.alive do continue
		for &e in s.enemies {
			if !e.alive do continue
			hit_half := BOSS_HALF if e.variant == .Boss else f32(ENEMY_HALF)
			if abs(b.pos.x - e.pos.x) < hit_half && abs(b.pos.y - e.pos.y) < hit_half {
				b.alive = false
				e.hp -= 1
				if e.hp > 0 {
					spawn_hit_flash(&s.hit_flashes, b.pos)
					continue // boss survives the hit
				}
				e.alive = false
				s.score += BOSS_SCORE if e.variant == .Boss else 100
				spawn_explosion(&s.particles, e.pos)
				if e.variant != .Boss && rl.GetRandomValue(0, 99) < POWERUP_DROP_CHANCE {
					drop_powerup(&s.powerups, e.pos)
				}
				if s.exploding_shot_timer > 0 {
					spawn_blast(&s.blasts, e.pos)
					for &other in s.enemies {
						if !other.alive do continue
						dx := other.pos.x - e.pos.x
						dy := other.pos.y - e.pos.y
						if dx * dx + dy * dy < EXPLODING_SHOT_RADIUS * EXPLODING_SHOT_RADIUS {
							other.hp -= 1
							if other.hp <= 0 {
								other.alive = false
								s.score += BOSS_SCORE if other.variant == .Boss else 100
								spawn_explosion(&s.particles, other.pos)
							}
						}
					}
					// Player caught in their own explosion
					if !s.player_dead && s.invincible_timer <= 0 {
						dx := s.player.pos.x - e.pos.x
						dy := s.player.pos.y - e.pos.y
						if dx * dx + dy * dy < EXPLODING_SHOT_RADIUS * EXPLODING_SHOT_RADIUS {
							s.lives -= 1
							s.player_dead = true
							s.respawn_timer = RESPAWN_DELAY
							spawn_explosion(&s.particles, s.player.pos)
						}
					}
				}
			}
		}
	}

	// --- Extra life ---
	if s.extra_life_flash > 0 {s.extra_life_flash -= dt}
	for !s.game_over && s.score >= s.extra_life_threshold {
		s.lives += 1
		s.extra_life_flash = EXTRA_LIFE_FLASH_DURATION
		s.extra_life_threshold += s.extra_life_gap
		s.extra_life_gap += EXTRA_LIFE_GAP_INCREASE
	}

	// --- Wave clear ---
	if s.wave_clear_timer == 0 {
		all_dead := true
		for e in s.enemies {if e.alive {all_dead = false; break}}
		if all_dead {
			s.wave_clear_timer = s.boss_wave ? LEVEL_CLEAR_DELAY : WAVE_CLEAR_DELAY
			s.level_clear_pending = s.boss_wave
		}
	} else {
		s.wave_clear_timer -= dt
		if s.wave_clear_timer <= 0 {
			s.wave += 1
			s.wave_clear_timer = 0
			s.level_clear_pending = false
			s.level_wave += 1
			if s.level_wave >= WAVES_PER_LEVEL {
				s.level_wave = 0
				s.level += 1
			}
			level_idx := (s.level - 1) % NUM_LEVELS
			config := LEVEL_DATA[level_idx][s.level_wave]
			s.enemies = init_wave(config, s.wave)
			s.boss_wave = config.is_boss
		}
	}
}

// ---- Draw ----

draw :: proc(s: ^Game_State, player_sheet: rl.Texture2D, enemy_sheet: rl.Texture2D, saucer_sheet: rl.Texture2D) {
	player_origin :: rl.Vector2{f32(PLAYER_SIZE) / 2, f32(PLAYER_H) / 2}
	enemy_origin :: rl.Vector2{ENEMY_HALF, ENEMY_HALF}

	rl.BeginDrawing()
	rl.ClearBackground(rl.BLACK)

	// Stars
	for star in s.stars {
		base := f32(180) + star.speed * 0.4
		b := base
		if star.twinkle_speed > 0 {
			b = base * (0.4 + 0.6 * (math.sin(star.twinkle_phase) * 0.5 + 0.5))
		}
		t := u8(clamp(b, 0, 255))
		// Scale the base color by brightness
		color := rl.Color {
			u8(f32(star.color.r) * f32(t) / 255),
			u8(f32(star.color.g) * f32(t) / 255),
			u8(f32(star.color.b) * f32(t) / 255),
			255,
		}
		rl.DrawRectangleV(star.pos, {star.size, star.size}, color)
	}

	// Particles
	for p in s.particles {
		if p.lifetime <= 0 do continue
		t := p.lifetime / p.max_life
		alpha := u8(255.0 * t)
		green := u8(180.0 * t)
		rl.DrawRectangleV(p.pos, {p.size, p.size}, rl.Color{255, green, 0, alpha})
	}

	// Blast shockwaves — expanding ring shows the explosion danger zone
	for bl in s.blasts {
		if !bl.alive do continue
		// Ease out: ring expands fast then slows
		ease := 1 - (1 - bl.t) * (1 - bl.t)
		radius := ease * EXPLODING_SHOT_RADIUS
		// Bright centre fading to transparent at full radius
		alpha := u8((1 - bl.t) * (1 - bl.t) * 255)
		r := u8(255)
		g := u8((1 - bl.t) * 180)
		ring_w := f32(6) * (1 - bl.t * 0.5) // ring thins as it expands
		inner := max(0, radius - ring_w)
		rl.DrawRing(bl.pos, inner, radius + ring_w, 0, 360, 48, rl.Color{r, g, 0, alpha})
		// Faint filled disc so the zone is legible even mid-expansion
		if bl.t < 0.5 {
			disc_alpha := u8((0.5 - bl.t) * 2 * 60)
			rl.DrawCircleV(bl.pos, EXPLODING_SHOT_RADIUS, rl.Color{255, 140, 0, disc_alpha})
		}
	}

	// Powerups
	for p in s.powerups {
		if !p.alive do continue
		color := powerup_color(p.type)
		rl.DrawRectangle(
			i32(p.pos.x) - POWERUP_HALF,
			i32(p.pos.y) - POWERUP_HALF,
			POWERUP_SIZE,
			POWERUP_SIZE,
			color,
		)
		rl.DrawRectangleLines(
			i32(p.pos.x) - POWERUP_HALF,
			i32(p.pos.y) - POWERUP_HALF,
			POWERUP_SIZE,
			POWERUP_SIZE,
			rl.WHITE,
		)
		rl.DrawText(powerup_label(p.type), i32(p.pos.x) - 4, i32(p.pos.y) - 5, 10, rl.WHITE)
	}

	// Enemy bullets — rotated to match trajectory
	for b in s.enemy_bullets {
		if !b.alive do continue
		angle := math.atan2(b.vel.y, b.vel.x) * (180.0 / math.PI) + 90.0
		rect := rl.Rectangle{b.pos.x, b.pos.y, 4, 12}
		rl.DrawRectanglePro(rect, {2, 6}, angle, rl.RED)
	}

	// Player bullets and rockets
	for b in s.bullets {
		if !b.alive do continue
		angle := math.atan2(b.vel.y, b.vel.x) * (180.0 / math.PI) + 90.0
		spd := math.sqrt(b.vel.x * b.vel.x + b.vel.y * b.vel.y)
		dx := b.vel.x / spd
		dy := b.vel.y / spd

		if b.is_rocket {
			// Rocket: exhaust flame behind, wide body, bright warhead at front
			// Positive offset = behind the tip (b.pos), negative = ahead
			seg_off := [5]f32{32, 22, 12, 2, -4}
			seg_w := [5]f32{6, 7, 10, 10, 6}
			seg_h := [5]f32{12, 12, 12, 10, 8}
			seg_color := [5]rl.Color {
				{80, 120, 255, 80}, // blue-white exhaust wisp
				{60, 80, 255, 150}, // exhaust core
				{220, 90, 0, 240}, // orange body
				{255, 200, 0, 255}, // amber warhead
				{255, 255, 220, 255}, // bright white tip
			}
			for i in 0 ..< 5 {
				cx := b.pos.x - dx * seg_off[i]
				cy := b.pos.y - dy * seg_off[i]
				w := seg_w[i]
				h := seg_h[i]
				rl.DrawRectanglePro({cx, cy, w, h}, {w / 2, h / 2}, angle, seg_color[i])
			}
		} else {
			// Regular bullet: green gradient laser trail
			bullet_segs := [6]rl.Color {
				{160, 40, 0, 30}, // far tail: ember
				{200, 80, 0, 80}, // orange
				{230, 160, 0, 140}, // amber
				{220, 230, 0, 190}, // yellow
				{80, 255, 60, 230}, // lime
				{210, 255, 200, 255}, // tip: pale bright green
			}
			for i in 0 ..< 6 {
				offset := f32(5 - i) * 9
				cx := b.pos.x - dx * offset
				cy := b.pos.y - dy * offset
				r := rl.Rectangle{cx, cy, f32(BULLET_W), 11}
				rl.DrawRectanglePro(r, {f32(BULLET_W) / 2, 5.5}, angle, bullet_segs[i])
			}
		}
	}

	// Enemies
	for e in s.enemies {
		if !e.alive do continue
		if e.variant == .Boss {
			dest := rl.Rectangle{x = e.pos.x, y = e.pos.y, width = BOSS_SIZE, height = BOSS_SIZE}
			boss_origin := rl.Vector2{BOSS_SIZE / 2, BOSS_SIZE / 2}
			rl.DrawTexturePro(saucer_sheet, e.src, dest, boss_origin, 0, rl.WHITE)
		} else {
			dest := rl.Rectangle {
				x      = e.pos.x,
				y      = e.pos.y,
				width  = ENEMY_SIZE,
				height = ENEMY_SIZE,
			}
			rl.DrawTexturePro(enemy_sheet, e.src, dest, enemy_origin, 0, rl.WHITE)
		}
	}

	// Boss health bar
	for e in s.enemies {
		if e.alive && e.variant == .Boss {
			bar_w := f32(300)
			bar_h := f32(16)
			bar_x := f32(SCREEN_WIDTH) / 2 - bar_w / 2
			bar_y := f32(36)
			hp_frac := f32(e.hp) / f32(e.max_hp)
			rl.DrawRectangle(i32(bar_x), i32(bar_y), i32(bar_w), i32(bar_h), rl.Color{40, 0, 0, 220})
			fill_color := hp_frac > 0.5 ? rl.Color{200, 30, 30, 255} : rl.Color{255, 80, 0, 255}
			rl.DrawRectangle(
				i32(bar_x),
				i32(bar_y),
				i32(bar_w * hp_frac),
				i32(bar_h),
				fill_color,
			)
			rl.DrawRectangleLines(i32(bar_x), i32(bar_y), i32(bar_w), i32(bar_h), rl.RED)
			boss_label :: "BOSS"
			lw := rl.MeasureText(boss_label, 14)
			rl.DrawText(boss_label, SCREEN_WIDTH / 2 - lw / 2, i32(bar_y) - 18, 14, rl.RED)
			break
		}
	}

	// Hit flashes (boss damage sparks)
	for hf in s.hit_flashes {
		if !hf.alive do continue
		ease := f32(1) - (f32(1) - hf.t) * (f32(1) - hf.t) // ease-out
		outer := ease * 20
		alpha := u8((f32(1) - hf.t) * 255)
		// Expanding ring
		rl.DrawRing(hf.pos, max(outer - 3, 0), outer, 0, 360, 12, rl.Color{255, 220, 80, alpha})
		// Bright core dot that shrinks away
		core := (f32(1) - hf.t) * 5
		rl.DrawCircleV(hf.pos, core, rl.Color{255, 255, 200, alpha})
	}

	// Player
	if !s.player_dead {
		tint := s.invincible_timer > 0 ? rl.Color{150, 200, 255, 255} : rl.WHITE
		player_dest := rl.Rectangle {
			x      = s.player.pos.x,
			y      = s.player.pos.y,
			width  = PLAYER_SIZE,
			height = PLAYER_H,
		}
		rl.DrawTexturePro(player_sheet, s.player.src, player_dest, player_origin, 0, tint)
	}

	// HUD
	// ---- HUD ----
	rl.DrawText(rl.TextFormat("SCORE %d", s.score), 10, 10, 20, rl.WHITE)
	if s.show_fps {
		rl.DrawFPS(SCREEN_WIDTH - 80, 10)
	}

	// Lives — bottom left, 24×24 ship sprites
	LIFE_SIZE :: i32(24)
	LIFE_STEP :: i32(28)
	life_y := i32(SCREEN_HEIGHT) - LIFE_SIZE - 10
	for i in 0 ..< s.lives {
		life_dest := rl.Rectangle {
			x      = f32(10 + i32(i) * LIFE_STEP),
			y      = f32(life_y),
			width  = f32(LIFE_SIZE),
			height = f32(LIFE_SIZE),
		}
		rl.DrawTexturePro(player_sheet, s.player.src, life_dest, {0, 0}, 0, rl.WHITE)
	}

	rl.DrawText(
		rl.TextFormat("LV%d  W%d/%d", s.level, s.level_wave + 1, WAVES_PER_LEVEL),
		SCREEN_WIDTH - 140,
		SCREEN_HEIGHT - 24,
		20,
		rl.GRAY,
	)

	// Active powerup icons — directly right of the lives row, same bottom baseline
	ICON :: i32(40)
	icon_x := 10 + i32(s.lives) * LIFE_STEP + 8
	powerup_y := i32(SCREEN_HEIGHT) - ICON - 10

	if s.double_shot_timer > 0 {
		frac := s.double_shot_timer / DOUBLE_SHOT_DURATION
		draw_powerup_icon_hud(icon_x, powerup_y, ICON, "2x", {0, 180, 220, 200}, frac)
		icon_x += ICON + 6
	}
	if s.exploding_shot_timer > 0 {
		frac := s.exploding_shot_timer / EXPLODING_SHOT_DURATION
		draw_powerup_icon_hud(icon_x, powerup_y, ICON, "X", {220, 80, 0, 200}, frac)
		icon_x += ICON + 6
	}
	if s.seeking_shot_timer > 0 {
		frac := s.seeking_shot_timer / SEEKING_SHOT_DURATION
		draw_powerup_icon_hud(icon_x, powerup_y, ICON, "S", {180, 80, 255, 200}, frac)
	}

	if s.extra_life_flash > 0 {
		fade := min(s.extra_life_flash / 0.5, f32(1.0))
		alpha := u8(fade * 255)
		msg :: "EXTRA LIFE!"
		mw := rl.MeasureText(msg, 28)
		rl.DrawText(
			msg,
			SCREEN_WIDTH / 2 - mw / 2,
			SCREEN_HEIGHT * 3 / 4,
			28,
			rl.Color{80, 255, 130, alpha},
		)
	}

	if s.wave_clear_timer > 0 {
		if s.level_clear_pending {
			msg :: "LEVEL CLEAR!"
			mw := rl.MeasureText(msg, 42)
			rl.DrawText(msg, SCREEN_WIDTH / 2 - mw / 2, SCREEN_HEIGHT / 2 - 24, 42, rl.GOLD)
		} else {
			msg :: "WAVE CLEAR"
			mw := rl.MeasureText(msg, 36)
			rl.DrawText(msg, SCREEN_WIDTH / 2 - mw / 2, SCREEN_HEIGHT / 2 - 18, 36, rl.GREEN)
		}
	}

	if s.game_over {
		rl.DrawText("GAME OVER", SCREEN_WIDTH / 2 - 90, SCREEN_HEIGHT / 2 - 20, 40, rl.RED)
		rl.DrawText(
			"Press R to restart",
			SCREEN_WIDTH / 2 - 100,
			SCREEN_HEIGHT / 2 + 30,
			20,
			rl.WHITE,
		)
	}

	draw_settings_menu(s)

	rl.EndDrawing()
}

enemy_fire :: proc(s: ^Game_State, e: ^Enemy) {
	switch e.variant {
	case .Standard, .Aggressive:
		fire_enemy_bullet(&s.enemy_bullets, e.pos, s.player.pos)
	case .Heavy:
		fire_enemy_bullet(&s.enemy_bullets, e.pos, s.player.pos)

		dir := rl.Vector2Normalize(s.player.pos - e.pos)
		angle := math.atan2(dir.y, dir.x)

		for offset in ([]f32{-0.25, 0.25}) {
			a := angle + offset
			vel := rl.Vector2{math.cos(a) * ENEMY_BULLET_SPEED, math.sin(a) * ENEMY_BULLET_SPEED}
			for &b in s.enemy_bullets {
				if !b.alive {
					b = {
						pos   = e.pos,
						vel   = vel,
						alive = true,
					}
					break
				}
			}
		}
	case .Burst:
		fire_enemy_bullet(&s.enemy_bullets, e.pos, s.player.pos)
		e.burst_count = 2 // One more after this
		e.burst_timer = 0.12
	case .Boss:
		// Fan of bullets aimed at the player; more shots at low HP
		hp_frac := f32(e.hp) / f32(e.max_hp)
		count := BOSS_SPREAD_HIGH if hp_frac > 0.5 else BOSS_SPREAD_LOW
		base_angle := math.atan2(
			s.player.pos.y - e.pos.y,
			s.player.pos.x - e.pos.x,
		)
		step := f32(BOSS_SPREAD_STEP) * math.PI / 180.0
		half := f32(count / 2)
		for i in 0 ..< count {
			a := base_angle + (f32(i) - half) * step
			vel := rl.Vector2 {
				math.cos(a) * ENEMY_BULLET_SPEED,
				math.sin(a) * ENEMY_BULLET_SPEED,
			}
			for &b in s.enemy_bullets {
				if !b.alive {
					b = {pos = e.pos, vel = vel, alive = true}
					break
				}
			}
		}
	}
}

// Internal helper for powerup icons in HUD
draw_powerup_icon_hud :: proc(x, y, size: i32, label: cstring, color: rl.Color, frac: f32) {
	// Full colored background
	rl.DrawRectangle(x, y, size, size, color)
	// Grey overlay fills down from top as frac decreases (frac=1 full, frac=0 empty)
	grey_h := i32((1.0 - frac) * f32(size))
	if grey_h > 0 {
		rl.DrawRectangle(x, y, size, grey_h, {40, 40, 40, 200})
	}
	// Horizontal line at the boundary
	line_y := y + grey_h
	rl.DrawRectangle(x, line_y - 1, size, 2, rl.WHITE)
	// Border and label
	rl.DrawRectangleLines(x, y, size, size, rl.WHITE)
	rl.DrawText(label, x + size / 2 - 6, y + size / 2 - 6, 14, rl.WHITE)
}

// ---- Helpers ----

spawn_bullet :: proc(
	bullets: ^[MAX_BULLETS]Player_Bullet,
	pos: rl.Vector2,
	player_vel: rl.Vector2,
	is_rocket: bool,
	is_seeking: bool,
) {
	spd := f32(ROCKET_SPEED) if is_rocket else f32(BULLET_SPEED)
	vel := rl.Vector2{player_vel.x * 0.2, -spd}
	for &b in bullets {
		if !b.alive {
			b = {
				pos        = pos,
				vel        = vel,
				is_rocket  = is_rocket,
				is_seeking = is_seeking,
				alive      = true,
			}
			return
		}
	}
}

// Weights control relative drop frequency — higher = more common
POWERUP_WEIGHTS :: []int {
	int(Powerup_Type.Double_Shot) = 20,
	int(Powerup_Type.Score_Bonus) = 70,
	int(Powerup_Type.Exploding_Shot) = 5,
	int(Powerup_Type.Seeking_Shot) = 3,
}

drop_powerup :: proc(powerups: ^[MAX_POWERUPS]Powerup, pos: rl.Vector2) {
	total := 0
	for w in POWERUP_WEIGHTS {total += w}

	roll := int(rl.GetRandomValue(0, i32(total - 1)))
	type := Powerup_Type(0)
	cumulative := 0
	for w, i in POWERUP_WEIGHTS {
		cumulative += w
		if roll < cumulative {
			type = Powerup_Type(i)
			break
		}
	}

	for &p in powerups {
		if !p.alive {
			p = {
				pos   = pos,
				type  = type,
				alive = true,
			}
			return
		}
	}
}

powerup_color :: proc(type: Powerup_Type) -> rl.Color {
	switch type {
	case .Double_Shot:
		return {0, 180, 220, 200}
	case .Score_Bonus:
		return {220, 180, 0, 200}
	case .Exploding_Shot:
		return {220, 80, 0, 200}
	case .Seeking_Shot:
		return {180, 80, 255, 200}
	}
	return rl.WHITE
}

powerup_label :: proc(type: Powerup_Type) -> cstring {
	switch type {
	case .Double_Shot:
		return "2x"
	case .Score_Bonus:
		return "$"
	case .Exploding_Shot:
		return "X"
	case .Seeking_Shot:
		return "S"
	}
	return "?"
}

pick_weighted_variant :: proc(weights: [4]int) -> int {
	total := 0
	for w in weights {total += w}
	if total == 0 {return 0}
	roll := int(rl.GetRandomValue(0, i32(total - 1)))
	cumulative := 0
	for w, i in weights {
		cumulative += w
		if roll < cumulative {return i}
	}
	return 0
}

init_wave :: proc(config: Wave_Config, wave: int) -> [MAX_ENEMIES]Enemy {
	if config.is_boss {
		return init_boss_wave(config, wave)
	}
	return init_formation(config, wave)
}

init_boss_wave :: proc(config: Wave_Config, wave: int) -> [MAX_ENEMIES]Enemy {
	enemies: [MAX_ENEMIES]Enemy
	slot := rl.Vector2{f32(SCREEN_WIDTH) / 2, 200}
	enter_from := rl.Vector2{f32(SCREEN_WIDTH) / 2, -100}
	enter_ctrl := rl.Vector2{f32(SCREEN_WIDTH) / 2, 60}
	hp := config.boss_hp
	enemies[0] = Enemy {
		pos        = enter_from,
		slot       = slot,
		enter_from = enter_from,
		enter_ctrl = enter_ctrl,
		src        = rl.Rectangle{12, 724, 72, 72},
		alive      = true,
		state      = .Entering,
		enter_t    = 0,
		fire_timer = 2.0,
		dive_timer = 99999,
		wave       = wave,
		variant    = .Boss,
		hp         = hp,
		max_hp     = hp,
	}
	return enemies
}

init_formation :: proc(config: Wave_Config, wave: int) -> [MAX_ENEMIES]Enemy {
	enemies: [MAX_ENEMIES]Enemy
	rows := min(config.rows, FORMATION_ROWS_MAX)
	total := rows * FORMATION_COLS

	// Build all slots then shuffle so groups claim random grid positions
	slots: [MAX_ENEMIES]rl.Vector2
	for row in 0 ..< rows {
		for col in 0 ..< FORMATION_COLS {
			slots[row * FORMATION_COLS + col] = rl.Vector2 {
				f32(FORMATION_X_START + col * FORMATION_SPACING_X),
				f32(FORMATION_Y + row * FORMATION_SPACING_Y),
			}
		}
	}
	for i := total - 1; i > 0; i -= 1 {
		j := rl.GetRandomValue(0, i32(i))
		slots[i], slots[j] = slots[j], slots[i]
	}

	// ships_biomech.png: 3 cols × 64px wide, 4 colour sections each ~176px tall
	// Pick the middle column (x=64) and one sprite per section, flipped vertically
	biomech_sprites := [4]rl.Rectangle {
		{64, 96, 64, -96}, // section 1: brown/natural  → Standard
		{64, 272, 64, -96}, // section 2: dark/black    → Aggressive
		{64, 448, 64, -96}, // section 3: dark red      → Heavy
		{64, 624, 64, -96}, // section 4: pink/purple   → Burst
	}

	for i in 0 ..< total {
		slot := slots[i]
		group := i / FORMATION_COLS

		// Come from the side the slot is on
		from_left := slot.x < f32(SCREEN_WIDTH) / 2
		enter_from := rl.Vector2{-60, -60} if from_left else rl.Vector2{SCREEN_WIDTH + 60, -60}
		enter_ctrl :=
			rl.Vector2{-60, slot.y + 120} if from_left else rl.Vector2{SCREEN_WIDTH + 60, slot.y + 120}

		variant_idx := pick_weighted_variant(config.variant_weights)

		enemies[i] = Enemy {
			pos         = enter_from,
			slot        = slot,
			enter_from  = enter_from,
			enter_ctrl  = enter_ctrl,
			src         = biomech_sprites[variant_idx],
			alive       = true,
			state       = .Waiting,
			enter_delay = f32(group) * GROUP_STAGGER,
			dive_timer  = rand_dive_timer(),
			wave        = wave,
			variant     = Enemy_Variant(variant_idx),
			hp          = 1,
			max_hp      = 1,
		}
	}
	return enemies
}

spawn_blast :: proc(blasts: ^[MAX_BLASTS]Blast, pos: rl.Vector2) {
	for &bl in blasts {
		if !bl.alive {
			bl = {
				pos   = pos,
				t     = 0,
				alive = true,
			}
			return
		}
	}
}

spawn_hit_flash :: proc(flashes: ^[MAX_HIT_FLASHES]Hit_Flash, pos: rl.Vector2) {
	for &hf in flashes {
		if !hf.alive {
			hf = {
				pos   = pos,
				t     = 0,
				alive = true,
			}
			return
		}
	}
}

rand_dive_timer :: proc() -> f32 {
	t := f32(rl.GetRandomValue(0, 100)) / 100.0
	return DIVE_TIMER_MIN + t * (DIVE_TIMER_MAX - DIVE_TIMER_MIN)
}

spawn_explosion :: proc(particles: ^[MAX_PARTICLES]Particle, pos: rl.Vector2) {
	spawned := 0
	for &p in particles {
		if p.lifetime > 0 do continue
		if spawned >= 24 do break
		angle := f32(rl.GetRandomValue(0, 628)) * 0.01
		speed := f32(rl.GetRandomValue(60, 260))
		life := f32(rl.GetRandomValue(40, 90)) * 0.01
		p = Particle {
			pos      = pos,
			vel      = {math.cos(angle) * speed, math.sin(angle) * speed},
			lifetime = life,
			max_life = life,
			size     = f32(rl.GetRandomValue(2, 6)),
		}
		spawned += 1
	}
}

bezier2 :: proc(t: f32, p0, p1, p2: rl.Vector2) -> rl.Vector2 {
	q0 := rl.Vector2{p0.x + (p1.x - p0.x) * t, p0.y + (p1.y - p0.y) * t}
	q1 := rl.Vector2{p1.x + (p2.x - p1.x) * t, p1.y + (p2.y - p1.y) * t}
	return rl.Vector2{q0.x + (q1.x - q0.x) * t, q0.y + (q1.y - q0.y) * t}
}

fire_enemy_bullet :: proc(bullets: ^[MAX_ENEMY_BULLETS]Enemy_Bullet, from, target: rl.Vector2) {
	dx := target.x - from.x
	dy := target.y - from.y
	len := math.sqrt(dx * dx + dy * dy)
	if len == 0 do return
	vel := rl.Vector2{dx / len * ENEMY_BULLET_SPEED, dy / len * ENEMY_BULLET_SPEED}
	for &b in bullets {
		if !b.alive {
			b = {
				pos   = from,
				vel   = vel,
				alive = true,
			}
			return
		}
	}
}

rand_fire_timer :: proc(wave: int = 1) -> f32 {
	t := f32(rl.GetRandomValue(0, 100)) / 100.0
	base := ENEMY_FIRE_MIN + t * (ENEMY_FIRE_MAX - ENEMY_FIRE_MIN)
	scale := max(0.4, 1.0 - f32(wave - 1) * 0.08)
	return base * scale
}

STAR_COLORS :: []rl.Color {
	{255, 255, 255, 255}, // white       (most common)
	{255, 255, 255, 255}, //
	{255, 255, 255, 255}, //
	{255, 220, 180, 255}, // warm yellow
	{255, 200, 100, 255}, // orange-yellow
	{180, 200, 255, 255}, // cool blue
	{140, 160, 255, 255}, // deep blue
	{255, 140, 140, 255}, // red
}

random_star :: proc(spread: bool) -> Star {
	y := rl.GetRandomValue(0, SCREEN_HEIGHT) if spread else rl.GetRandomValue(-10, 0)
	speed := f32(rl.GetRandomValue(40, 200))
	size := f32(1) if speed < 100 else f32(2)
	twinkle_speed := f32(0)
	if rl.GetRandomValue(0, 2) == 0 {
		twinkle_speed = f32(rl.GetRandomValue(150, 400)) * 0.01
	}
	palette := STAR_COLORS
	color := palette[rl.GetRandomValue(0, i32(len(palette) - 1))]
	return Star {
		pos = {f32(rl.GetRandomValue(0, SCREEN_WIDTH)), f32(y)},
		speed = speed,
		size = size,
		twinkle_phase = f32(rl.GetRandomValue(0, 628)) * 0.01,
		twinkle_speed = twinkle_speed,
		color = color,
	}
}

update_seeking_bullet :: proc(s: ^Game_State, b: ^Player_Bullet, dt: f32) {
	// Seek closest enemy that is above the bullet
	target: ^Enemy = nil
	min_dist_sq := f32(1e9)

	for &e in s.enemies {
		if !e.alive do continue
		if e.pos.y > b.pos.y do continue // Already passed

		diff := e.pos - b.pos
		dist_sq := diff.x * diff.x + diff.y * diff.y
		if dist_sq < min_dist_sq {
			min_dist_sq = dist_sq
			target = &e
		}
	}

	if target != nil {
		desired_dir := rl.Vector2Normalize(target.pos - b.pos)
		current_dir := rl.Vector2Normalize(b.vel)

		// Smoothly rotate current_dir towards desired_dir
		// Using 2D cross product to find rotation direction
		cross := current_dir.x * desired_dir.y - current_dir.y * desired_dir.x
		angle := math.atan2(current_dir.y, current_dir.x)
		if cross > 0 {
			angle += SEEKING_TURN_RATE * dt
		} else {
			angle -= SEEKING_TURN_RATE * dt
		}

		spd := math.sqrt(b.vel.x * b.vel.x + b.vel.y * b.vel.y)
		b.vel.x = math.cos(angle) * spd
		b.vel.y = math.sin(angle) * spd
	}
}
