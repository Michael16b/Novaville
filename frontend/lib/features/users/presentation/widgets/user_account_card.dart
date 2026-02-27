import 'package:flutter/material.dart';
import 'package:frontend/constants/colors.dart';
import 'package:frontend/constants/texts/texts_user_accounts.dart';
import 'package:frontend/features/users/data/models/user.dart';
import 'package:frontend/features/users/data/models/user_role.dart';

/// Reusable card used to display and manage one user account.
class UserAccountCard extends StatelessWidget {
  const UserAccountCard({
    required this.user,
    required this.isCurrentUser,
    required this.onEdit,
    required this.onDelete,
    required this.getRoleColor,
    super.key,
  });

  final User user;
  final bool isCurrentUser;
  final ValueChanged<User> onEdit;
  final ValueChanged<User> onDelete;
  final Color Function(UserRole? role) getRoleColor;

  @override
  Widget build(BuildContext context) {
    final fullName = '${user.firstName} ${user.lastName}'.trim();
    final initials =
        '${_firstChar(user.firstName)}${_firstChar(user.lastName)}';

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundColor: AppColors.highlight,
                  child: Text(
                    initials.toUpperCase(),
                    style: const TextStyle(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        fullName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '@${user.username}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: AppColors.secondaryText,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: getRoleColor(user.role),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    user.role?.label ?? '-',
                    style: const TextStyle(
                      color: AppColors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              user.email,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const Spacer(),
            const Divider(height: 20),
            Row(
              children: [
                Expanded(
                  child: TextButton.icon(
                    onPressed: () => onEdit(user),
                    icon: const Icon(Icons.edit_outlined, size: 18),
                    label: const Text(UserTexts.edit),
                  ),
                ),
                Expanded(
                  child: TextButton.icon(
                    onPressed: isCurrentUser ? null : () => onDelete(user),
                    icon: Icon(
                      Icons.delete_outline,
                      size: 18,
                      color: isCurrentUser ? Colors.grey : AppColors.error,
                    ),
                    label: Text(
                      UserTexts.delete,
                      style: TextStyle(
                        color: isCurrentUser ? Colors.grey : AppColors.error,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _firstChar(String value) {
    final trimmed = value.trim();
    if (trimmed.isEmpty) {
      return '';
    }
    return trimmed.substring(0, 1);
  }
}
