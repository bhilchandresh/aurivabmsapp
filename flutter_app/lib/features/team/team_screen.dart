import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:image_picker/image_picker.dart';
import 'package:skeletonizer/skeletonizer.dart';
import '../../core/services/permission_manager.dart';

import '../../core/constants/app_colors.dart';
import '../../shared/widgets/app_top_bar.dart';
import '../../shared/widgets/app_input_field.dart';
import 'team_controller.dart';
import '../auth/auth_controller.dart';

class TeamScreen extends StatefulWidget {
  const TeamScreen({super.key});

  @override
  State<TeamScreen> createState() => _TeamScreenState();
}

class _TeamScreenState extends State<TeamScreen> {
  final TeamController _controller = Get.put(TeamController());
  final ImagePicker _imagePicker = ImagePicker();

  String _searchQuery = '';

  // Text editing controllers for Add form
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  String _selectedRole = 'sales';

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  // --- FILTERED TEAM MEMBERS ---
  List<TeamMember> get _filteredMembers {
    return _controller.teamMembers.where((member) {
      final query = _searchQuery.toLowerCase();
      return member.name.toLowerCase().contains(query) ||
          member.email.toLowerCase().contains(query);
    }).toList();
  }

  // --- PICKS IMAGE AND CONVERTS TO BASE64 ---
  Future<void> _pickSignature(String memberId) async {
    final isGranted = await PermissionManager.requestGalleryPermission();
    if (!isGranted) return;
    
    try {
      final XFile? pickedFile = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 85,
        maxWidth: 600,
      );

      if (pickedFile != null) {
        final bytes = await pickedFile.readAsBytes();
        if (bytes.length > 2 * 1024 * 1024) {
          Get.snackbar(
            'File Too Large',
            'Please choose an image smaller than 2MB.',
            snackPosition: SnackPosition.BOTTOM,
            backgroundColor: AppColors.error,
            colorText: Colors.white,
          );
          return;
        }

        final base64String = 'data:image/png;base64,${base64Encode(bytes)}';
        final success = await _controller.updateSignature(
          memberId,
          base64String,
        );

        if (success) {
          Get.snackbar(
            'Success',
            'Digital signature updated successfully!',
            snackPosition: SnackPosition.BOTTOM,
            backgroundColor: AppColors.success,
            colorText: Colors.white,
          );
        } else {
          Get.snackbar(
            'Upload Failed',
            'Failed to update signature. Please try again.',
            snackPosition: SnackPosition.BOTTOM,
            backgroundColor: AppColors.error,
            colorText: Colors.white,
          );
        }
      }
    } catch (e) {
      Get.snackbar(
        'Upload Failed',
        'Could not upload signature: $e',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: AppColors.error,
        colorText: Colors.white,
      );
    }
  }

  // --- RENDERS BASE64 SIGNATURE ---
  Widget _buildSignatureWidget(String? base64Str) {
    if (base64Str == null) {
      return const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(LucideIcons.alertCircle, size: 12, color: Colors.red),
          SizedBox(width: 4),
          Text(
            'No Signature',
            style: TextStyle(
              color: Colors.red,
              fontSize: 11,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      );
    }

    try {
      String cleanBase64 = base64Str;
      if (base64Str.contains(',')) {
        cleanBase64 = base64Str.split(',')[1];
      }
      final decodedBytes = base64Decode(cleanBase64);
      return Container(
        height: 38,
        width: 100,
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: Colors.grey.shade200),
          borderRadius: BorderRadius.circular(6),
        ),
        padding: const EdgeInsets.all(2),
        child: Image.memory(decodedBytes, fit: BoxFit.contain),
      );
    } catch (_) {
      return const Icon(LucideIcons.imageOff, size: 18, color: Colors.grey);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppTopBar(
        title: 'team_access'.tr,
        subtitle: 'manage_roles'.tr,
        showProfile: false,
        showBadge: false,
        showBackButton: true,
      ),
      body: Column(
        children: [
          Expanded(
            child: Obx(() {
              if (_controller.isLocked) {
                return _buildLockedView();
              }
              return _buildDashboardView();
            }),
          ),
        ],
      ),
    );
  }

  // --- BASIC PLAN LOCK VIEW ---
  Widget _buildLockedView() {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.all(24.0),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const SizedBox(height: 40),
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.amber.shade50,
                shape: BoxShape.circle,
              ),
              child: Icon(
                LucideIcons.lock,
                size: 48,
                color: Colors.amber.shade600,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'team_pro_feature'.tr,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w900,
                color: (Theme.of(context).textTheme.displayLarge?.color ?? Colors.black),
                letterSpacing: -0.5,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'team_pro_desc'.tr,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                color: (Theme.of(context).textTheme.bodyMedium?.color ?? Colors.grey),
                height: 1.5,
              ),
            ),
            const SizedBox(height: 32),
            _buildUpgradePlanCard(
              'pro_plan_team'.tr,
              'pro_plan_team_desc'.tr,
              'pro_plan_price'.tr,
            ),
            const SizedBox(height: 12),
            _buildUpgradePlanCard(
              'business_plan_team'.tr,
              'business_plan_team_desc'.tr,
              'business_plan_price'.tr,
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: () {
                _controller.subscriptionPlan.value = 'premium';
                Get.snackbar(
                  'Simulation Success',
                  'Upgraded subscription simulation to Premium!',
                  snackPosition: SnackPosition.BOTTOM,
                  backgroundColor: AppColors.success,
                  colorText: Colors.white,
                );
              },
              icon: const Icon(LucideIcons.zap, size: 16, color: Colors.white),
              label: Text(
                'upgrade_now'.tr,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.amber.shade600,
                padding: const EdgeInsets.symmetric(
                  horizontal: 32,
                  vertical: 14,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUpgradePlanCard(String name, String desc, String price) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.3)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.01),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                name,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                  color: (Theme.of(context).textTheme.displayLarge?.color ?? Colors.black),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                desc,
                style: TextStyle(
                  fontSize: 12,
                  color: (Theme.of(context).textTheme.bodyMedium?.color ?? Colors.grey),
                ),
              ),
            ],
          ),
          Text(
            price,
            style: const TextStyle(
              fontWeight: FontWeight.w800,
              fontSize: 13,
              color: AppColors.primary,
            ),
          ),
        ],
      ),
    );
  }

  // --- REGULAR ACCESS DASHBOARD ---
  Widget _buildDashboardView() {
    return RefreshIndicator(
      onRefresh: () => _controller.fetchTeamMembers(),
      color: AppColors.primary,
      child: Skeletonizer(
        enabled: _controller.isLoading.value && _controller.teamMembers.isEmpty,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(
            parent: BouncingScrollPhysics(),
          ),
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Slots Usage Card (Only for Premium Plan)
              Obx(() {
                if (_controller.subscriptionPlan.value == 'premium') {
                  final used = _controller.teamMembers.length;
                  final max = _controller.maxUsers;
                  final pct = _controller.usagePercentage;
                  final limitReached = _controller.isAtLimit;

                  Color progressColor = AppColors.primary;
                  if (pct >= 1.0) {
                    progressColor = Colors.red;
                  } else if (pct >= 0.8) {
                    progressColor = Colors.amber;
                  }

                  return Container(
                    margin: const EdgeInsets.only(bottom: 16),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Theme.of(context).cardTheme.color,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.3)),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.01),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'team_slots_used'.tr,
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                                color: (Theme.of(context).textTheme.displayLarge?.color ?? Colors.black),
                              ),
                            ),
                            Text(
                              '$used / $max',
                              style: TextStyle(
                                fontWeight: FontWeight.w900,
                                fontSize: 13,
                                color: limitReached
                                    ? Colors.red
                                    : (Theme.of(context).textTheme.displayLarge?.color ?? Colors.black),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: LinearProgressIndicator(
                            value: pct,
                            minHeight: 8,
                            backgroundColor: Colors.grey.shade100,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              progressColor,
                            ),
                          ),
                        ),
                        if (limitReached) ...[
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              const Icon(
                                LucideIcons.alertTriangle,
                                size: 12,
                                color: Colors.red,
                              ),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Text(
                                  'team_slots_full'.tr,
                                  style: TextStyle(
                                    color: Colors.red.shade600,
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  );
                }
                return const SizedBox.shrink();
              }),

              // Search and Action Bar
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      onChanged: (val) {
                        setState(() {
                          _searchQuery = val;
                        });
                      },
                      decoration: InputDecoration(
                        hintText: 'search_staff'.tr,
                        hintStyle: const TextStyle(
                          color: Colors.grey,
                          fontSize: 12,
                        ),
                        prefixIcon: const Icon(
                          LucideIcons.search,
                          color: Colors.grey,
                          size: 16,
                        ),
                        filled: true,
                        fillColor: Theme.of(context).cardTheme.color,
                        contentPadding: const EdgeInsets.symmetric(
                          vertical: 10,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.3)),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.3)),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(
                            color: AppColors.primary,
                            width: 1.5,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Obx(() {
                    final atLimit = _controller.isAtLimit;
                    return ElevatedButton.icon(
                      onPressed: atLimit
                          ? null
                          : () => _showAddMemberBottomSheet(context),
                      icon: const Icon(LucideIcons.plus, size: 14),
                      label: Text(
                        'add_staff'.tr,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        disabledBackgroundColor: Colors.grey.shade200,
                        disabledForegroundColor: Colors.grey.shade400,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 12,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 0,
                      ),
                    );
                  }),
                ],
              ),
              const SizedBox(height: 20),

              // Registry List Title
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'access_registry'.tr,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: (Theme.of(context).textTheme.displayLarge?.color ?? Colors.black),
                    ),
                  ),
                  const Icon(LucideIcons.users, size: 16, color: Colors.grey),
                ],
              ),
              const SizedBox(height: 12),

              // Team List
              Obx(() => _buildMembersList()),
            ],
          ),
        ),
      ),
    );
  }

  // --- MEMBERS LIST RENDERER ---
  Widget _buildMembersList() {
    final showSkeleton =
        _controller.isLoading.value && _controller.teamMembers.isEmpty;
    final list = showSkeleton
        ? List.generate(
            5,
            (index) => TeamMember(
              id: 'loading_$index',
              name: 'Loading Member Name',
              email: 'member@loading.com',
              role: 'sales',
            ),
          )
        : _filteredMembers;

    if (list.isEmpty) {
      return Container(
        height: 180,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: Theme.of(context).cardTheme.color,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.3)),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(LucideIcons.users, size: 36, color: Colors.grey.shade300),
            const SizedBox(height: 12),
            Text(
              'no_staff_found'.tr,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 12,
                color: Colors.grey.shade500,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.separated(
      shrinkWrap: true,
      padding: EdgeInsets.zero,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: list.length,
      separatorBuilder: (context, index) => const SizedBox(height: 10),
      itemBuilder: (context, index) {
        final member = list[index];
        final authController = Get.find<AuthController>();
        final isMe =
            member.email.toLowerCase() ==
            authController.userEmail.value.toLowerCase();
        final isAdmin = member.role == 'admin';

        final roleColor = isAdmin ? Colors.purple : Colors.blue;
        final roleLabel = isAdmin ? 'Admin' : 'Sales';

        return TweenAnimationBuilder<double>(
          duration: Duration(milliseconds: 200 + (index * 40)),
          tween: Tween<double>(begin: 0.0, end: 1.0),
          builder: (context, value, child) {
            return Transform.translate(
              offset: Offset(0, 12 * (1.0 - value)),
              child: Opacity(opacity: value, child: child),
            );
          },
          child: InkWell(
            onTap: () => _showMemberDetailsBottomSheet(context, member),
            borderRadius: BorderRadius.circular(16),
            child: Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Theme.of(context).cardTheme.color,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.3)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.01),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  // Avatar
                  Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      color: roleColor.withValues(alpha: 0.08),
                      shape: BoxShape.circle,
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      member.name.isNotEmpty
                          ? member.name[0].toUpperCase()
                          : '?',
                      style: TextStyle(
                        color: roleColor,
                        fontWeight: FontWeight.w900,
                        fontSize: 16,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),

                  // Member details
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          member.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                            color: (Theme.of(context).textTheme.displayLarge?.color ?? Colors.black),
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          member.email,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 10,
                            color: Colors.grey.shade500,
                          ),
                        ),
                        const SizedBox(height: 8),

                        // Signature Status & Actions
                        Row(
                          children: [
                            _buildSignatureWidget(member.signatureImage),
                            const SizedBox(width: 10),
                            Obx(() {
                              final isUploading = _controller.isLoading.value;
                              return GestureDetector(
                                onTap: isUploading
                                    ? null
                                    : () => _pickSignature(member.id),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Theme.of(context).scaffoldBackgroundColor,
                                    borderRadius: BorderRadius.circular(4),
                                    border: Border.all(
                                      color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.3),
                                    ),
                                  ),
                                  child: isUploading
                                      ? const SizedBox(
                                          height: 10,
                                          width: 10,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 1.5,
                                            color: AppColors.primary,
                                          ),
                                        )
                                      : Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Icon(
                                              member.signatureImage != null
                                                  ? LucideIcons.refreshCw
                                                  : LucideIcons.upload,
                                              size: 10,
                                              color: Theme.of(context).textTheme.bodyMedium?.color,
                                            ),
                                            const SizedBox(width: 4),
                                            Text(
                                              member.signatureImage != null
                                                  ? 'change'.tr
                                                  : 'upload'.tr,
                                              style: TextStyle(
                                                fontSize: 9,
                                                fontWeight: FontWeight.bold,
                                                color: Theme.of(context).textTheme.bodyMedium?.color,
                                              ),
                                            ),
                                          ],
                                        ),
                                ),
                              );
                            }),
                          ],
                        ),
                      ],
                    ),
                  ),

                  // Actions Column
                  const SizedBox(width: 8),
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: roleColor.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          roleLabel.toUpperCase(),
                          style: TextStyle(
                            fontSize: 8,
                            fontWeight: FontWeight.w900,
                            color: roleColor,
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      if (isMe)
                        Text(
                          'its_you'.tr,
                          style: TextStyle(
                            fontSize: 10,
                            fontStyle: FontStyle.italic,
                            color: Colors.grey.shade400,
                            fontWeight: FontWeight.bold,
                          ),
                        )
                      else
                        IconButton(
                          onPressed: () =>
                              _confirmDeleteMember(context, member),
                          icon: const Icon(
                            LucideIcons.trash2,
                            size: 15,
                            color: Colors.red,
                          ),
                          style: IconButton.styleFrom(
                            backgroundColor: Colors.red.withValues(alpha: 0.06),
                            padding: const EdgeInsets.all(6),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  // --- DELETE CONFIRMATION DIALOG ---
  void _confirmDeleteMember(BuildContext context, TeamMember member) {
    Get.dialog(
      AlertDialog(
        title: Text('remove_member'.tr),
        content: Text('remove_member_confirm'.tr),
        actions: [
          Obx(() {
            final isSaving = _controller.isLoading.value;
            return TextButton(
              onPressed: isSaving ? null : () => Get.back(),
              child: Text(
                'cancel'.tr,
                style: const TextStyle(color: Colors.grey),
              ),
            );
          }),
          Obx(() {
            final isSaving = _controller.isLoading.value;
            return ElevatedButton(
              onPressed: isSaving
                  ? null
                  : () async {
                      final success = await _controller.deleteMember(member.id);
                      Get.back();
                      if (success) {
                        Get.snackbar(
                          'Removed',
                          'member_removed'.tr,
                          snackPosition: SnackPosition.BOTTOM,
                          backgroundColor: AppColors.error,
                          colorText: Colors.white,
                        );
                      } else {
                        Get.snackbar(
                          'Error',
                          'member_remove_error'.tr,
                          snackPosition: SnackPosition.BOTTOM,
                          backgroundColor: Colors.red,
                          colorText: Colors.white,
                        );
                      }
                    },
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              child: isSaving
                  ? const SizedBox(
                      height: 16,
                      width: 16,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                  : Text(
                      'remove'.tr,
                      style: const TextStyle(color: Colors.white),
                    ),
            );
          }),
        ],
      ),
    );
  }

  // --- TEAM MEMBER DETAILS BOTTOM SHEET ---
  void _showMemberDetailsBottomSheet(BuildContext context, TeamMember member) {
    final isMe = member.id == _controller.currentUserId.value;
    final roleColor = member.role == 'admin' ? Colors.purple : Colors.blue;

    Get.bottomSheet(
      Container(
        decoration: BoxDecoration(
          color: Theme.of(context).cardTheme.color,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: roleColor.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    member.role.toUpperCase(),
                    style: TextStyle(
                      color: roleColor,
                      fontWeight: FontWeight.w900,
                      fontSize: 9,
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(LucideIcons.x, size: 18),
                  onPressed: () => Get.back(),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Profile info
            Row(
              children: [
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: roleColor.withValues(alpha: 0.08),
                    shape: BoxShape.circle,
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    member.name.isNotEmpty ? member.name[0].toUpperCase() : '?',
                    style: TextStyle(
                      color: roleColor,
                      fontWeight: FontWeight.w900,
                      fontSize: 20,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        member.name,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: (Theme.of(context).textTheme.displayLarge?.color ?? Colors.black),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        member.email,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade500,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const Divider(height: 36),

            // Digital Signature Preview Card
            Text(
              'digital_signature'.tr,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 12,
                color: (Theme.of(context).textTheme.displayLarge?.color ?? Colors.black),
              ),
            ),
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              height: 120,
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: member.signatureImage != null
                  ? Center(
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: _buildSignatureWidget(member.signatureImage),
                      ),
                    )
                  : Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          LucideIcons.alertTriangle,
                          color: Colors.red.shade400,
                          size: 24,
                        ),
                        const SizedBox(height: 6),
                        const Text(
                          'No digital signature uploaded',
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.grey,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
            ),
            const SizedBox(height: 16),

            // Upload actions
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Get.back();
                      _pickSignature(member.id);
                    },
                    icon: Icon(
                      member.signatureImage != null
                          ? LucideIcons.refreshCw
                          : LucideIcons.upload,
                      size: 14,
                      color: Colors.white,
                    ),
                    label: Text(
                      member.signatureImage != null
                          ? 'change'.tr
                          : 'upload_signature'.tr,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                        color: Colors.white,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),

            // Delete action for others
            if (!isMe) ...[
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () {
                        Get.back();
                        _confirmDeleteMember(context, member);
                      },
                      icon: const Icon(
                        LucideIcons.trash2,
                        size: 14,
                        color: Colors.red,
                      ),
                      label: Text(
                        'remove_member'.tr,
                        style: const TextStyle(
                          color: Colors.red,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Colors.red),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  // --- ADD MEMBER FORM BOTTOM SHEET ---
  void _showAddMemberBottomSheet(BuildContext context) {
    final formKey = GlobalKey<FormState>();

    Get.bottomSheet(
      StatefulBuilder(
        builder: (context, setSheetState) {
          return Container(
            decoration: BoxDecoration(
              color: Theme.of(context).cardTheme.color,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
            ),
            padding: const EdgeInsets.all(20),
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: Form(
                key: formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'add_staff'.tr,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: (Theme.of(context).textTheme.displayLarge?.color ?? Colors.black),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(LucideIcons.x, size: 18),
                          onPressed: () => Get.back(),
                        ),
                      ],
                    ),
                    const Divider(),
                    const SizedBox(height: 12),

                    // Name
                    AppInputField(
                      label: 'full_name_star'.tr,
                      hintText: 'eg_name'.tr,
                      controller: _nameCtrl,
                      validator: (val) {
                        if (val == null || val.trim().isEmpty) {
                          return 'Please enter name';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 12),

                    // Email
                    AppInputField(
                      label: 'email'.tr,
                      hintText: 'eg_email'.tr,
                      keyboardType: TextInputType.emailAddress,
                      controller: _emailCtrl,
                      validator: (val) {
                        if (val == null || val.trim().isEmpty) {
                          return 'Please enter email';
                        }
                        if (!GetUtils.isEmail(val.trim())) {
                          return 'Invalid email address';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 12),

                    // Password
                    AppInputField(
                      label: 'password_star'.tr,
                      hintText: '••••••••',
                      obscureText: true,
                      controller: _passwordCtrl,
                      validator: (val) {
                        if (val == null || val.trim().isEmpty) {
                          return 'Please enter password';
                        }
                        if (val.trim().length < 6) {
                          return 'Password must be at least 6 chars';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 12),

                    // Role Select
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.only(left: 4, bottom: 4),
                          child: Text(
                            'role'.tr.toUpperCase(),
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 10,
                              color: (Theme.of(context).textTheme.bodyMedium?.color ?? Colors.grey),
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Theme.of(context).scaffoldBackgroundColor,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.3),
                            ),
                          ),
                          child: DropdownButtonHideUnderline(
                            child: DropdownButtonFormField<String>(
                              initialValue: _selectedRole,
                              style: Theme.of(context).textTheme.bodyMedium
                                  ?.copyWith(
                                    color: (Theme.of(context).textTheme.displayLarge?.color ?? Colors.black),
                                    fontWeight: FontWeight.w500,
                                  ),
                              items: [
                                DropdownMenuItem(
                                  value: 'sales',
                                  child: Text('sales_staff'.tr),
                                ),
                                DropdownMenuItem(
                                  value: 'admin',
                                  child: Text('administrator'.tr),
                                ),
                              ],
                              onChanged: (val) {
                                if (val != null) {
                                  setSheetState(() {
                                    _selectedRole = val;
                                  });
                                }
                              },
                              decoration: const InputDecoration(
                                border: InputBorder.none,
                                contentPadding: EdgeInsets.zero,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // Submit Button
                    Obx(() {
                      final isSaving = _controller.isLoading.value;
                      return SizedBox(
                        width: double.infinity,
                        height: 48,
                        child: ElevatedButton.icon(
                          onPressed: isSaving
                              ? null
                              : () async {
                                  if (formKey.currentState!.validate()) {
                                    final success = await _controller.addMember(
                                      _nameCtrl.text.trim(),
                                      _emailCtrl.text.trim(),
                                      _passwordCtrl.text.trim(),
                                      _selectedRole,
                                    );

                                    if (success) {
                                      // Clean controllers
                                      _nameCtrl.clear();
                                      _emailCtrl.clear();
                                      _passwordCtrl.clear();
                                      _selectedRole = 'sales';

                                      Get.back();
                                      Get.snackbar(
                                        'Success',
                                        'Sales staff added successfully!',
                                        snackPosition: SnackPosition.BOTTOM,
                                        backgroundColor: AppColors.success,
                                        colorText: Colors.white,
                                      );
                                    } else {
                                      Get.snackbar(
                                        'Error',
                                        'Failed to add staff member. Email might already be taken or limit reached.',
                                        snackPosition: SnackPosition.BOTTOM,
                                        backgroundColor: Colors.red,
                                        colorText: Colors.white,
                                      );
                                    }
                                  }
                                },
                          icon: isSaving
                              ? const SizedBox.shrink()
                              : const Icon(
                                  LucideIcons.plus,
                                  size: 16,
                                  color: Colors.white,
                                ),
                          label: isSaving
                              ? const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 2,
                                  ),
                                )
                              : Text(
                                  'add_staff'.tr,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                        ),
                      );
                    }),
                  ],
                ),
              ),
            ),
          );
        },
      ),
      isScrollControlled: true,
    );
  }
}
