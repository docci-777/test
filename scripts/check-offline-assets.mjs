import { readFile, readdir } from "node:fs/promises";
import { fileURLToPath } from "node:url";
import { dirname, extname, join, resolve } from "node:path";

const root = resolve(dirname(fileURLToPath(import.meta.url)), "..");
const rootsToScan = [
  resolve(root, "apps/web/index.html"),
  resolve(root, "apps/web/src"),
  resolve(root, "apps/web/dist"),
];
const externalUrlPattern = /^(?:https?:|wss?:|\/\/)/i;
const sourceExtensions = new Set([".css", ".html", ".js", ".jsx", ".ts", ".tsx"]);
const buildExtensions = new Set([".css", ".html", ".js"]);

function stripComments(content, extension) {
  if (extension === ".css" || extension === ".js" || extension === ".jsx" || extension === ".ts" || extension === ".tsx") {
    return content
      .replace(/\/\*[\s\S]*?\*\//g, "")
      .replace(/(^|\s)\/\/.*$/gm, "$1");
  }
  return content;
}

function isExternalResource(value) {
  return externalUrlPattern.test(value.trim());
}

function collectReferences(content, extension, filePath) {
  const references = [];
  const withoutComments = stripComments(content, extension);
  const addMatches = (pattern, kind) => {
    for (const match of withoutComments.matchAll(pattern)) {
      const value = match[1].trim();
      if (isExternalResource(value)) {
        references.push({ file: filePath, kind, value });
      }
    }
  };

  if (extension === ".html" || extension === ".jsx" || extension === ".tsx") {
    addMatches(/(?:src|href)\s*=\s*["']([^"']+)["']/gi, "html-or-jsx-attribute");
  }
  if (extension === ".css") {
    addMatches(/url\(\s*["']?([^"')]+)["']?\s*\)/gi, "css-url");
    addMatches(/@import\s+["']([^"']+)["']/gi, "css-import");
  }
  if (extension === ".js" || extension === ".jsx" || extension === ".ts" || extension === ".tsx") {
    addMatches(/\b(?:fetch|import|new\s+URL|new\s+WebSocket)\s*\(\s*["']([^"']+)["']/g, "script-loader");
  }
  return references;
}

async function filesUnder(path, allowedExtensions) {
  const info = await readdir(path, { withFileTypes: true }).catch(() => null);
  if (info === null) {
    return [];
  }

  const files = [];
  for (const entry of info) {
    const entryPath = join(path, entry.name);
    if (entry.isDirectory()) {
      files.push(...await filesUnder(entryPath, allowedExtensions));
    } else if (allowedExtensions.has(extname(entry.name).toLowerCase())) {
      files.push(entryPath);
    }
  }
  return files;
}

async function collectFiles() {
  const files = [];
  for (const scanRoot of rootsToScan) {
    const extensionSet = scanRoot.endsWith("/dist") ? buildExtensions : sourceExtensions;
    if (scanRoot.endsWith(".html")) {
      files.push({ path: scanRoot, extensionSet });
      continue;
    }
    const info = await readdir(scanRoot, { withFileTypes: true }).catch(() => null);
    if (info === null) {
      continue;
    }
    for (const file of await filesUnder(scanRoot, extensionSet)) {
      files.push({ path: file, extensionSet });
    }
  }
  return files;
}

const files = await collectFiles();
const externalReferences = [];
for (const file of files) {
  const content = await readFile(file.path, "utf8");
  externalReferences.push(...collectReferences(content, extname(file.path).toLowerCase(), file.path));
}

const result = {
  scannedFiles: files.map((file) => file.path.replace(`${root}/`, "")),
  externalReferences,
};
console.log(JSON.stringify(result, null, 2));
if (externalReferences.length > 0) {
  process.exitCode = 1;
}
