# game.wasm: game.c
#	clang \
#	-v \
#	--target=wasm32 \
#	--sysroot=/tmp/wasi-libc \
#	-nostartfiles \
#	-I./linux/include \
#	-I/tmp/wasi-libc/include/wasm32-wasi \
#	-L/tmp/wasi-libc/lib/wasm32-wasi \
#	-Wl,--no-entry \
#	-Wl,--unresolved-symbols=ignore-all \
#	-Wl,--import-undefined \
#	-Wl,--export=game_init,--export=game_frame,--export=game_over \
#	-DHAND_CRAFTED \
#	-o $@ $^ \
#	-lm

game.wasm: game.c
	clang \
	-v \
	--target=wasm32-unknown-wasi \
	--sysroot=/tmp/wasi-libc \
	-nostartfiles \
	-I./linux/include \
	-Wl,--no-entry \
	-Wl,--unresolved-symbols=ignore-all \
	-Wl,--import-undefined \
	-Wl,--export=game_init,--export=game_frame,--export=game_over \
	-DHAND_CRAFTED \
	-o $@ $^ \
	-lm

game_native: game.c
	clang -o $@ $^ -Ilinux/include -Llinux/lib '-l:libraylib.a' -lm

game_emcc: game.c
	emcc \
	-o game_emcc.html \
	$^ \
	-Wall \
	-Iwasm/include \
	-Lwasm/lib \
	'-l:libraylib.a' \
	-s USE_GLFW=3 \
	-s ASYNCIFY \
	--shell-file ./shell.html

.PHONY: clean

clean:
	rm -f game_native
	rm -f game.wasm
	rm -f game_emcc.{wasm,js,html}
