#+build js
package swarm

import js "core:sys/wasm/js"
import "core:fmt"
import "core:strconv"
import "core:strings"

save_settings :: proc(s: ^Game_State) {
	script := fmt.tprintf(
		"localStorage.setItem('swarm_settings','volume = %f')",
		s.volume,
	)
	js.evaluate(script)
}

load_settings :: proc(s: ^Game_State) {
	// First 4 bytes = length (little-endian u16 at [0..1]), rest = utf-8 data
	buf: [516]u8
	ptr := uintptr(&buf[0])

	// Use evaluate to copy localStorage value into WASM linear memory.
	// wasmMemoryInterface is accessible in odin.js's eval scope.
	script := fmt.tprintf(
		"(function(){var v=localStorage.getItem('swarm_settings');if(!v)return;var mem=new Uint8Array(wasmMemoryInterface.memory.buffer);var b=new TextEncoder().encode(v);var n=Math.min(b.length,511);mem[%d]=n&0xff;mem[%d]=(n>>8)&0xff;mem[%d]=0;mem[%d]=0;for(var i=0;i<n;i++)mem[%d+i]=b[i];})()",
		ptr, ptr + 1, ptr + 2, ptr + 3, ptr + 4,
	)
	js.evaluate(script)

	length := int(buf[0]) | (int(buf[1]) << 8)
	if length <= 0 || length > 511 do return

	content := string(buf[4 : 4 + length])
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
