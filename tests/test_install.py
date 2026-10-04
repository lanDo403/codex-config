"""Run installer checks in temporary directories without changing user settings."""

import os
import shutil
import subprocess
import tempfile
import unittest
from pathlib import Path


REPO = Path(__file__).resolve().parents[1]


class InstallTest(unittest.TestCase):
    def test_installation_and_backups(self):
        backends = []
        if bash := shutil.which("bash"):
            backends.append(([bash, (REPO / "install.sh").as_posix()], "--skills-dir"))
        if powershell := shutil.which("powershell") or shutil.which("pwsh"):
            backends.append(([
                powershell, "-NoProfile", "-ExecutionPolicy", "Bypass",
                "-File", str(REPO / "install.ps1"),
            ], "-SkillsDir"))
        self.assertTrue(backends, "Bash or PowerShell is required to check the installers")
        for command, target_option in backends:
            with self.subTest(backend=command[0]), tempfile.TemporaryDirectory(
                prefix="install-check-", dir=REPO / "tests"
            ) as temporary:
                # Keep all writes and automatic cleanup inside the test workspace.
                sandbox = Path(temporary).resolve()
                self.assertTrue(sandbox.is_relative_to(REPO / "tests"))
                target = sandbox / "user profile & settings" / "skills"
                config = target.parent / ".codex"
                config.mkdir(parents=True)
                (config / "AGENTS.md").write_text("existing global instructions")
                (config / "RTK.md").write_text("existing RTK instructions")
                vault = sandbox / "vault & notes"
                tools = sandbox / "wiki tools"
                vault.mkdir()
                tools.mkdir()
                is_bash = target_option == "--skills-dir"

                def path_arg(path):
                    if is_bash and os.name == "nt":
                        return subprocess.check_output(
                            [command[0], "-c", 'cygpath -u "$1"', "bash", str(path)],
                            text=True,
                        ).strip()
                    return str(path)

                config_arg = path_arg(config)
                wiki_options = [
                    "--vault-path" if is_bash else "-VaultPath", path_arg(vault),
                    "--wiki-tools-path" if is_bash else "-WikiToolsPath", path_arg(tools),
                ]

                def run(selection, *extra, success=True):
                    result = subprocess.run(
                        [*command, selection, target_option, path_arg(target),
                         "--codex-dir" if is_bash else "-CodexDir", config_arg, *extra],
                        cwd=sandbox, capture_output=True, timeout=30,
                    )
                    if success:
                        self.assertEqual(result.returncode, 0, repr(result.stderr))
                    else:
                        self.assertNotEqual(result.returncode, 0)

                run("fpga-workflow")
                agents = (config / "AGENTS.md").read_text(encoding="utf-8")
                self.assertEqual(agents.splitlines()[0], "@" + config_arg.replace("\\", "/") + "/RTK.md")
                self.assertIn("<ТВОЙ ПУТЬ ДО VAULT>", agents)
                self.assertEqual([p.name for p in target.iterdir()], ["fpga-workflow"])
                self.assertEqual(
                    (target / "fpga-workflow/SKILL.md").read_bytes(),
                    (REPO / "skills/fpga-workflow/SKILL.md").read_bytes(),
                )
                (target / "fpga-workflow/custom.md").write_text("user customization")
                unrelated = target / "unrelated"
                unrelated.mkdir()
                (unrelated / "SKILL.md").write_text("unrelated skill")
                run("all", *wiki_options)
                run("all", *wiki_options)
                agents = (config / "AGENTS.md").read_text(encoding="utf-8")
                self.assertNotIn("<ТВОЙ", agents)
                self.assertIn(path_arg(vault).replace("\\", "/") + "/LLM WIKI", agents)
                self.assertIn(path_arg(tools).replace("\\", "/"), agents)
                self.assertIn(".venv/bin/python" if is_bash else ".venv/Scripts/python.exe", agents)
                self.assertEqual((config / "RTK.md").read_bytes(), (REPO / "codex/RTK.md").read_bytes())
                config_backups = config / "config-backups"
                self.assertEqual(len(list(config_backups.iterdir())), 3)
                self.assertIn("existing global instructions", [
                    p.read_text(encoding="utf-8") for p in config_backups.rglob("AGENTS.md")
                ])
                self.assertIn("existing RTK instructions", [
                    p.read_text(encoding="utf-8") for p in config_backups.rglob("RTK.md")
                ])
                for source in (REPO / "skills").rglob("*"):
                    if source.is_file():
                        self.assertEqual(
                            (target / source.relative_to(REPO / "skills")).read_bytes(),
                            source.read_bytes(),
                        )
                self.assertEqual((unrelated / "SKILL.md").read_text(), "unrelated skill")
                self.assertFalse((target / "fpga-workflow/custom.md").exists())
                backups = target.parent / "skill-backups"
                self.assertEqual(len(list(backups.iterdir())), 4)
                self.assertEqual(
                    [p.read_text() for p in backups.rglob("custom.md")],
                    ["user customization"],
                )
                self.assertEqual(len(list(target.rglob("SKILL.md"))), 4)
                before = {p.relative_to(sandbox): p.read_bytes()
                          for p in sandbox.rglob("*") if p.is_file()}
                run("../codex", success=False)
                run("missing-skill", success=False)
                run("all", "--claude", success=False)
                after = {p.relative_to(sandbox): p.read_bytes()
                         for p in sandbox.rglob("*") if p.is_file()}
                self.assertEqual(before, after)


if __name__ == "__main__":
    unittest.main()
