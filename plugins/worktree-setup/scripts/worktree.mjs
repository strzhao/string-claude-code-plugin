#!/usr/bin/env node
// worktree.mjs — Claude Code worktree-setup plugin
// Unified entry: create / remove / repair
import { execSync, execFileSync } from 'child_process';
import { readFileSync, existsSync, mkdirSync, symlinkSync, lstatSync, unlinkSync, readdirSync, writeFileSync } from 'fs';
import { join, basename, dirname, resolve } from 'path';
import { fileURLToPath } from 'url';

const log = (msg) => process.stderr.write(msg + '\n');

// Shell-safe: uses execFileSync (array args) to avoid injection
function git(...args) {
  return execFileSync('git', args, { encoding: 'utf8', stdio: ['pipe', 'pipe', 'pipe'] }).trim();
}

function gitSilent(...args) {
  try { return git(...args); } catch { return ''; }
}

function readStdin() {
  let raw;
  try {
    raw = readFileSync(0, 'utf8');
  } catch (e) {
    throw new Error(`无法读取 stdin: ${e.message}`);
  }
  try {
    return JSON.parse(raw);
  } catch (e) {
    throw new Error(`stdin 不是合法 JSON: ${e.message}`);
  }
}

function repoRoot(cwd) {
  try {
    return git('-C', cwd, 'rev-parse', '--show-toplevel');
  } catch {
    return git('rev-parse', '--show-toplevel');
  }
}

// ─── Name sanitize ───
export function sanitizeName(raw) {
  return raw
    .replace(/\s/g, '-')
    .replace(/[^a-zA-Z0-9\u4e00-\u9fff._/-]/g, '-')
    .replace(/-{2,}/g, '-')
    .replace(/^-/, '')
    .replace(/-$/, '');
}

// ─── Deterministic port: hash(branch) → 4001-4999 ───
export function computePort(branch) {
  let h = 0;
  for (let i = 0; i < branch.length; i++) h = (h * 31 + branch.charCodeAt(i)) >>> 0;
  return 4001 + (h % 999);
}

// ─── Parse worktree-links file ───
export function parseLinksFile(filepath) {
  if (!existsSync(filepath)) return [];
  return readFileSync(filepath, 'utf8')
    .split('\n')
    .filter(line => line.trim() && !/^\s*#/.test(line))
    .map(line => line.trim());
}

// ─── REPAIR ───
function repair(worktreePath) {
  const root = repoRoot(worktreePath);
  log(`→ 修复 worktree: ${worktreePath}`);

  const linksFile = join(root, '.claude', 'worktree-links');
  const links = parseLinksFile(linksFile);

  if (links.length > 0) {
    log('→ 按 .claude/worktree-links 创建符号链接...');
    for (const file of links) {
      const src = join(root, file);
      const dst = join(worktreePath, file);
      const srcExists = existsSync(src);
      let dstExists = false;
      let dstIsLink = false;
      try { dstIsLink = lstatSync(dst).isSymbolicLink(); dstExists = true; } catch { /* not found */ }
      if (!dstExists) dstExists = existsSync(dst);

      if (srcExists && !dstExists) {
        const dir = dirname(dst);
        if (!existsSync(dir)) mkdirSync(dir, { recursive: true });
        symlinkSync(src, dst);
        log(`   ✓ 链接: ${file}`);
      } else if (dstIsLink) {
        log(`   — 已存在: ${file}`);
      } else if (!srcExists) {
        log(`   ⚠ 跳过（源文件不存在）: ${file}`);
      } else {
        log(`   — 已存在: ${file}`);
      }
    }
  } else {
    log('→ 无 .claude/worktree-links，自动链接 .env* 文件...');
    try {
      const entries = readdirSync(root).filter(f => f.startsWith('.env'));
      for (const file of entries) {
        const src = join(root, file);
        const dst = join(worktreePath, file);
        try {
          if (!lstatSync(src).isFile()) continue;
        } catch { continue; }
        if (!existsSync(dst)) {
          symlinkSync(src, dst);
          log(`   ✓ ${file}（自动）`);
        }
      }
    } catch { /* no .env files */ }
  }

  // Install dependencies
  const nodeModules = join(worktreePath, 'node_modules');
  if (!existsSync(nodeModules)) {
    log('→ 安装依赖（自动识别包管理器）...');
    const execOpts = { cwd: worktreePath, stdio: ['pipe', 'pipe', 'inherit'] };
    try {
      if (existsSync(join(worktreePath, 'pnpm-lock.yaml'))) {
        execSync('pnpm install', execOpts);
      } else if (existsSync(join(worktreePath, 'yarn.lock'))) {
        execSync('yarn install', execOpts);
      } else {
        execSync('npm install', execOpts);
      }
    } catch (e) {
      log(`   ⚠ 依赖安装失败: ${e.message}`);
    }
  } else {
    log('→ node_modules 已存在，跳过安装');
  }

  // Prisma generate
  if (existsSync(join(worktreePath, 'prisma'))) {
    log('→ 检测到 prisma 目录，执行 prisma generate...');
    try {
      execSync('npx prisma generate', { cwd: worktreePath, stdio: ['pipe', 'pipe', 'inherit'] });
    } catch (e) {
      log(`   ⚠ prisma generate 失败: ${e.message}`);
    }
  }

  log('✅ 修复完成');
}

// ─── CREATE ───
function create() {
  const input = readStdin();
  if (!input.name) throw new Error('stdin JSON 缺少 name 字段');
  const name = sanitizeName(input.name);
  if (!name) throw new Error(`名称清洗后为空: ${JSON.stringify(input.name)}`);
  const root = repoRoot(process.cwd());
  const worktreePath = join(root, '.claude', 'worktrees', name);
  const branch = `worktree-${name}`;

  log(`→ 创建 worktree: ${name} (分支: ${branch})`);

  // Detect default branch from origin
  let created = false;
  const hasOrigin = gitSilent('remote', 'show', 'origin');
  if (hasOrigin) {
    const headLine = hasOrigin.split('\n').find(l => l.includes('HEAD branch:'));
    const defaultBranch = headLine ? headLine.replace(/.*HEAD branch:\s*/, '').trim() : '';
    if (defaultBranch) {
      try {
        git('fetch', 'origin', defaultBranch);
        git('worktree', 'add', worktreePath, '-b', branch, `origin/${defaultBranch}`);
        created = true;
      } catch (e) {
        log(`   ⚠ 基于 origin/${defaultBranch} 创建失败: ${e.message}`);
      }
    }
  }

  if (!created) {
    log('→ 无 origin remote 或无法检测默认分支，基于当前 HEAD 创建');
    git('worktree', 'add', worktreePath, '-b', branch, 'HEAD');
  }

  // Repair: symlinks + deps
  repair(worktreePath);

  // Deterministic port
  const port = computePort(branch);
  log(`→ 分配端口: ${port}`);
  writeFileSync(
    join(worktreePath, 'local-config.json'),
    JSON.stringify({ server: { devPort: port, hostname: 'localhost', enableHttps: false } }) + '\n'
  );

  log(`✅ Worktree 就绪，dev 端口: ${port}`);
  process.stdout.write(worktreePath); // Only stdout — Claude reads this
}

// ─── REMOVE ───
function remove() {
  const input = readStdin();
  const worktreePath = input.worktree_path;
  if (!worktreePath) throw new Error('stdin JSON 缺少 worktree_path 字段');
  log(`→ 清理 worktree: ${worktreePath}`);

  const root = repoRoot(process.cwd());
  const linksFile = join(root, '.claude', 'worktree-links');
  const links = parseLinksFile(linksFile);

  // Remove symlinks first (avoid git worktree remove error on tracked files)
  if (links.length > 0) {
    for (const file of links) {
      const dst = join(worktreePath, file);
      try {
        if (lstatSync(dst).isSymbolicLink()) {
          unlinkSync(dst);
          log(`   ✓ 移除符号链接: ${file}`);
        }
      } catch { /* not a symlink or doesn't exist */ }
    }
  } else {
    // Fallback: scan .env*
    try {
      const entries = readdirSync(worktreePath).filter(f => f.startsWith('.env'));
      for (const file of entries) {
        const dst = join(worktreePath, file);
        try {
          if (lstatSync(dst).isSymbolicLink()) {
            unlinkSync(dst);
          }
        } catch { /* ignore */ }
      }
    } catch { /* dir may not exist */ }
  }

  // Remove local-config.json
  const configPath = join(worktreePath, 'local-config.json');
  if (existsSync(configPath)) unlinkSync(configPath);

  // Get branch name before removing worktree
  const branch = gitSilent('-C', worktreePath, 'rev-parse', '--abbrev-ref', 'HEAD');

  // Remove worktree
  git('worktree', 'remove', '--force', worktreePath);

  // Delete branch (unless main/HEAD)
  if (branch && branch !== 'main' && branch !== 'HEAD') {
    try {
      git('branch', '-D', branch);
      log(`   ✓ 分支已删除: ${branch}`);
    } catch { /* branch may not exist */ }
  }

  log('✅ 清理完成');
}

// ─── Main (only when run directly, not when imported) ───
const __filename = fileURLToPath(import.meta.url);
if (process.argv[1] && resolve(process.argv[1]) === __filename) {
  const subcmd = process.argv[2];

  try {
    switch (subcmd) {
      case 'create':
        create();
        break;
      case 'remove':
        remove();
        break;
      case 'repair':
        repair(process.argv[3] || process.cwd());
        break;
      default:
        log(`用法: node worktree.mjs <create|remove|repair> [worktree_path]`);
        process.exit(1);
    }
  } catch (e) {
    log(`❌ 错误: ${e.message}`);
    process.exit(1);
  }
}
