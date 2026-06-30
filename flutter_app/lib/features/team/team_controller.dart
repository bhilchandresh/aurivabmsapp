import 'package:flutter/foundation.dart';
import 'dart:convert';
import 'package:get/get.dart';
import '../../core/utils/api_service.dart';
import '../../core/constants/api_constants.dart';
import '../auth/auth_controller.dart';

class TeamMember {
  final String id;
  final String name;
  final String email;
  final String role; // 'admin' or 'sales'
  final String? signatureImage; // Base64 data URI

  TeamMember({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
    this.signatureImage,
  });

  TeamMember copyWith({
    String? id,
    String? name,
    String? email,
    String? role,
    String? signatureImage,
  }) {
    return TeamMember(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      role: role ?? this.role,
      signatureImage: signatureImage ?? this.signatureImage,
    );
  }

  factory TeamMember.fromJson(Map<String, dynamic> json) {
    final rawRole = json['role'] ?? 'user';
    // Map backend 'user' -> frontend 'sales'
    final role = rawRole == 'user' ? 'sales' : rawRole;
    return TeamMember(
      id: json['_id'] ?? json['id'] ?? '',
      name: json['name'] ?? '',
      email: json['email'] ?? '',
      role: role,
      signatureImage: json['signatureImage'],
    );
  }
}

class TeamController extends GetxController {
  // Subscription Plan state
  var subscriptionPlan = 'premium'.obs; // 'basic', 'premium', 'enterprise'

  // Loaded list of team members
  var teamMembers = <TeamMember>[].obs;

  // Current logged in user ID to prevent self-deletion
  var currentUserId = 'u1'.obs;

  var isLoading = false.obs;

  @override
  void onInit() {
    super.onInit();
    final AuthController authController = Get.isRegistered<AuthController>()
        ? Get.find<AuthController>()
        : Get.put(AuthController(), permanent: true);

    subscriptionPlan.value =
        authController.tenantInfo.value?['subscriptionPlan'] ?? 'premium';

    // Bind subscription plan from authController's tenantInfo if it changes
    ever(authController.tenantInfo, (Map<String, dynamic>? info) {
      if (info != null) {
        subscriptionPlan.value = info['subscriptionPlan'] ?? 'premium';
      }
    });

    fetchTeamMembers();
  }

  Future<void> fetchTeamMembers() async {
    try {
      isLoading.value = true;
      final response = await ApiService.get(ApiConstants.users);
      if (response.statusCode == 200) {
        final Map<String, dynamic> body = jsonDecode(response.body);
        if (body['success'] == true) {
          final List<dynamic> data = body['data'] ?? [];
          teamMembers.assignAll(
            data.map((m) => TeamMember.fromJson(m)).toList(),
          );
        }
      }
    } catch (e) {
      debugPrint('Error fetching team members: $e');
    } finally {
      isLoading.value = false;
    }
  }

  int get maxUsers {
    switch (subscriptionPlan.value) {
      case 'basic':
        return 2;
      case 'premium':
        return 5;
      default:
        return 99999; // Infinity
    }
  }

  bool get isLocked => subscriptionPlan.value == 'basic';

  bool get isAtLimit => teamMembers.length >= maxUsers;

  double get usagePercentage {
    if (maxUsers == 99999) return 0.0;
    return (teamMembers.length / maxUsers).clamp(0.0, 1.0);
  }

  Future<bool> addMember(
    String name,
    String email,
    String password,
    String role,
  ) async {
    if (isAtLimit) return false;
    try {
      isLoading.value = true;

      // Map frontend 'sales' -> backend 'user'
      final backendRole = role == 'sales' ? 'user' : role;

      final response = await ApiService.post(ApiConstants.users, {
        'name': name,
        'email': email,
        'password': password,
        'role': backendRole,
      });
      if (response.statusCode == 201 || response.statusCode == 200) {
        await fetchTeamMembers();
        return true;
      }
      return false;
    } catch (e) {
      debugPrint('Error adding team member: $e');
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  Future<bool> deleteMember(String id) async {
    try {
      isLoading.value = true;
      final response = await ApiService.delete('${ApiConstants.users}/$id');
      if (response.statusCode == 200) {
        await fetchTeamMembers();
        return true;
      }
      return false;
    } catch (e) {
      debugPrint('Error deleting team member: $e');
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  Future<bool> updateSignature(String id, String signatureBase64) async {
    try {
      isLoading.value = true;
      final response = await ApiService.put('${ApiConstants.users}/$id', {
        'signatureImage': signatureBase64,
      });
      if (response.statusCode == 200) {
        await fetchTeamMembers();
        final AuthController authController = Get.find<AuthController>();
        if (id == authController.userId.value) {
          await authController.updateSignatureLocal(signatureBase64);
        }
        return true;
      }
      return false;
    } catch (e) {
      debugPrint('Error updating signature: $e');
      return false;
    } finally {
      isLoading.value = false;
    }
  }
}
