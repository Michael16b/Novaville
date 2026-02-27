import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:frontend/constants/colors.dart';
import 'package:frontend/constants/texts/texts_user_accounts.dart';
import 'package:frontend/features/auth/application/bloc/auth_bloc.dart';
import 'package:frontend/features/users/data/models/user.dart';
import 'package:frontend/features/users/data/models/user_role.dart';

class UserDataSource extends DataTableSource {
  final List<User> _users;
  final int _rowCount;
  final int _page;
  final int _pageSize;
  final BuildContext context;
  final void Function(User) onEdit;
  final void Function(User) onDelete;

  UserDataSource({
    required List<User> users,
    required int rowCount,
    required int page,
    required int pageSize,
    required this.context,
    required this.onEdit,
    required this.onDelete,
  })  : _users = users,
        _rowCount = rowCount,
        _page = page,
        _pageSize = pageSize;

  @override
  DataRow? getRow(int index) {
    final firstRowOnPage = (_page - 1) * _pageSize;
    final localIndex = index - firstRowOnPage;

    if (localIndex < 0 || localIndex >= _users.length) {
      return null;
    }
    final user = _users[localIndex];

    final currentUser = context.read<AuthBloc>().state.user;
    final isCurrentUser = user.id == currentUser?.id;
    final fullName = '${user.firstName} ${user.lastName}';

    return DataRow(
      cells: [
        DataCell(Text(fullName)),
        DataCell(Text(user.username)),
        DataCell(Text(user.email)),
        DataCell(
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: _getRoleColor(user.role),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              user.role?.label ?? '-',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
        DataCell(
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                icon: const Icon(Icons.edit, size: 18),
                tooltip: UserTexts.edit,
                onPressed: () => onEdit(user),
              ),
              IconButton(
                icon: Icon(
                  Icons.delete,
                  size: 18,
                  color: isCurrentUser ? Colors.grey : Colors.red,
                ),
                tooltip:
                    isCurrentUser ? UserTexts.cannotDeleteSelf : UserTexts.delete,
                onPressed: isCurrentUser ? null : () => onDelete(user),
              ),
            ],
          ),
        ),
      ],
    );
  }

  @override
  bool get isRowCountApproximate => false;

  @override
  int get rowCount => _rowCount;

  @override
  int get selectedRowCount => 0;

  Color _getRoleColor(UserRole? role) {
    switch (role) {
      case UserRole.globalAdmin:
        return AppColors.error;
      case UserRole.elected:
        return AppColors.warning;
      case UserRole.agent:
        return AppColors.info;
      case UserRole.citizen:
      default:
        return AppColors.success;
    }
  }
}
