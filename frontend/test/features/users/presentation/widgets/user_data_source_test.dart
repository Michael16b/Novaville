import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/features/users/data/models/user.dart';
import 'package:frontend/features/users/data/models/user_role.dart';
import 'package:frontend/features/users/presentation/widgets/user_data_source.dart';

void main() {
  const user1 = User(
    id: 1,
    username: 'admin',
    email: 'admin@example.com',
    firstName: 'Admin',
    lastName: 'User',
    role: UserRole.globalAdmin,
  );
  const user2 = User(
    id: 2,
    username: 'bob',
    email: 'bob@example.com',
    firstName: 'Bob',
    lastName: 'Smith',
    role: UserRole.citizen,
  );

  UserDataSource buildSource({
    List<User> users = const [],
    int rowCount = 0,
    int page = 1,
    int pageSize = 20,
    int? currentUserId,
    void Function(User)? onEdit,
    void Function(User)? onDelete,
  }) {
    return UserDataSource(
      users: users,
      rowCount: rowCount,
      page: page,
      pageSize: pageSize,
      currentUserId: currentUserId,
      onEdit: onEdit ?? (_) {},
      onDelete: onDelete ?? (_) {},
    );
  }

  group('UserDataSource', () {
    test('rowCount returns the provided value', () {
      expect(buildSource(rowCount: 42).rowCount, 42);
    });

    test('isRowCountApproximate is false', () {
      expect(buildSource().isRowCountApproximate, isFalse);
    });

    test('selectedRowCount is 0', () {
      expect(buildSource().selectedRowCount, 0);
    });

    test('getRow returns null when index is before the first row on the page', () {
      // page=2, pageSize=20: first row on page is at absolute index 20.
      // Requesting index 0 → localIndex = 0 - 20 = -20 → out of bounds for this page → null.
      final source = buildSource(users: [user1], rowCount: 21, page: 2, pageSize: 20);
      expect(source.getRow(0), isNull);
    });

    test('getRow returns null when local index exceeds available users', () {
      final source = buildSource(users: [user1], rowCount: 1, page: 1, pageSize: 20);
      expect(source.getRow(1), isNull);
    });

    test('getRow returns a DataRow for a valid index', () {
      final source = buildSource(users: [user1, user2], rowCount: 2, page: 1, pageSize: 20);
      expect(source.getRow(0), isA<DataRow>());
      expect(source.getRow(1), isA<DataRow>());
    });

    test('delete button is disabled (onPressed null) for the current user', () {
      final source = buildSource(
        users: [user1],
        rowCount: 1,
        page: 1,
        pageSize: 20,
        currentUserId: user1.id,
      );
      final row = source.getRow(0)!;
      final actions = row.cells[4].child as Row;
      final deleteButton = actions.children[1] as IconButton;
      expect(deleteButton.onPressed, isNull);
    });

    test('delete button is enabled (onPressed non-null) for other users', () {
      final source = buildSource(
        users: [user2],
        rowCount: 1,
        page: 1,
        pageSize: 20,
        currentUserId: user1.id, // user1 is current, user2 is not
      );
      final row = source.getRow(0)!;
      final actions = row.cells[4].child as Row;
      final deleteButton = actions.children[1] as IconButton;
      expect(deleteButton.onPressed, isNotNull);
    });

    test('delete button invokes onDelete callback with the correct user', () {
      User? deletedUser;
      final source = buildSource(
        users: [user1, user2],
        rowCount: 2,
        page: 1,
        pageSize: 20,
        currentUserId: user1.id, // user1 is current; user2 can be deleted
        onDelete: (u) => deletedUser = u,
      );
      final row = source.getRow(1)!; // user2
      final actions = row.cells[4].child as Row;
      final deleteButton = actions.children[1] as IconButton;
      deleteButton.onPressed!();
      expect(deletedUser, equals(user2));
    });

    test('edit button invokes onEdit callback with the correct user', () {
      User? editedUser;
      final source = buildSource(
        users: [user1],
        rowCount: 1,
        page: 1,
        pageSize: 20,
        currentUserId: null,
        onEdit: (u) => editedUser = u,
      );
      final row = source.getRow(0)!;
      final actions = row.cells[4].child as Row;
      final editButton = actions.children[0] as IconButton;
      editButton.onPressed!();
      expect(editedUser, equals(user1));
    });

    test('getRow returns correct user data in cells', () {
      final source = buildSource(users: [user1], rowCount: 1, page: 1, pageSize: 20);
      final row = source.getRow(0)!;
      expect((row.cells[0].child as Text).data, 'Admin User');
      expect((row.cells[1].child as Text).data, 'admin');
      expect((row.cells[2].child as Text).data, 'admin@example.com');
    });
  });
}
