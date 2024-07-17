function makeEnvironment(envs) {
  return new Proxy(envs, {
    get(target, prop, receiver) {
      if (envs.hasOwnProperty(prop)) {
        return envs[prop];
      }
      return (...args) => {
        console.error("NOT IMPLEMENTED: " + prop, args)
      };
    }
  });
}

let previous = undefined;
let canvas = undefined;
let wasmExports = undefined;
let dt = 0;

function cStrLen(mem, ptr) {
  let len = 0;
  while (mem[ptr] != 0) {
    len++;
    ptr++;
  }
  return len;
}

function cStrByPtr(memBuf, ptr) {
  const mem = new Uint8Array(memBuf);
  const len = cStrLen(mem, ptr);
  const bytes = new Uint8Array(memBuf, ptr, len);
  return new TextDecoder().decode(bytes);
}


WebAssembly.instantiateStreaming(
  fetch('game.wasm'),
  {
    env: makeEnvironment({
      WindowShouldClose: () => false,
      InitWindow: async (width, height, titlePtr) => {
        canvas.width = width;
        canvas.height = height;
        document.title = cStrByPtr(wasmExports.memory.buffer, titlePtr);
      },
      SetTargetFPS: (fps) => {
        console.log(`The game wants to run at ${fps} FPS, but in Web we gonna just ignore it.`);
      },
      BeginDrawing: () => {
      },
      EndDrawing: () => {
      },
      ClearBackground: (colorPtr) => {
        const color = new Uint8Array(wasmExports.memory.buffer, colorPtr, 4);
        const colorHex = `#${((color[0] * (1 << 24)) + (color[1] * (1 << 16)) + (color[2] * (1 << 8)) + color[3]).toString(16)}`;
        const ctx = canvas.getContext('2d');
        ctx.fillStyle = colorHex;
        ctx.fillRect(0, 0, canvas.width, canvas.height);
      },
      GetScreenWidth: () => canvas.width,
      GetScreenHeight: () => canvas.height,
      GetFrameTime: () => dt,
      DrawCircleV: (center_ptr, radius, color_ptr) => {
        const buffer = wasmExports.memory.buffer;
        const [ x, y ] = new Float32Array(buffer, center_ptr, 2);
        const color = new Uint8Array(buffer, color_ptr, 4);
        const colorHex = `#${((color[0] * (1 << 24)) + (color[1] * (1 << 16)) + (color[2] * (1 << 8)) + color[3]).toString(16)}`
        const ctx = canvas.getContext('2d');
        ctx.beginPath();
        ctx.arc(x, y, radius, 0, 2 * Math.PI, false);
        ctx.fillStyle = colorHex;
        ctx.fill();
      }
    })
  }).then((w) => {
    wasmExports = w.instance.exports;
    canvas = document.getElementById('game');
    w.instance.exports.game_init();
    const step = (timeStamp) => {
      if (!previous) {
        previous = timeStamp;
      } else {
        dt = (timeStamp - previous) / 1000.0;
        previous = timeStamp;
        w.instance.exports.game_frame();
      }
      window.requestAnimationFrame(step);
    };
    window.requestAnimationFrame(step);
  });
