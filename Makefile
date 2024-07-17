game_emcc: game.c
	emcc -o game_emcc.html $^ -Os -Wall -I. -Iwasm/include -Lwasm/lib '-l:libraylib.a' -s USE_GLFW=3 -s ASYNCIFY --shell-file ./shell.html -DPLATFORM_WEB

game2.wasm: game.c
	clang \
	-v \
	--target=wasm32 \
	--sysroot=/tmp/wasi-libc \
	-Wl,--verbose \
	-I./wasm/include \
	-L./wasm/lib \
	-I/tmp/wasi-libc/include/wasm32-wasi \
	-L/tmp/wasi-libc/lib/wasm32-wasi \
	-o $@ $^ \
	'-l:libraylib.a' \
	-lm

game.wasm: game.c
	clang \
	-v \
	--target=wasm32 \
	--sysroot=/tmp/wasi-libc \
	-nostartfiles \
	-I./linux/include \
	-I/tmp/wasi-libc/include/wasm32-wasi \
	-L/tmp/wasi-libc/lib/wasm32-wasi \
	-Wl,--no-entry \
	-Wl,--unresolved-symbols=ignore-all \
	-Wl,--import-undefined \
	-Wl,--export=game_init,--export=game_frame,--export=game_over \
	-DPLATFORM_WEB \
	-o $@ $^ \
	-lm

game_native: game.c
	clang -o $@ $^ -Ilinux/include -Llinux/lib '-l:libraylib.a' -lm

.PHONY: clean

clean:
	rm -f game_native
	rm -f game.wasm
