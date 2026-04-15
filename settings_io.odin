#+build !js
package swarm

import "core:fmt"
import "core:os"
import "core:strconv"
import "core:strings"

SETTINGS_FILE :: "settings.cfg"

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

	data := make([]byte, int(size))
	defer delete(data)

	_, read_err := os.read(fd, data)
	if read_err != 0 do return

	content := string(data)
	lines := strings.split(content, "\n")
	defer delete(lines)

	for line in lines {
		trimmed := strings.trim_space(line)
		if trimmed == "" || strings.has_prefix(trimmed, "#") do continue

		parts := strings.split(trimmed, "=")
		defer delete(parts)

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
