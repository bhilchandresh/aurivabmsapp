import '../models/user_permission.dart';
import '../../services/session_manager.dart';

class PermissionManager {
  final SessionManager _sessionManager;

  PermissionManager(this._sessionManager);

  // ── Role check helpers ─────────────────────────────────────────────────────

  bool get isSuperAdmin {
    final role = _sessionManager.currentUserRole.toLowerCase();
    return role.contains('superadmin') || role.contains('super_admin');
  }

  bool get isAdmin {
    if (isSuperAdmin) return true;
    final role = _sessionManager.currentUserRole.toLowerCase();
    return role.contains('admin');
  }

  bool get isManager {
    if (isAdmin) return true;
    final role = _sessionManager.currentUserRole.toLowerCase();
    return role.contains('manager');
  }

  // ── Resource permissions check ─────────────────────────────────────────────

  bool hasPermission(String resource, String action) {
    if (isSuperAdmin) return true;

    final user = _sessionManager.currentUserModel;
    if (user == null) return false;

    // Direct match against serialized packed permission list e.g. "invoices:rwu"
    for (final permStr in user.permissions) {
      final perm = UserPermission.parse(permStr);
      if (perm.resource.toLowerCase() == resource.toLowerCase()) {
        switch (action.toLowerCase()) {
          case 'read':
          case 'r':
            return perm.read;
          case 'write':
          case 'w':
            return perm.write;
          case 'update':
          case 'u':
            return perm.update;
          case 'delete':
          case 'd':
            return perm.delete;
          case 'export':
          case 'e':
            return perm.export;
          case 'approve':
          case 'a':
            return perm.approve;
        }
      }
    }

    // Role-based fallbacks if permissions list is empty
    if (isAdmin) return true;
    if (isManager) {
      // Managers can do everything except delete or manage settings
      if (resource.toLowerCase() == 'settings') return false;
      if (action.toLowerCase() == 'delete' || action.toLowerCase() == 'd') return false;
      return true;
    }

    // Employees can only read resources
    if (action.toLowerCase() == 'read' || action.toLowerCase() == 'r') return true;

    return false;
  }

  bool canRead(String resource) => hasPermission(resource, 'read');
  bool canWrite(String resource) => hasPermission(resource, 'write');
  bool canUpdate(String resource) => hasPermission(resource, 'update');
  bool canDelete(String resource) => hasPermission(resource, 'delete');
  bool canExport(String resource) => hasPermission(resource, 'export');
  bool canApprove(String resource) => hasPermission(resource, 'approve');
}
