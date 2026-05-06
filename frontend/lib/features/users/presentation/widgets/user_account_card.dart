import 'package:flutter/material.dart';
import 'package:frontend/constants/colors.dart';
import 'package:frontend/features/users/data/models/user.dart';
import 'package:frontend/features/users/data/models/user_role.dart';

/// Reusable card used to display and manage one user account.
class UserAccountCard extends StatelessWidget {
  const UserAccountCard({
    required this.user,
    required this.isCurrentUser,
    required this.onEdit,
    required this.onDelete,
    this.onResetPassword,
    required this.getRoleColor,
    this.neighborhoodName,
    super.key,
  });

  final User user;
  final bool isCurrentUser;
  final ValueChanged<User> onEdit;
  final ValueChanged<User> onDelete;
  final ValueChanged<User>? onResetPassword;
  final Color Function(UserRole? role) getRoleColor;

  /// The resolved neighborhood name for this user, if available.
  final String? neighborhoodName;

  @override
  Widget build(BuildContext context) {
    final fullName = '${user.firstName} ${user.lastName}'.trim();
    final initials =
        '${_firstChar(user.firstName)}${_firstChar(user.lastName)}';
    final roleColor = getRoleColor(user.role);

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // ── Header: colored accent bar + avatar + name + role badge ──
          Container(
            decoration: BoxDecoration(color: roleColor.withValues(alpha: 0.08)),
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 14),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 22,
                  backgroundColor: roleColor.withValues(alpha: 0.18),
                  child: Text(
                    initials.toUpperCase(),
                    style: TextStyle(
                      color: roleColor,
                      fontWeight: FontWeight.w800,
                      fontSize: 14,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        fullName.isNotEmpty ? fullName : user.username,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: roleColor,
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(
                          user.role?.label ?? '-',
                          style: const TextStyle(
                            color: AppColors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                if (isCurrentUser)
                  Tooltip(
                    message: 'Votre compte',
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.12),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.person,
                        size: 16,
                        color: AppColors.primary,
                      ),
                    ),
                  ),
              ],
            ),
          ),

          // ── Body: info rows with icons ──
          Expanded(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
              child: Column(
                children: [
                  _InfoRow(icon: Icons.alternate_email, text: user.username),
                  const SizedBox(height: 8),
                  _InfoRow(icon: Icons.mail_outline_rounded, text: user.email),
                  if (neighborhoodName != null) ...[
                    const SizedBox(height: 8),
                    _InfoRow(
                      icon: Icons.location_on_outlined,
                      text: neighborhoodName!,
                    ),
                  ],
                  if (user.address.trim().isNotEmpty) ...[
                    const SizedBox(height: 8),
                    _InfoRow(icon: Icons.home_outlined, text: user.address),
                  ],
                  const Spacer(),
                ],
              ),
            ),
          ),

          // ── Footer: action buttons ──
          Padding(
            padding: const EdgeInsets.fromLTRB(8, 0, 8, 8),
            child: LayoutBuilder(
              builder: (context, constraints) {
                final useVerticalActions = constraints.maxWidth < 260;
                final actions = [
                  _ActionButton(
                    icon: Icons.edit_outlined,
                    label: 'Modifier',
                    color: isCurrentUser
                        ? AppColors.disabled
                        : AppColors.primary,
                    onTap: isCurrentUser ? null : () => onEdit(user),
                  ),
                  if (onResetPassword != null)
                    _ActionButton(
                      icon: Icons.lock_reset,
                      label: 'Mot de passe',
                      color: isCurrentUser
                          ? AppColors.disabled
                          : AppColors.warning,
                      onTap: isCurrentUser
                          ? null
                          : () => onResetPassword!(user),
                    ),
                  _ActionButton(
                    icon: Icons.delete_outline_rounded,
                    label: 'Supprimer',
                    color: isCurrentUser ? AppColors.disabled : AppColors.error,
                    onTap: isCurrentUser ? null : () => onDelete(user),
                  ),
                ];

                if (useVerticalActions) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      for (var i = 0; i < actions.length; i++) ...[
                        actions[i],
                        if (i < actions.length - 1) const SizedBox(height: 4),
                      ],
                    ],
                  );
                }

                return Row(
                  children: [
                    for (var i = 0; i < actions.length; i++) ...[
                      Expanded(child: actions[i]),
                      if (i < actions.length - 1) const SizedBox(width: 4),
                    ],
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  String _firstChar(String value) {
    final trimmed = value.trim();
    if (trimmed.isEmpty) return '';
    return trimmed.substring(0, 1);
  }
}

/// A single info row with a leading icon and text.
class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 16, color: AppColors.secondaryText),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: AppColors.primaryText,
              height: 1.3,
            ),
          ),
        ),
      ],
    );
  }
}

/// A compact action button used in the card footer.
class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.icon,
    required this.label,
    required this.color,
    this.onTap,
  });

  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Wrap(
            alignment: WrapAlignment.center,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 4,
            children: [
              Icon(icon, size: 16, color: color),
              Text(
                label,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: color,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
