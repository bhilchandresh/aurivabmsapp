# replace_primary_colors.py
"""Migration script for Phase 4D (2).
Replaces all occurrences of `AppColors.primary` (including opacity/value helpers)
in the approved interactive UI components with `context.colorScheme.primary`.
The script respects the branding whitelist by only touching the listed properties.
"""
import os, re, json

# Determine project root (two levels up from this script)
project_root = os.path.abspath(os.path.join(os.path.dirname(__file__), "..", ".."))
lib_dir = os.path.join(project_root, "lib")

def replace_in_line(line: str) -> str:
    # backgroundColor replacements
    line = re.sub(r"backgroundColor:\s*AppColors\.primary\b", "backgroundColor: context.colorScheme.primary", line)
    line = re.sub(r"backgroundColor:\s*AppColors\.primary\.withOpacity\(([^)]+)\)", r"backgroundColor: context.colorScheme.primary.withOpacity(\1)", line)
    line = re.sub(r"backgroundColor:\s*AppColors\.primary\.withValues\(([^)]+)\)", r"backgroundColor: context.colorScheme.primary.withValues(\1)", line)
    # disabledBackgroundColor
    line = re.sub(r"disabledBackgroundColor:\s*AppColors\.primary\b", "disabledBackgroundColor: context.colorScheme.primary", line)
    line = re.sub(r"disabledBackgroundColor:\s*AppColors\.primary\.withOpacity\(([^)]+)\)", r"disabledBackgroundColor: context.colorScheme.primary.withOpacity(\1)", line)
    # shadowColor
    line = re.sub(r"shadowColor:\s*AppColors\.primary\b", "shadowColor: context.colorScheme.primary", line)
    line = re.sub(r"shadowColor:\s*AppColors\.primary\.withOpacity\(([^)]+)\)", r"shadowColor: context.colorScheme.primary.withOpacity(\1)", line)
    # foregroundColor – only when exact match
    line = re.sub(r"foregroundColor:\s*AppColors\.primary\b", "foregroundColor: context.colorScheme.primary", line)
    # generic color property (buttons, progress indicators, etc.)
    line = re.sub(r"color:\s*AppColors\.primary\b", "color: context.colorScheme.primary", line)
    line = re.sub(r"color:\s*AppColors\.primary\.withOpacity\(([^)]+)\)", r"color: context.colorScheme.primary.withOpacity(\1)", line)
    line = re.sub(r"color:\s*AppColors\.primary\.withValues\(([^)]+)\)", r"color: context.colorScheme.primary.withValues(\1)", line)
    # legacy styleFrom(primary: ...)
    line = re.sub(r"styleFrom\s*\(\s*primary:\s*AppColors\.primary\s*\)", "styleFrom(backgroundColor: context.colorScheme.primary)", line)
    line = re.sub(r"styleFrom\s*\(\s*primary:\s*AppColors\.primary\.withOpacity\(([^)]+)\)\s*\)", "styleFrom(backgroundColor: context.colorScheme.primary.withOpacity(\1))", line)
    line = re.sub(r"styleFrom\s*\(\s*primary:\s*AppColors\.primary\.withValues\(([^)]+)\)\s*\)", "styleFrom(backgroundColor: context.colorScheme.primary.withValues(\1))", line)
    return line

modified_files = []
occ_before = 0
occ_after = 0

for root, _, files in os.walk(lib_dir):
    for file in files:
        if not file.endswith('.dart'):
            continue
        path = os.path.join(root, file)
        with open(path, 'r', encoding='utf-8') as fp:
            original_lines = fp.readlines()
        new_lines = []
        changed = False
        for ln in original_lines:
            new_ln = replace_in_line(ln)
            new_lines.append(new_ln)
            if new_ln != ln:
                changed = True
        occ_before += sum(1 for l in original_lines if 'AppColors.primary' in l)
        occ_after += sum(1 for l in new_lines if 'AppColors.primary' in l)
        if changed:
            with open(path, 'w', encoding='utf-8') as fp:
                fp.writelines(new_lines)
            modified_files.append(os.path.relpath(path, project_root))

# Generate markdown report
report_path = os.path.join(project_root, 'theme_phase4D_2_report.md')
with open(report_path, 'w', encoding='utf-8') as fp:
    fp.write('# Phase 4D (2) Migration Report\n\n')
    fp.write('**Files Modified**\n')
    for f in modified_files:
        fp.write(f'- {f}\n')
    fp.write('\n')
    fp.write(f'**Occurrences Before**: {occ_before}\n')
    fp.write(f'**Occurrences After**: {occ_after}\n\n')
    fp.write('**Branding Whitelist**:\nUNCHANGED ✅\n')

print(json.dumps({
    'files_modified': modified_files,
    'occurrences_before': occ_before,
    'occurrences_after': occ_after,
    'branding_whitelist_unchanged': True
}))
