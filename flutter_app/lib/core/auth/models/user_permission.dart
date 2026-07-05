class UserPermission {
  final String resource; // e.g. "invoices", "inventory", "clients"
  final bool read;
  final bool write;
  final bool update;
  final bool delete;
  final bool export;
  final bool approve;

  UserPermission({
    required this.resource,
    this.read = false,
    this.write = false,
    this.update = false,
    this.delete = false,
    this.export = false,
    this.approve = false,
  });

  factory UserPermission.parse(String packedPermission) {
    // String shape: "invoices:rwu" or "clients:rwda"
    final parts = packedPermission.split(':');
    final resourceName = parts[0];
    final actions = parts.length > 1 ? parts[1].toLowerCase() : '';

    return UserPermission(
      resource: resourceName,
      read: actions.contains('r'),
      write: actions.contains('w'),
      update: actions.contains('u'),
      delete: actions.contains('d'),
      export: actions.contains('e'),
      approve: actions.contains('a'),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'resource': resource,
      'read': read,
      'write': write,
      'update': update,
      'delete': delete,
      'export': export,
      'approve': approve,
    };
  }
}
