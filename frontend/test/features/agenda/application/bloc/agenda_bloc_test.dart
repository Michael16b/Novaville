import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/features/agenda/application/bloc/agenda_bloc/agenda_bloc.dart';
import 'package:frontend/features/agenda/data/event_repository.dart';
import 'package:frontend/features/agenda/data/models/community_event.dart';
import 'package:frontend/features/agenda/data/models/event_theme.dart';
import 'package:frontend/features/users/data/models/user.dart';

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

/// Minimal [User] used as event creator in test fixtures.
const _testUser = User(
  id: 1,
  username: 'agent',
  firstName: 'Agent',
  lastName: 'Test',
);

/// A single [CommunityEvent] used across tests.
final _event1 = CommunityEvent(
  id: 1,
  title: 'Réunion publique',
  description: 'Réunion de quartier',
  startDate: DateTime(2025, 6),
  endDate: DateTime(2025, 6, 1, 2),
  createdBy: _testUser,
);

/// A second [CommunityEvent] on a different day.
final _event2 = CommunityEvent(
  id: 2,
  title: 'Fête de la musique',
  description: 'Concert en plein air',
  startDate: DateTime(2025, 6, 21),
  endDate: DateTime(2025, 6, 21, 22),
  createdBy: _testUser,
  themeId: 1,
  theme: EventTheme.culture,
);

// ---------------------------------------------------------------------------
// Fake repository
// ---------------------------------------------------------------------------

class _FakeEventRepository implements IEventRepository {
  _FakeEventRepository({
    this.themes = const [],
    this.pages = const [[]],
    this.shouldThrow = false,
    this.shouldThrowOnCreate = false,
    this.shouldThrowOnDelete = false,
    this.shouldThrowOnUpdate = false,
    this.errorMessage = 'Network error',
  });

  final List<ThemeItem> themes;

  /// Each sub-list represents one page of results.
  /// If [shouldThrow], listEvents raises after themes are loaded.
  final List<List<CommunityEvent>> pages;

  final bool shouldThrow;
  final bool shouldThrowOnCreate;
  final bool shouldThrowOnDelete;
  final bool shouldThrowOnUpdate;
  final String errorMessage;

  int _listCallCount = 0;

  @override
  Future<List<ThemeItem>> listThemes() async => themes;

  @override
  Future<EventPage> listEvents({
    String? ordering,
    String? search,
    int page = 1,
    int? theme,
    DateTime? startDateGte,
    DateTime? startDateLte,
  }) async {
    if (shouldThrow) throw Exception(errorMessage);
    final index = (page - 1).clamp(0, pages.length - 1);
    _listCallCount++;
    final results = pages[index];
    final isLastPage = page >= pages.length;
    return EventPage(
      count: pages.fold(0, (sum, p) => sum + p.length),
      next: isLastPage ? null : 'http://example.com/?page=${page + 1}',
      results: results,
    );
  }

  @override
  Future<CommunityEvent> getEvent({required int eventId}) async =>
      throw UnimplementedError();

  @override
  Future<void> createEvent({
    required String title,
    required String description,
    required DateTime startDate,
    required DateTime endDate,
    int? theme,
  }) async {
    if (shouldThrowOnCreate) throw Exception(errorMessage);
  }

  @override
  Future<CommunityEvent> updateEvent({
    required int eventId,
    String? title,
    String? description,
    DateTime? startDate,
    DateTime? endDate,
    int? theme,
  }) async {
    if (shouldThrowOnUpdate) throw Exception(errorMessage);
    return _event1.copyWith(id: eventId, title: title ?? _event1.title);
  }

  @override
  Future<void> deleteEvent({required int eventId}) async {
    if (shouldThrowOnDelete) throw Exception(errorMessage);
  }
}

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

void main() {
  group('AgendaBloc', () {
    // ── Initial state ──────────────────────────────────────────────────────

    test('initial state is AgendaStatus.initial with empty events', () async {
      final bloc = AgendaBloc(repository: _FakeEventRepository());
      expect(bloc.state.status, AgendaStatus.initial);
      expect(bloc.state.events, isEmpty);
      expect(bloc.state.error, isNull);
      await bloc.close();
    });

    // ── Load – success path ────────────────────────────────────────────────

    test('AgendaLoadRequested emits loading then loaded on success', () async {
      final repo = _FakeEventRepository(
        pages: [
          [_event1],
        ],
      );
      final bloc = AgendaBloc(repository: repo);

      final expectation = expectLater(
        bloc.stream,
        emitsInOrder([
          isA<AgendaState>().having(
            (s) => s.status,
            'status',
            AgendaStatus.loading,
          ),
          isA<AgendaState>()
              .having((s) => s.status, 'status', AgendaStatus.loaded)
              .having((s) => s.events, 'events', [_event1])
              .having((s) => s.count, 'count', 1),
        ]),
      );

      bloc.add(const AgendaLoadRequested());
      await expectation;
      await bloc.close();
    });

    // ── Load – multi-page ──────────────────────────────────────────────────

    test('AgendaLoadRequested fetches all pages and merges results', () async {
      final repo = _FakeEventRepository(
        pages: [
          [_event1],
          [_event2],
        ],
      );
      final bloc = AgendaBloc(repository: repo);

      final expectation = expectLater(
        bloc.stream,
        emitsInOrder([
          isA<AgendaState>().having(
            (s) => s.status,
            'status',
            AgendaStatus.loading,
          ),
          isA<AgendaState>()
              .having((s) => s.status, 'status', AgendaStatus.loaded)
              .having((s) => s.events, 'events', [_event1, _event2])
              .having((s) => s.count, 'count', 2),
        ]),
      );

      bloc.add(const AgendaLoadRequested());
      await expectation;
      // Should have called listEvents twice (once per page).
      expect(repo._listCallCount, 2);
      await bloc.close();
    });

    // ── Load – failure path ────────────────────────────────────────────────

    test('AgendaLoadRequested emits loading then failure on error', () async {
      final bloc = AgendaBloc(
        repository: _FakeEventRepository(
          shouldThrow: true,
          errorMessage: 'Server error',
        ),
      );

      final expectation = expectLater(
        bloc.stream,
        emitsInOrder([
          isA<AgendaState>().having(
            (s) => s.status,
            'status',
            AgendaStatus.loading,
          ),
          isA<AgendaState>()
              .having((s) => s.status, 'status', AgendaStatus.failure)
              .having((s) => s.error, 'error', contains('Server error')),
        ]),
      );

      bloc.add(const AgendaLoadRequested());
      await expectation;
      await bloc.close();
    });

    // ── resolveThemeId ─────────────────────────────────────────────────────

    test('resolveThemeId returns null for null input', () async {
      final bloc = AgendaBloc(repository: _FakeEventRepository());
      expect(bloc.resolveThemeId(null), isNull);
      await bloc.close();
    });

    test('resolveThemeId returns null when no themes are cached', () async {
      final bloc = AgendaBloc(repository: _FakeEventRepository());
      expect(bloc.resolveThemeId('Sport'), isNull);
      await bloc.close();
    });

    test('resolveThemeId matches French label case-insensitively', () async {
      final repo = _FakeEventRepository(
        themes: [const ThemeItem(id: 3, title: 'Citoyenneté')],
        pages: [
          [_event1],
        ],
      );
      final bloc = AgendaBloc(repository: repo);

      // Trigger load so themes are cached.
      final expectation = expectLater(
        bloc.stream,
        emitsInOrder([
          isA<AgendaState>().having(
            (s) => s.status,
            'status',
            AgendaStatus.loading,
          ),
          isA<AgendaState>().having(
            (s) => s.status,
            'status',
            AgendaStatus.loaded,
          ),
        ]),
      );
      bloc.add(const AgendaLoadRequested());
      await expectation;

      // Exact match
      expect(bloc.resolveThemeId('Citoyenneté'), 3);
      // Case-insensitive match
      expect(bloc.resolveThemeId('citoyenneté'), 3);
      // No match
      expect(bloc.resolveThemeId('Environnement'), isNull);

      await bloc.close();
    });

    // ── Filter ─────────────────────────────────────────────────────────────

    test('AgendaFilterRequested reloads events with updated filter', () async {
      final repo = _FakeEventRepository(
        pages: [
          [_event1],
        ],
      );
      final bloc = AgendaBloc(repository: repo);

      // Initial load
      final loadExpectation = expectLater(
        bloc.stream,
        emitsInOrder([
          isA<AgendaState>().having(
            (s) => s.status,
            'status',
            AgendaStatus.loading,
          ),
          isA<AgendaState>().having(
            (s) => s.status,
            'status',
            AgendaStatus.loaded,
          ),
        ]),
      );
      bloc.add(const AgendaLoadRequested());
      await loadExpectation;

      // Apply filter
      final filterExpectation = expectLater(
        bloc.stream,
        emitsInOrder([
          isA<AgendaState>().having(
            (s) => s.status,
            'status',
            AgendaStatus.loading,
          ),
          isA<AgendaState>().having(
            (s) => s.status,
            'status',
            AgendaStatus.loaded,
          ),
        ]),
      );
      bloc.add(const AgendaFilterRequested(themeTitle: 'Sport'));
      await filterExpectation;

      await bloc.close();
    });

    // ── Create ─────────────────────────────────────────────────────────────

    test(
      'AgendaEventCreateRequested emits creating, created, then reloads',
      () async {
        final repo = _FakeEventRepository(
          pages: [
            [_event1],
          ],
        );
        final bloc = AgendaBloc(repository: repo);

        // Initial load
        final loadExpectation = expectLater(
          bloc.stream,
          emitsInOrder([
            isA<AgendaState>().having(
              (s) => s.status,
              'status',
              AgendaStatus.loading,
            ),
            isA<AgendaState>().having(
              (s) => s.status,
              'status',
              AgendaStatus.loaded,
            ),
          ]),
        );
        bloc.add(const AgendaLoadRequested());
        await loadExpectation;

        // Create
        final createExpectation = expectLater(
          bloc.stream,
          emitsInOrder([
            isA<AgendaState>().having(
              (s) => s.status,
              'status',
              AgendaStatus.creating,
            ),
            isA<AgendaState>().having(
              (s) => s.status,
              'status',
              AgendaStatus.created,
            ),
            isA<AgendaState>().having(
              (s) => s.status,
              'status',
              AgendaStatus.loaded,
            ),
          ]),
        );
        bloc.add(
          AgendaEventCreateRequested(
            title: 'Nouvel événement',
            description: 'Description',
            startDate: DateTime(2025, 7),
            endDate: DateTime(2025, 7, 1, 2),
          ),
        );
        await createExpectation;
        await bloc.close();
      },
    );

    test('AgendaEventCreateRequested emits failure on error', () async {
      final repo = _FakeEventRepository(
        shouldThrowOnCreate: true,
        errorMessage: 'Create failed',
        pages: [
          [_event1],
        ],
      );
      final bloc = AgendaBloc(repository: repo);

      // Initial load
      final loadExpectation = expectLater(
        bloc.stream,
        emitsInOrder([
          isA<AgendaState>().having(
            (s) => s.status,
            'status',
            AgendaStatus.loading,
          ),
          isA<AgendaState>().having(
            (s) => s.status,
            'status',
            AgendaStatus.loaded,
          ),
        ]),
      );
      bloc.add(const AgendaLoadRequested());
      await loadExpectation;

      final createExpectation = expectLater(
        bloc.stream,
        emitsInOrder([
          isA<AgendaState>().having(
            (s) => s.status,
            'status',
            AgendaStatus.creating,
          ),
          isA<AgendaState>()
              .having((s) => s.status, 'status', AgendaStatus.failure)
              .having((s) => s.error, 'error', contains('Create failed')),
        ]),
      );
      bloc.add(
        AgendaEventCreateRequested(
          title: 'Événement',
          description: 'Description',
          startDate: DateTime(2025, 7),
          endDate: DateTime(2025, 7, 1, 2),
        ),
      );
      await createExpectation;
      await bloc.close();
    });

    // ── Delete ─────────────────────────────────────────────────────────────

    test(
      'AgendaEventDeleteRequested emits deleting, deleted, then reloads',
      () async {
        final repo = _FakeEventRepository(
          pages: [
            [_event1, _event2],
          ],
        );
        final bloc = AgendaBloc(repository: repo);

        // Initial load
        final loadExpectation = expectLater(
          bloc.stream,
          emitsInOrder([
            isA<AgendaState>().having(
              (s) => s.status,
              'status',
              AgendaStatus.loading,
            ),
            isA<AgendaState>()
                .having((s) => s.status, 'status', AgendaStatus.loaded)
                .having((s) => s.events.length, 'count', 2),
          ]),
        );
        bloc.add(const AgendaLoadRequested());
        await loadExpectation;

        final deleteExpectation = expectLater(
          bloc.stream,
          emitsInOrder([
            isA<AgendaState>().having(
              (s) => s.status,
              'status',
              AgendaStatus.deleting,
            ),
            isA<AgendaState>()
                .having((s) => s.status, 'status', AgendaStatus.deleted)
                .having(
                  (s) => s.events.any((e) => e.id == _event1.id),
                  'event1 removed',
                  isFalse,
                ),
            isA<AgendaState>().having(
              (s) => s.status,
              'status',
              AgendaStatus.loaded,
            ),
          ]),
        );
        bloc.add(AgendaEventDeleteRequested(eventId: _event1.id));
        await deleteExpectation;
        await bloc.close();
      },
    );

    test('AgendaEventDeleteRequested emits failure on error', () async {
      final repo = _FakeEventRepository(
        shouldThrowOnDelete: true,
        errorMessage: 'Delete failed',
        pages: [
          [_event1],
        ],
      );
      final bloc = AgendaBloc(repository: repo);

      final loadExpectation = expectLater(
        bloc.stream,
        emitsInOrder([
          isA<AgendaState>().having(
            (s) => s.status,
            'status',
            AgendaStatus.loading,
          ),
          isA<AgendaState>().having(
            (s) => s.status,
            'status',
            AgendaStatus.loaded,
          ),
        ]),
      );
      bloc.add(const AgendaLoadRequested());
      await loadExpectation;

      final deleteExpectation = expectLater(
        bloc.stream,
        emitsInOrder([
          isA<AgendaState>().having(
            (s) => s.status,
            'status',
            AgendaStatus.deleting,
          ),
          isA<AgendaState>()
              .having((s) => s.status, 'status', AgendaStatus.failure)
              .having((s) => s.error, 'error', contains('Delete failed')),
        ]),
      );
      bloc.add(AgendaEventDeleteRequested(eventId: _event1.id));
      await deleteExpectation;
      await bloc.close();
    });

    // ── Update ─────────────────────────────────────────────────────────────

    test(
      'AgendaEventUpdateRequested emits updating, updated, then reloads',
      () async {
        final repo = _FakeEventRepository(
          pages: [
            [_event1],
          ],
        );
        final bloc = AgendaBloc(repository: repo);

        final loadExpectation = expectLater(
          bloc.stream,
          emitsInOrder([
            isA<AgendaState>().having(
              (s) => s.status,
              'status',
              AgendaStatus.loading,
            ),
            isA<AgendaState>().having(
              (s) => s.status,
              'status',
              AgendaStatus.loaded,
            ),
          ]),
        );
        bloc.add(const AgendaLoadRequested());
        await loadExpectation;

        final updateExpectation = expectLater(
          bloc.stream,
          emitsInOrder([
            isA<AgendaState>().having(
              (s) => s.status,
              'status',
              AgendaStatus.updating,
            ),
            isA<AgendaState>().having(
              (s) => s.status,
              'status',
              AgendaStatus.updated,
            ),
            isA<AgendaState>().having(
              (s) => s.status,
              'status',
              AgendaStatus.loaded,
            ),
          ]),
        );
        bloc.add(
          AgendaEventUpdateRequested(
            eventId: _event1.id,
            title: 'Titre modifié',
          ),
        );
        await updateExpectation;
        await bloc.close();
      },
    );

    test('AgendaEventUpdateRequested emits failure on error', () async {
      final repo = _FakeEventRepository(
        shouldThrowOnUpdate: true,
        errorMessage: 'Update failed',
        pages: [
          [_event1],
        ],
      );
      final bloc = AgendaBloc(repository: repo);

      final loadExpectation = expectLater(
        bloc.stream,
        emitsInOrder([
          isA<AgendaState>().having(
            (s) => s.status,
            'status',
            AgendaStatus.loading,
          ),
          isA<AgendaState>().having(
            (s) => s.status,
            'status',
            AgendaStatus.loaded,
          ),
        ]),
      );
      bloc.add(const AgendaLoadRequested());
      await loadExpectation;

      final updateExpectation = expectLater(
        bloc.stream,
        emitsInOrder([
          isA<AgendaState>().having(
            (s) => s.status,
            'status',
            AgendaStatus.updating,
          ),
          isA<AgendaState>()
              .having((s) => s.status, 'status', AgendaStatus.failure)
              .having((s) => s.error, 'error', contains('Update failed')),
        ]),
      );
      bloc.add(
        AgendaEventUpdateRequested(eventId: _event1.id, title: 'Titre modifié'),
      );
      await updateExpectation;
      await bloc.close();
    });
  });
}
