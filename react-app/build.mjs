import { build } from "esbuild";
import { mkdir, copyFile, rm } from "node:fs/promises";

await rm("dist", { recursive: true, force: true });
await mkdir("dist", { recursive: true });

await build({
  entryPoints: ["src/main.jsx"],
  bundle: true,
  minify: true,
  outfile: "dist/app.js",
  define: {
    "process.env.NODE_ENV": JSON.stringify("production")
  }
});

await copyFile("index.html", "dist/index.html");

console.log("React build completed.");