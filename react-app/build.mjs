import { build } from "esbuild";
import { mkdir, readFile, writeFile, cp, rm } from "node:fs/promises";
await rm("dist", { recursive: true, force: true });
await mkdir("dist/assets", { recursive: true });
await cp("public", "dist", { recursive: true });
const result = await build({
  entryPoints: { app: "src/main.jsx", admin: "src/admin.jsx" },
  bundle: true, minify: true, metafile: true, outdir: "dist",
  entryNames: "assets/[name]-[hash]", assetNames: "assets/[name]-[hash]",
  define: { "process.env.NODE_ENV": JSON.stringify("production") }
});
for (const [page, entry] of [["index", "main"], ["admin", "admin"]]) {
  const [js, info] = Object.entries(result.metafile.outputs).find(([, v]) => v.entryPoint === `src/${entry}.jsx`);
  const script = js.replace(/^dist/, "");
  const css = info.cssBundle.replace(/^dist/, "");
  const template = await readFile(`${page}.html`, "utf8");
  await writeFile(`dist/${page}.html`, template.replace("{{script}}", script).replace("{{css}}", css));
}
console.log("Built public showroom and administrator portal.");
