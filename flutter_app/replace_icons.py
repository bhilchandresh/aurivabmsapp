import re
f = open('lib/features/profile/profile_screen.dart', 'r', encoding='utf-8')
code = f.read()
f.close()

if 'flutter_svg' not in code:
    code = code.replace("import 'package:flutter/material.dart';", "import 'package:flutter/material.dart';\nimport 'package:flutter_svg/flutter_svg.dart';")

# Update _buildMenuRow signature
code = code.replace('required IconData icon,', 'required String iconAsset,')
# Update _buildMenuRow body
old_icon_body = '''child: Icon(
                icon,
                color: isHovered ? AppColors.primary : iconColor,
                size: 20,
              ),'''
new_icon_body = '''child: SvgPicture.asset(
                iconAsset,
                width: 20,
                height: 20,
                colorFilter: ColorFilter.mode(
                  isHovered ? AppColors.primary : iconColor,
                  BlendMode.srcIn,
                ),
              ),'''
code = code.replace(old_icon_body, new_icon_body)

# Mapping of icons to SVGs
mapping = {
    r'icon: LucideIcons\.user,': r"iconAsset: 'assets/SVG/profile.svg',",
    r'icon: LucideIcons\.package,': r"iconAsset: 'assets/SVG/inventory.svg',",
    r'icon: LucideIcons\.truck,': r"iconAsset: 'assets/SVG/supplier.svg',",
    r'icon: LucideIcons\.wallet,': r"iconAsset: 'assets/SVG/expance.svg',",
    r'icon: LucideIcons\.database,': r"iconAsset: 'assets/SVG/import.svg',",
    r'icon: LucideIcons\.bell,': r"iconAsset: 'assets/SVG/notification.svg',",
    r'icon: LucideIcons\.languages,': r"iconAsset: 'assets/SVG/language.svg',",
    r'icon: LucideIcons\.mail,': r"iconAsset: 'assets/SVG/mail.svg',",
    r'icon: LucideIcons\.shield,': r"iconAsset: 'assets/SVG/privacy.svg',",
    r'icon: LucideIcons\.fileText,': r"iconAsset: 'assets/SVG/tearmandcondition.svg',",
    r'icon: LucideIcons\.shieldCheck,': r"iconAsset: 'assets/SVG/teamandaccess.svg',",
    r'icon: LucideIcons\.settings,': r"iconAsset: 'assets/SVG/setting-2.svg',",
    r'icon: isDark \? LucideIcons\.sun : LucideIcons\.moon,': r"iconAsset: isDark ? 'assets/SVG/light.svg' : 'assets/SVG/dark.svg',"
}

for k, v in mapping.items():
    code = re.sub(k, v, code)

f = open('lib/features/profile/profile_screen.dart', 'w', encoding='utf-8')
f.write(code)
f.close()
