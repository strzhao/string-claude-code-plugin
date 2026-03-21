/**
 * Acceptance tests for README.md autopilot version update.
 *
 * Red-team verification: tests are written purely from the design document,
 * without reading the blue-team implementation.
 *
 * Design spec:
 *   README.md autopilot version must be v2.9.0 (not v2.0.0),
 *   consistent with CLAUDE.md.
 *
 * Run: node --test tests/readme-autopilot-version.acceptance.test.mjs
 */

import { describe, it } from 'node:test';
import assert from 'node:assert/strict';
import { readFile } from 'node:fs/promises';
import { resolve, dirname } from 'node:path';
import { fileURLToPath } from 'node:url';

const __dirname = dirname(fileURLToPath(import.meta.url));
const README_PATH = resolve(__dirname, '..', 'README.md');
const CLAUDE_MD_PATH = resolve(__dirname, '..', 'CLAUDE.md');

describe('README.md autopilot version (v2.9.0)', () => {
  it('README.md contains autopilot v2.9.0', async () => {
    const content = await readFile(README_PATH, 'utf-8');
    assert.ok(
      content.includes('v2.9.0'),
      'README.md must contain "v2.9.0" for autopilot'
    );
  });

  it('README.md does not contain the old autopilot v2.0.0', async () => {
    const content = await readFile(README_PATH, 'utf-8');
    // Find lines mentioning autopilot and v2.0.0 together
    const lines = content.split('\n');
    const oldVersionLine = lines.find(
      (line) => line.includes('autopilot') && line.includes('v2.0.0')
    );
    assert.equal(
      oldVersionLine,
      undefined,
      'README.md must not contain autopilot with version "v2.0.0"'
    );
  });

  it('autopilot version in README.md matches CLAUDE.md', async () => {
    const [readmeContent, claudeContent] = await Promise.all([
      readFile(README_PATH, 'utf-8'),
      readFile(CLAUDE_MD_PATH, 'utf-8'),
    ]);

    // Extract autopilot version from CLAUDE.md (pattern: "autopilot (vX.Y.Z)")
    const claudeMatch = claudeContent.match(/autopilot\s*\(v(\d+\.\d+\.\d+)\)/);
    assert.ok(claudeMatch, 'CLAUDE.md must declare an autopilot version');
    const claudeVersion = claudeMatch[1];

    // Extract autopilot version from README.md
    const readmeMatch = readmeContent.match(/autopilot\s*\(v(\d+\.\d+\.\d+)\)/);
    assert.ok(readmeMatch, 'README.md must declare an autopilot version');
    const readmeVersion = readmeMatch[1];

    assert.equal(
      readmeVersion,
      claudeVersion,
      `README.md autopilot version (v${readmeVersion}) must match CLAUDE.md (v${claudeVersion})`
    );
  });

  it('the version appears on the autopilot heading line', async () => {
    const content = await readFile(README_PATH, 'utf-8');
    const lines = content.split('\n');
    const headingLine = lines.find(
      (line) => line.includes('autopilot') && /^#+\s/.test(line.trim())
    );
    assert.ok(headingLine, 'README.md must have an autopilot heading');
    assert.ok(
      headingLine.includes('v2.9.0'),
      `Autopilot heading must show v2.9.0, got: "${headingLine.trim()}"`
    );
  });
});
