/**
 * Permission Gate Extension
 *
 * Prompts for confirmation before running potentially dangerous bash commands.
 * Patterns checked: rm -r*, sudo, chmod/chown 777
 *
 * Copied from pi's examples/extensions/permission-gate.ts.
 * Changed: the rm pattern now matches any flag cluster containing "r"
 * (so `rm -fr`, `rm -Rf`, `rm -rvf` are caught, not just `rm -rf`).
 * Known limit: `rm -i -rf dir` (flags split apart) still slips through.
 */

import type { ExtensionAPI } from "@earendil-works/pi-coding-agent";

export default function (pi: ExtensionAPI) {
	const dangerousPatterns = [
		/\brm\s+(?:-\w*r\w*|--recursive)/i,
		/\bsudo\b/i,
		/\b(chmod|chown)\b.*777/i,
	];

	pi.on("tool_call", async (event, ctx) => {
		if (event.toolName !== "bash") return undefined;

		const command = event.input.command as string;
		const isDangerous = dangerousPatterns.some((p) => p.test(command));

		if (isDangerous) {
			if (!ctx.hasUI) {
				// In non-interactive mode, block by default
				return { block: true, reason: "Dangerous command blocked (no UI for confirmation)" };
			}

			const choice = await ctx.ui.select(`⚠️ Dangerous command:\n\n  ${command}\n\nAllow?`, ["Yes", "No"]);

			if (choice !== "Yes") {
				return { block: true, reason: "Blocked by user" };
			}
		}

		return undefined;
	});
}