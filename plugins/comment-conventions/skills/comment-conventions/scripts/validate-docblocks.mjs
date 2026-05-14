#!/usr/bin/env node
// validate-docblocks.mjs
//
// Enforces Rule 4 of the comment-conventions skill: a docblock's prose
// description has at most 3 source lines, and each line is strictly
// shorter (in characters) than the line before it.
//
// Currently handles JSDoc-style /** ... */ blocks, which cover JS, TS,
// PHP, Java, Kotlin, Swift, C#, C/C++ and Rust (/** */ form). Python
// triple-quote docstrings and Rustdoc /// blocks are not yet parsed —
// for those files, verify Rule 4 manually for now.
//
// Usage:
//   node validate-docblocks.mjs <file> [<file>...]
//
// Exit codes:
//   0  no violations
//   1  one or more violations
//   2  usage error (missing arg, unreadable file)

import { readFileSync } from 'node:fs';
import { argv, exit, stderr, stdout } from 'node:process';

const files = argv.slice(2);
if (files.length === 0) {
  stderr.write('Usage: validate-docblocks.mjs <file> [<file>...]\n');
  exit(2);
}

let violationCount = 0;
let unreadable = false;

for (const file of files) {
  let content;
  try {
    content = readFileSync(file, 'utf8');
  } catch (err) {
    stderr.write(`${file}: cannot read (${err.message})\n`);
    unreadable = true;
    continue;
  }
  for (const v of findViolations(content)) {
    stdout.write(`${file}:${v.line}: ${v.message}\n`);
    violationCount++;
  }
}

if (unreadable) exit(2);
if (violationCount === 0) {
  stdout.write(`OK: no docblock violations in ${files.length} file(s)\n`);
}
exit(violationCount > 0 ? 1 : 0);

function findViolations(content) {
  const lines = content.split('\n');
  const violations = [];

  let i = 0;
  while (i < lines.length) {
    const openIdx = lines[i].indexOf('/**');
    if (openIdx === -1) {
      i++;
      continue;
    }
    // Skip single-line blocks: /** stuff */ on one line carries no prose
    // pyramid to validate.
    const afterOpen = lines[i].slice(openIdx + 3);
    if (afterOpen.includes('*/')) {
      i++;
      continue;
    }

    const blockStartLine = i + 1;
    const prose = [];
    let j = i + 1;
    while (j < lines.length) {
      const raw = lines[j];
      if (raw.includes('*/')) break;
      // Strip leading indentation + optional ` * ` continuation marker,
      // then trailing whitespace.
      const stripped = raw.replace(/^\s*\*\s?/, '').replace(/\s+$/, '');
      if (stripped === '') break;
      if (stripped.startsWith('@')) break;
      prose.push({ text: stripped, line: j + 1 });
      j++;
    }
    violations.push(...checkProse(prose, blockStartLine));
    i = j + 1;
  }
  return violations;
}

function checkProse(prose, blockStartLine) {
  const out = [];
  if (prose.length === 0) return out;

  if (prose.length > 3) {
    out.push({
      line: prose[3].line,
      message: `docblock prose has ${prose.length} lines, max is 3 (block starts at line ${blockStartLine})`,
    });
  }

  const checked = prose.slice(0, 3);
  for (let k = 1; k < checked.length; k++) {
    const cur = checked[k];
    const prev = checked[k - 1];
    if (cur.text.length >= prev.text.length) {
      out.push({
        line: cur.line,
        message: `line is ${cur.text.length} chars; must be strictly shorter than previous (${prev.text.length} chars) — block starts at line ${blockStartLine}`,
      });
    }
  }
  return out;
}
