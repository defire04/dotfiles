import * as fs from "node:fs";
import * as os from "node:os";
import * as path from "node:path";
import type { ExtensionAPI } from "@earendil-works/pi-coding-agent";

// Pi сам читает CLAUDE.md. Это расширение добавляет остальное из .claude, как у Claude Code:
// скилы ~/.claude/skills и <проект>/.claude/skills, команды <проект>/.claude/commands,
// а в системный промт список правил .claude/rules/*.md и заметок .claude/*.md (RESUME.md, PLAN.md).

function isDir(p: string): boolean {
	try {
		return fs.statSync(p).isDirectory();
	} catch {
		return false;
	}
}

function skillDirs(root: string): string[] {
	if (!isDir(root)) return [];
	return fs
		.readdirSync(root)
		.map((name) => path.join(root, name))
		.filter((dir) => fs.existsSync(path.join(dir, "SKILL.md")));
}

function projectDirs(cwd: string): string[] {
	const dirs: string[] = [];
	let dir = path.resolve(cwd);
	const home = os.homedir();
	while (true) {
		if (dir !== home) dirs.push(dir);
		if (fs.existsSync(path.join(dir, ".git")) || dir === path.dirname(dir) || dir === home) break;
		dir = path.dirname(dir);
	}
	return dirs;
}

function markdownFiles(dir: string, base = ""): string[] {
	if (!isDir(dir)) return [];
	const out: string[] = [];
	for (const entry of fs.readdirSync(dir, { withFileTypes: true })) {
		const rel = base ? `${base}/${entry.name}` : entry.name;
		if (entry.isDirectory()) out.push(...markdownFiles(path.join(dir, entry.name), rel));
		else if (entry.isFile() && entry.name.endsWith(".md")) out.push(rel);
	}
	return out;
}

export default function claudeCompat(pi: ExtensionAPI) {
	let notes: string[] = [];

	pi.on("resources_discover", async (event) => {
		const projects = projectDirs(event.cwd);
		const skillPaths = [
			...skillDirs(path.join(os.homedir(), ".claude", "skills")),
			...projects.flatMap((dir) => skillDirs(path.join(dir, ".claude", "skills"))),
		];
		const promptPaths = projects
			.map((dir) => path.join(dir, ".claude", "commands"))
			.filter(isDir);
		return { skillPaths, promptPaths };
	});

	pi.on("session_start", async (_event, ctx) => {
		notes = projectDirs(ctx.cwd).flatMap((dir) => {
			const claude = path.join(dir, ".claude");
			const top = isDir(claude)
				? fs.readdirSync(claude).filter((name) => name.endsWith(".md"))
				: [];
			const rules = markdownFiles(path.join(claude, "rules")).map((rel) => `rules/${rel}`);
			return [...top, ...rules].map((rel) => path.relative(ctx.cwd, path.join(claude, rel)) || rel);
		});
	});

	pi.on("before_agent_start", async (event) => {
		if (notes.length === 0) return;
		const list = notes.map((file) => `- ${file}`).join("\n");
		return {
			systemPrompt: `${event.systemPrompt}

## Файлы проекта в .claude

В проекте есть заметки и правила для агента (их вёл Claude Code). Прочитай нужные инструментом read, когда задача
их касается: RESUME.md и PLAN.md в начале работы, правила из rules/ перед правкой той части кода, о которой они.

${list}
`,
		};
	});
}
