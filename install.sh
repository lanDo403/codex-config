#!/usr/bin/env bash
set -euo pipefail

# Install local skills and global rules for Codex. Windows users can use install.ps1.

repo_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)"
skills_dir="$repo_dir/skills"

usage() {
  echo "Usage: bash $0 <skill-name|all> [--skills-dir PATH]" >&2
  echo "  [--codex-dir PATH] [--vault-path PATH] [--wiki-tools-path PATH]" >&2
  echo "Available skills:" >&2
  for d in "$skills_dir"/*/; do
    [ -d "$d" ] || continue
    echo "  - $(basename "$d")" >&2
  done
}

if [ "${1:-}" = "--help" ]; then
  usage
  exit 0
fi
if [ $# -lt 1 ]; then
  usage
  exit 2
fi

selection="$1"
shift

target_root="$HOME/.agents/skills"
codex_dir="${CODEX_HOME:-$HOME/.codex}"
vault_path=""
wiki_tools_path=""
while [ $# -gt 0 ]; do
  case "$1" in
    --skills-dir|--codex-dir|--vault-path|--wiki-tools-path)
      [ $# -ge 2 ] && [ -n "$2" ] || { usage; exit 2; }
      case "$1" in
        --skills-dir) target_root="$2" ;;
        --codex-dir) codex_dir="$2" ;;
        --vault-path) vault_path="$2" ;;
        --wiki-tools-path) wiki_tools_path="$2" ;;
      esac
      shift 2
      ;;
    *) usage; exit 2 ;;
  esac
done

install_one() {
  local name="$1"
  local source_dir="$skills_dir/$name"
  local target_dir="$target_root/$name"

  if [ -e "$target_dir" ] || [ -L "$target_dir" ]; then
    mkdir -p "$backup_root"
    local backup_dir
    backup_dir="$(mktemp -d "$backup_root/$name.backup-$(date +%Y%m%d-%H%M%S)-XXXXXX")"
    mv -- "$target_dir" "$backup_dir/$name"
    echo "Backed up existing skill to: $backup_dir"
  fi

  cp -a -- "$source_dir" "$target_dir"

  if [ -d "$target_dir/scripts" ]; then
    find "$target_dir/scripts" -type f \( -name '*.sh' -o -name '*.py' -o -name '*.js' \) -exec chmod +x {} +
  fi

  echo "Installed $name -> $target_dir"
}

if [ "$selection" = "all" ]; then
  names=()
  for d in "$skills_dir"/*/; do
    [ -f "$d/SKILL.md" ] || continue
    names+=("$(basename "$d")")
  done
else
  names=("$selection")
fi

if [ "${#names[@]}" -eq 0 ]; then
  echo "No skills found in: $skills_dir" >&2
  exit 1
fi
for name in "${names[@]}"; do
  if [[ ! "$name" =~ ^[a-zA-Z0-9][a-zA-Z0-9._-]*$ ]] || [ ! -f "$skills_dir/$name/SKILL.md" ]; then
    echo "Skill not found or invalid name: $name" >&2
    exit 1
  fi
done

for config_file in AGENTS.md RTK.md; do
  [ -f "$repo_dir/codex/$config_file" ] || { echo "Missing global rules: $config_file" >&2; exit 1; }
done
[ -z "$vault_path" ] || vault_path="$(cd -- "$vault_path" && pwd -P)"
[ -z "$wiki_tools_path" ] || wiki_tools_path="$(cd -- "$wiki_tools_path" && pwd -P)"
mkdir -p "$target_root"
target_root="$(cd -- "$target_root" && pwd -P)"
if [[ "$target_root" = "$skills_dir" || "$target_root" = "$skills_dir/"* ]]; then
  echo "Installation target must be outside the source skills directory." >&2
  exit 1
fi
mkdir -p "$codex_dir"
codex_dir="$(cd -- "$codex_dir" && pwd -P)"
if [[ "$codex_dir" = "$repo_dir/codex" || "$codex_dir" = "$repo_dir/codex/"* ]]; then
  echo "Codex directory must be outside the source rules directory." >&2
  exit 1
fi
for config_file in AGENTS.md RTK.md; do
  if [ -L "$codex_dir/$config_file" ] || { [ -e "$codex_dir/$config_file" ] && [ ! -f "$codex_dir/$config_file" ]; }; then
    echo "Global rules target must be a regular file: $codex_dir/$config_file" >&2
    exit 1
  fi
done
backup_root="$(dirname -- "$target_root")/skill-backups"
for name in "${names[@]}"; do
  install_one "$name"
done

config_backup=""
for config_file in AGENTS.md RTK.md; do
  if [ -f "$codex_dir/$config_file" ]; then
    if [ -z "$config_backup" ]; then
      mkdir -p "$codex_dir/config-backups"
      config_backup="$(mktemp -d "$codex_dir/config-backups/install-$(date +%Y%m%d-%H%M%S)-XXXXXX")"
    fi
    cp -a -- "$codex_dir/$config_file" "$config_backup/$config_file"
  fi
done
[ -z "$config_backup" ] || echo "Backed up global rules to: $config_backup"
agents_temp="$(mktemp "$codex_dir/.AGENTS.md-XXXXXX")"
while IFS= read -r line || [ -n "$line" ]; do
  line="${line//'<ТВОЙ ПУТЬ>/RTK.md'/"$codex_dir/RTK.md"}"
  line="${line//'.venv/Scripts/python.exe'/'.venv/bin/python'}"
  [ -z "$vault_path" ] || line="${line//'<ТВОЙ ПУТЬ ДО VAULT>'/"$vault_path"}"
  [ -z "$wiki_tools_path" ] || line="${line//'<ТВОЙ ПУТЬ>'/"$wiki_tools_path"}"
  printf '%s\n' "$line"
done < "$repo_dir/codex/AGENTS.md" > "$agents_temp"
mv -- "$agents_temp" "$codex_dir/AGENTS.md"
cp -a -- "$repo_dir/codex/RTK.md" "$codex_dir/RTK.md"
echo "Installed global rules -> $codex_dir"
if [ -z "$vault_path" ] || [ -z "$wiki_tools_path" ]; then
  echo "Wiki placeholders remain in AGENTS.md. Set --vault-path and --wiki-tools-path or edit them manually."
fi
echo "Done. Restart Codex if the installed skills do not appear."
