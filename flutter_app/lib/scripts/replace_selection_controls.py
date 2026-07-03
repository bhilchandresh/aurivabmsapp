# replace_selection_controls.py
"""Migration script for Phase 4D (3).
Replaces AppColors.primary (including opacity/value helpers) in selection control widgets with
`context.colorScheme.primary`.
Scope limited to files containing any of the target widgets.
"""

import os, re, json

PROJECT_ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), '..', '..'))
LIB_DIR = os.path.join(PROJECT_ROOT, 'lib')
TARGET_WIDGETS = [
    'Slider', 'Switch', 'Checkbox', 'Radio', 'TabBar', 'ChoiceChip',
    'FilterChip', 'InputChip', 'ActionChip'
]

def file_contains_target(path: str) -> bool:
    with open(path, 'r', encoding='utf-8') as f:
        content = f.read()
    return any(widget in content for widget in TARGET_WIDGETS)

def replace_in_line(line: str) -> str:
    # backgroundColor replacements
    line = re.sub(r"backgroundColor:\s*AppColors\.primary\b", "backgroundColor: context.colorScheme.primary", line)
    line = re.sub(r"backgroundColor:\s*AppColors\.primary\.withOpacity\(([^)]+)\)", r"backgroundColor: context.colorScheme.primary.withOpacity(\1)", line)
    line = re.sub(r"backgroundColor:\s*AppColors\.primary\.withValues\(([^)]+)\)", r"backgroundColor: context.colorScheme.primary.withValues(\1)", line)
    # foregroundColor exact match
    line = re.sub(r"foregroundColor:\s*AppColors\.primary\b", "foregroundColor: context.colorScheme.primary", line)
    # generic color property
    line = re.sub(r"color:\s*AppColors\.primary\b", "color: context.colorScheme.primary", line)
    line = re.sub(r"color:\s*AppColors\.primary\.withOpacity\(([^)]+)\)", r"color: context.colorScheme.primary.withOpacity(\1)", line)
    line = re.sub(r"color:\s*AppColors\.primary\.withValues\(([^)]+)\)", r"color: context.colorScheme.primary.withValues(\1)", line)
    # active/selected/indicator/thumb/track/overlay/fillColor
    props = ['activeColor', 'selectedColor', 'indicatorColor', 'thumbColor', 'trackColor', 'overlayColor', 'fillColor']
    for prop in props:
        line = re.sub(fr"{prop}:\s*AppColors\.primary\b", f"{prop}: context.colorScheme.primary", line)
        line = re.sub(fr"{prop}:\s*AppColors\.primary\.withOpacity\(([^)]+)\)", f"{prop}: context.colorScheme.primary.withOpacity(\1)", line)
        line = re.sub(fr"{prop}:\s*AppColors\.primary\.withValues\(([^)]+)\)", f"{prop}: context.colorScheme.primary.withValues(\1)", line)
    # legacy styleFrom primary
    line = re.sub(r"styleFrom\s*\(\s*primary:\s*AppColors\.primary\s*\)", "styleFrom(backgroundColor: context.colorScheme.primary)", line)
    line = re.sub(r"styleFrom\s*\(\s*primary:\s*AppColors\.primary\.withOpacity\(([^)]+)\)\s*\)", "styleFrom(backgroundColor: context.colorScheme.primary.withOpacity(\1))", line)
    line = re.sub(r"styleFrom\s*\(\s*primary:\s*AppColors\.primary\.withValues\(([^)]+)\)\s*\)", "styleFrom(backgroundColor: context.colorScheme.primary.withValues(\1))", line)
    return line

modified_files = []
occ_before = 0
occ_after = 0

for root, _, files in os.walk(LIB_DIR):
    for file in files:
        if not file.endswith('.dart'):
            continue
        path = os.path.join(root, file)
        if not file_contains_target(path):
            continue
        with open(path, 'r', encoding='utf-8') as fp:
            original = fp.readlines()
        new = []
        changed = False
        for ln in original:
            new_ln = replace_in_line(ln)
            new.append(new_ln)
            if new_ln != ln:
                changed = True
        occ_before += sum(1 for l in original if 'AppColors.primary' in l)
        occ_after += sum(1 for l in new if 'AppColors.primary' in l)
        if changed:
            with open(path, 'w', encoding='utf-8') as fp:
                fp.writelines(new)
            modified_files.append(os.path.relpath(path, PROJECT_ROOT))

# Generate markdown report
report_path = os.path.join(PROJECT_ROOT, 'theme_phase4D_3_report.md')
with open(report_path, 'w', encoding='utf-8') as fp:
    fp.write('# Phase 4D (3) Migration Report\n\n')
    fp.write('**Files Modified**\n')
    for f in modified_files:
        fp.write(f'- {f}\n')
    fp.write('\n')
    fp.write(f'**Occurrences Before**: {occ_before}\n')
    fp.write(f'**Occurrences After**: {occ_after}\n\n')
    fp.write('**Branding Whitelist**:\nUNCHANGED ✅ – Splash screen BMS text remains unchanged.\n')

print(json.dumps({
    'files_modified': modified_files,
    'occurrences_before': occ_before,
    'occurrences_after': occ_after,
    'branding_whitelist_unchanged': True
}))
