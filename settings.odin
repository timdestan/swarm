package swarm

import "core:os"
import "core:fmt"
import "core:strings"
import "core:strconv"
import rl "vendor:raylib"

// ---- Settings UI Constants ----
SETTINGS_FILE :: "settings.cfg"

PAUSE_PANEL_W :: 360
PAUSE_PANEL_H :: 360
PAUSE_PANEL_X :: (SCREEN_WIDTH - PAUSE_PANEL_W) / 2
PAUSE_PANEL_Y :: (SCREEN_HEIGHT - PAUSE_PANEL_H) / 2

SLIDER_W :: 280
SLIDER_H :: 10
SLIDER_X :: PAUSE_PANEL_X + (PAUSE_PANEL_W - SLIDER_W) / 2
SLIDER_Y :: PAUSE_PANEL_Y + 120

RESUME_BTN_W :: 180
RESUME_BTN_H :: 44
RESUME_BTN_X :: PAUSE_PANEL_X + (PAUSE_PANEL_W - RESUME_BTN_W) / 2
RESUME_BTN_Y :: PAUSE_PANEL_Y + 190

QUIT_BTN_W :: 180
QUIT_BTN_H :: 44
QUIT_BTN_X :: PAUSE_PANEL_X + (PAUSE_PANEL_W - QUIT_BTN_W) / 2
QUIT_BTN_Y :: PAUSE_PANEL_Y + 250

save_settings :: proc(s: ^Game_State) {
	f, err := os.open(SETTINGS_FILE, os.O_WRONLY | os.O_CREATE | os.O_TRUNC)
	if err != 0 {
		fmt.eprintln("Failed to open settings file for writing:", err)
		return
	}
	defer os.close(f)

	fmt.fprintf(f, "volume = %f\n", s.volume)
}

load_settings :: proc(s: ^Game_State) {
	fd, err := os.open(SETTINGS_FILE, os.O_RDONLY)
	if err != 0 do return
	defer os.close(fd)

	size, _ := os.file_size(fd)
	if size <= 0 do return

	data := make([]byte, int(size), context.allocator)
	defer delete(data, context.allocator)

	_, read_err := os.read(fd, data)
	if read_err != 0 do return

	content := string(data)
	lines := strings.split(content, "\n", context.allocator)
	defer delete(lines, context.allocator)

	for line in lines {
		trimmed := strings.trim_space(line)
		if trimmed == "" || strings.has_prefix(trimmed, "#") do continue

		parts := strings.split(trimmed, "=", context.allocator)
		defer delete(parts, context.allocator)

		if len(parts) == 2 {
			key := strings.trim_space(parts[0])
			val_str := strings.trim_space(parts[1])

			if key == "volume" {
				val, parse_ok := strconv.parse_f32(val_str)
				if parse_ok {
					s.volume = val
				}
			}
		}
	}
}

update_settings_menu :: proc(s: ^Game_State, dt: f32) {
	if s.save_timer > 0 {
		s.save_timer -= dt
		if s.save_timer <= 0 {
			save_settings(s)
		}
	}

	if rl.IsKeyPressed(.ESCAPE) {
		prev_paused := s.paused
		s.paused = !s.paused
		if prev_paused && !s.paused {
			save_settings(s)
			s.save_timer = 0 // cancel any pending timer
		}
	}

	if s.paused {
		mouse := rl.GetMousePosition()
		if rl.IsMouseButtonDown(.LEFT) {
			// Broad collision check for the slider to make it easy to grab
			if mouse.y > SLIDER_Y - 40 && mouse.y < SLIDER_Y + 40 &&
			   mouse.x > SLIDER_X - 20 && mouse.x < SLIDER_X + SLIDER_W + 20 {
				new_vol := clamp((mouse.x - SLIDER_X) / SLIDER_W, 0, 1)
				if new_vol != s.volume {
					s.volume = new_vol
					s.save_timer = 0.5 // delay save
				}
			}
		}

		if rl.IsMouseButtonPressed(.LEFT) {
			if rl.CheckCollisionPointRec(mouse, {RESUME_BTN_X, RESUME_BTN_Y, RESUME_BTN_W, RESUME_BTN_H}) {
				s.paused = false
				save_settings(s)
				s.save_timer = 0
			}
			if rl.CheckCollisionPointRec(mouse, {QUIT_BTN_X, QUIT_BTN_Y, QUIT_BTN_W, QUIT_BTN_H}) {
				s.quit_game = true
			}
		}
	}
}

draw_settings_menu :: proc(s: ^Game_State) {
	if s.paused {
		rl.DrawRectangle(0, 0, SCREEN_WIDTH, SCREEN_HEIGHT, {0, 0, 0, 180})

		// Panel shadow/backdrop
		rl.DrawRectangleRounded(
			rl.Rectangle{PAUSE_PANEL_X + 4, PAUSE_PANEL_Y + 4, PAUSE_PANEL_W, PAUSE_PANEL_H},
			0.1,
			8,
			rl.Color{0, 0, 0, 100},
		)
		rl.DrawRectangleRounded(
			rl.Rectangle{PAUSE_PANEL_X, PAUSE_PANEL_Y, PAUSE_PANEL_W, PAUSE_PANEL_H},
			0.1,
			8,
			rl.Color{20, 20, 25, 255},
		)
		rl.DrawRectangleRoundedLines(
			rl.Rectangle{PAUSE_PANEL_X, PAUSE_PANEL_Y, PAUSE_PANEL_W, PAUSE_PANEL_H},
			0.1,
			8,
			rl.Color{80, 80, 100, 255},
		)

		title :: "PAUSED"
		title_size :: 32
		title_w := rl.MeasureText(title, title_size)
		rl.DrawText(
			title,
			SCREEN_WIDTH / 2 - title_w / 2,
			i32(PAUSE_PANEL_Y) + 30,
			title_size,
			rl.GOLD,
		)

		// Volume Setting
		rl.DrawText("VOLUME", i32(SLIDER_X), i32(SLIDER_Y) - 30, 18, rl.LIGHTGRAY)

		rl.DrawRectangleRounded(
			rl.Rectangle{SLIDER_X, SLIDER_Y, SLIDER_W, f32(SLIDER_H)},
			1.0,
			4,
			rl.Color{50, 50, 60, 255},
		)
		rl.DrawRectangleRounded(
			rl.Rectangle{SLIDER_X, SLIDER_Y, SLIDER_W * s.volume, f32(SLIDER_H)},
			1.0,
			4,
			rl.GOLD,
		)

		handle_x := SLIDER_X + s.volume * SLIDER_W
		handle_y := SLIDER_Y + f32(SLIDER_H) / 2

		mouse := rl.GetMousePosition()
		is_hovering_slider := rl.CheckCollisionPointCircle(mouse, rl.Vector2{handle_x, handle_y}, 12)
		handle_color := is_hovering_slider ? rl.WHITE : rl.GOLD

		rl.DrawCircleV(rl.Vector2{handle_x, handle_y}, 10, handle_color)
		if is_hovering_slider {
			rl.DrawCircleLines(i32(handle_x), i32(handle_y), 14, {255, 255, 255, 120})
		}

		// Resume Button
		resume_hover := rl.CheckCollisionPointRec(
			mouse,
			{RESUME_BTN_X, RESUME_BTN_Y, RESUME_BTN_W, RESUME_BTN_H},
		)
		resume_color := resume_hover ? rl.Color{60, 100, 60, 255} : rl.Color{40, 80, 40, 255}

		rl.DrawRectangleRounded(
			{RESUME_BTN_X, RESUME_BTN_Y, RESUME_BTN_W, RESUME_BTN_H},
			0.2,
			8,
			resume_color,
		)
		rl.DrawRectangleRoundedLines(
			{RESUME_BTN_X, RESUME_BTN_Y, RESUME_BTN_W, RESUME_BTN_H},
			0.2,
			8,
			rl.LIME,
		)

		resume_text_w := rl.MeasureText("RESUME", 20)
		rl.DrawText(
			"RESUME",
			i32(RESUME_BTN_X + RESUME_BTN_W / 2) - resume_text_w / 2,
			i32(RESUME_BTN_Y + RESUME_BTN_H / 2) - 10,
			20,
			rl.RAYWHITE,
		)

		// Quit Button
		quit_hover := rl.CheckCollisionPointRec(
			mouse,
			{QUIT_BTN_X, QUIT_BTN_Y, QUIT_BTN_W, QUIT_BTN_H},
		)
		quit_color := quit_hover ? rl.Color{60, 30, 30, 255} : rl.Color{40, 20, 20, 255}

		rl.DrawRectangleRounded(
			{QUIT_BTN_X, QUIT_BTN_Y, QUIT_BTN_W, QUIT_BTN_H},
			0.2,
			8,
			quit_color,
		)
		rl.DrawRectangleRoundedLines(
			{QUIT_BTN_X, QUIT_BTN_Y, QUIT_BTN_W, QUIT_BTN_H},
			0.2,
			8,
			rl.MAROON,
		)

		quit_text_w := rl.MeasureText("QUIT", 20)
		rl.DrawText(
			"QUIT",
			i32(QUIT_BTN_X + QUIT_BTN_W / 2) - quit_text_w / 2,
			i32(QUIT_BTN_Y + QUIT_BTN_H / 2) - 10,
			20,
			rl.RAYWHITE,
		)

		hint :: "Press ESC to Resume"
		hint_size :: 16
		hint_w := rl.MeasureText(hint, hint_size)
		rl.DrawText(
			hint,
			SCREEN_WIDTH / 2 - hint_w / 2,
			i32(PAUSE_PANEL_Y + PAUSE_PANEL_H) - 30,
			hint_size,
			rl.GRAY,
		)
	}
}
