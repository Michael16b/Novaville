import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/features/surveys/application/bloc/surveys_bloc.dart';
import 'package:frontend/features/surveys/data/models/survey.dart';
import 'package:frontend/features/surveys/data/survey_repository.dart';
import 'package:frontend/features/users/data/models/user.dart';
import 'package:frontend/features/users/data/models/user_role.dart';

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

const _testUser = User(
  id: 1,
  username: 'agent',
  firstName: 'Agent',
  lastName: 'Test',
);

final _survey1 = Survey(
  id: 1,
  title: 'Sondage test 1',
  description: 'Description 1',
  address: '1 Rue de la Paix, Novaville',
  startDate: DateTime(2025, 6),
  endDate: DateTime(2025, 12, 31),
  createdAt: DateTime(2025, 6),
  totalVotes: 3,
  options: const [],
  createdBy: _testUser,
);

final _survey2 = Survey(
  id: 2,
  title: 'Sondage test 2',
  description: 'Description 2',
  address: '2 Avenue de la Liberté, Novaville',
  startDate: DateTime(2025, 7),
  endDate: DateTime(2025, 12, 31),
  createdAt: DateTime(2025, 7),
  totalVotes: 0,
  options: const [],
  createdBy: _testUser,
);

// ---------------------------------------------------------------------------
// Fake repository
// ---------------------------------------------------------------------------

class _FakeSurveyRepository implements ISurveyRepository {
  _FakeSurveyRepository({
    this.surveys = const [],
    this.shouldThrow = false,
    this.shouldThrowOnCreate = false,
    this.shouldThrowOnUpdate = false,
    this.shouldThrowOnDelete = false,
    this.shouldThrowOnVote = false,
    this.errorMessage = 'Network error',
  });

  final List<Survey> surveys;
  final bool shouldThrow;
  final bool shouldThrowOnCreate;
  final bool shouldThrowOnUpdate;
  final bool shouldThrowOnDelete;
  final bool shouldThrowOnVote;
  final String errorMessage;

  @override
  Future<SurveyPage> listSurveys({
    String? exactAddress,
    UserRole? citizenTarget,
    String? ordering,
    int page = 1,
  }) async {
    if (shouldThrow) throw Exception(errorMessage);
    return SurveyPage(count: surveys.length, results: surveys);
  }

  @override
  Future<void> createSurvey({
    required String question,
    required String description,
    required String address,
    required List<String> options,
    UserRole? citizenTarget,
  }) async {
    if (shouldThrowOnCreate) throw Exception(errorMessage);
  }

  @override
  Future<void> updateSurvey({
    required int surveyId,
    required String question,
    required String description,
    required String address,
    UserRole? citizenTarget,
  }) async {
    if (shouldThrowOnUpdate) throw Exception(errorMessage);
  }

  @override
  Future<void> deleteSurvey({required int surveyId}) async {
    if (shouldThrowOnDelete) throw Exception(errorMessage);
  }

  @override
  Future<void> vote({required int surveyId, required int optionId}) async {
    if (shouldThrowOnVote) throw Exception(errorMessage);
  }
}

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

void main() {
  group('SurveysBloc', () {
    // ── Initial state ──────────────────────────────────────────────────────

    test('initial state has status initial and empty surveys', () async {
      final bloc = SurveysBloc(repository: _FakeSurveyRepository());
      expect(bloc.state.status, SurveysStatus.initial);
      expect(bloc.state.surveys, isEmpty);
      expect(bloc.state.error, isNull);
      await bloc.close();
    });

    // ── Load – success path ────────────────────────────────────────────────

    test('SurveysLoadRequested emits loading then loaded on success', () async {
      final repo = _FakeSurveyRepository(surveys: [_survey1, _survey2]);
      final bloc = SurveysBloc(repository: repo);

      final expectation = expectLater(
        bloc.stream,
        emitsInOrder([
          isA<SurveysState>().having(
            (s) => s.status,
            'status',
            SurveysStatus.loading,
          ),
          isA<SurveysState>()
              .having((s) => s.status, 'status', SurveysStatus.loaded)
              .having((s) => s.surveys, 'surveys', [_survey1, _survey2])
              .having((s) => s.count, 'count', 2),
        ]),
      );

      bloc.add(const SurveysLoadRequested(citizenTargetSet: true));
      await expectation;
      await bloc.close();
    });

    // ── Load – failure path ────────────────────────────────────────────────

    test('SurveysLoadRequested emits loading then failure on error', () async {
      final bloc = SurveysBloc(
        repository: _FakeSurveyRepository(
          shouldThrow: true,
          errorMessage: 'Server error',
        ),
      );

      final expectation = expectLater(
        bloc.stream,
        emitsInOrder([
          isA<SurveysState>().having(
            (s) => s.status,
            'status',
            SurveysStatus.loading,
          ),
          isA<SurveysState>()
              .having((s) => s.status, 'status', SurveysStatus.failure)
              .having((s) => s.error, 'error', contains('Server error')),
        ]),
      );

      bloc.add(const SurveysLoadRequested(citizenTargetSet: true));
      await expectation;
      await bloc.close();
    });

    // ── Filter ────────────────────────────────────────────────────────────

    test('SurveysFilterChanged reloads with updated filters', () async {
      final repo = _FakeSurveyRepository(surveys: [_survey1]);
      final bloc = SurveysBloc(repository: repo);

      // Initial load
      final loadExpectation = expectLater(
        bloc.stream,
        emitsInOrder([
          isA<SurveysState>().having(
            (s) => s.status,
            'status',
            SurveysStatus.loading,
          ),
          isA<SurveysState>().having(
            (s) => s.status,
            'status',
            SurveysStatus.loaded,
          ),
        ]),
      );
      bloc.add(const SurveysLoadRequested(citizenTargetSet: true));
      await loadExpectation;

      // Apply filter
      final filterExpectation = expectLater(
        bloc.stream,
        emitsInOrder([
          isA<SurveysState>().having(
            (s) => s.status,
            'status',
            SurveysStatus.loading,
          ),
          isA<SurveysState>()
              .having((s) => s.status, 'status', SurveysStatus.loaded)
              .having(
                (s) => s.exactAddress,
                'exactAddress',
                '1 Rue de la Paix, Novaville',
              ),
        ]),
      );
      bloc.add(
        const SurveysFilterChanged(
          exactAddress: '1 Rue de la Paix, Novaville',
          citizenTargetSet: true,
        ),
      );
      await filterExpectation;
      await bloc.close();
    });

    // ── Pagination ────────────────────────────────────────────────────────

    test('SurveysPageRequested loads the requested page', () async {
      final repo = _FakeSurveyRepository(surveys: [_survey1]);
      final bloc = SurveysBloc(repository: repo);

      // Initial load
      final loadExpectation = expectLater(
        bloc.stream,
        emitsInOrder([
          isA<SurveysState>().having(
            (s) => s.status,
            'status',
            SurveysStatus.loading,
          ),
          isA<SurveysState>().having(
            (s) => s.status,
            'status',
            SurveysStatus.loaded,
          ),
        ]),
      );
      bloc.add(const SurveysLoadRequested(citizenTargetSet: true));
      await loadExpectation;

      // Request page 2
      final pageExpectation = expectLater(
        bloc.stream,
        emitsInOrder([
          isA<SurveysState>().having(
            (s) => s.status,
            'status',
            SurveysStatus.loading,
          ),
          isA<SurveysState>().having(
            (s) => s.status,
            'status',
            SurveysStatus.loaded,
          ),
        ]),
      );
      bloc.add(const SurveysPageRequested(page: 2));
      await pageExpectation;
      await bloc.close();
    });

    // ── Create ────────────────────────────────────────────────────────────

    test(
      'SurveyCreateRequested emits creating, created, then reloads',
      () async {
        final repo = _FakeSurveyRepository(surveys: [_survey1]);
        final bloc = SurveysBloc(repository: repo);

        // Initial load
        final loadExpectation = expectLater(
          bloc.stream,
          emitsInOrder([
            isA<SurveysState>().having(
              (s) => s.status,
              'status',
              SurveysStatus.loading,
            ),
            isA<SurveysState>().having(
              (s) => s.status,
              'status',
              SurveysStatus.loaded,
            ),
          ]),
        );
        bloc.add(const SurveysLoadRequested(citizenTargetSet: true));
        await loadExpectation;

        final createExpectation = expectLater(
          bloc.stream,
          emitsInOrder([
            isA<SurveysState>().having(
              (s) => s.status,
              'status',
              SurveysStatus.creating,
            ),
            isA<SurveysState>().having(
              (s) => s.status,
              'status',
              SurveysStatus.created,
            ),
            isA<SurveysState>().having(
              (s) => s.status,
              'status',
              SurveysStatus.loading,
            ),
            isA<SurveysState>().having(
              (s) => s.status,
              'status',
              SurveysStatus.loaded,
            ),
          ]),
        );
        bloc.add(
          const SurveyCreateRequested(
            question: 'Nouveau sondage ?',
            description: 'Description',
            address: '3 Rue Test, Novaville',
            options: ['Oui', 'Non'],
          ),
        );
        await createExpectation;
        await bloc.close();
      },
    );

    test('SurveyCreateRequested emits failure on error', () async {
      final repo = _FakeSurveyRepository(
        shouldThrowOnCreate: true,
        errorMessage: 'Create failed',
        surveys: [_survey1],
      );
      final bloc = SurveysBloc(repository: repo);

      // Initial load
      final loadExpectation = expectLater(
        bloc.stream,
        emitsInOrder([
          isA<SurveysState>().having(
            (s) => s.status,
            'status',
            SurveysStatus.loading,
          ),
          isA<SurveysState>().having(
            (s) => s.status,
            'status',
            SurveysStatus.loaded,
          ),
        ]),
      );
      bloc.add(const SurveysLoadRequested(citizenTargetSet: true));
      await loadExpectation;

      final createExpectation = expectLater(
        bloc.stream,
        emitsInOrder([
          isA<SurveysState>().having(
            (s) => s.status,
            'status',
            SurveysStatus.creating,
          ),
          isA<SurveysState>()
              .having((s) => s.status, 'status', SurveysStatus.failure)
              .having((s) => s.error, 'error', contains('Create failed')),
        ]),
      );
      bloc.add(
        const SurveyCreateRequested(
          question: 'Sondage ?',
          description: 'Desc',
          address: 'Adresse',
          options: ['Oui', 'Non'],
        ),
      );
      await createExpectation;
      await bloc.close();
    });

    // ── Update ────────────────────────────────────────────────────────────

    test(
      'SurveyUpdateRequested emits updating, updated, then reloads',
      () async {
        final repo = _FakeSurveyRepository(surveys: [_survey1]);
        final bloc = SurveysBloc(repository: repo);

        final loadExpectation = expectLater(
          bloc.stream,
          emitsInOrder([
            isA<SurveysState>().having(
              (s) => s.status,
              'status',
              SurveysStatus.loading,
            ),
            isA<SurveysState>().having(
              (s) => s.status,
              'status',
              SurveysStatus.loaded,
            ),
          ]),
        );
        bloc.add(const SurveysLoadRequested(citizenTargetSet: true));
        await loadExpectation;

        final updateExpectation = expectLater(
          bloc.stream,
          emitsInOrder([
            isA<SurveysState>().having(
              (s) => s.status,
              'status',
              SurveysStatus.updating,
            ),
            isA<SurveysState>().having(
              (s) => s.status,
              'status',
              SurveysStatus.updated,
            ),
            isA<SurveysState>().having(
              (s) => s.status,
              'status',
              SurveysStatus.loading,
            ),
            isA<SurveysState>().having(
              (s) => s.status,
              'status',
              SurveysStatus.loaded,
            ),
          ]),
        );
        bloc.add(
          const SurveyUpdateRequested(
            surveyId: 1,
            question: 'Question modifiée ?',
            description: 'Nouvelle description',
            address: '1 Rue de la Paix, Novaville',
          ),
        );
        await updateExpectation;
        await bloc.close();
      },
    );

    test('SurveyUpdateRequested emits failure on error', () async {
      final repo = _FakeSurveyRepository(
        shouldThrowOnUpdate: true,
        errorMessage: 'Update failed',
        surveys: [_survey1],
      );
      final bloc = SurveysBloc(repository: repo);

      final loadExpectation = expectLater(
        bloc.stream,
        emitsInOrder([
          isA<SurveysState>().having(
            (s) => s.status,
            'status',
            SurveysStatus.loading,
          ),
          isA<SurveysState>().having(
            (s) => s.status,
            'status',
            SurveysStatus.loaded,
          ),
        ]),
      );
      bloc.add(const SurveysLoadRequested(citizenTargetSet: true));
      await loadExpectation;

      final updateExpectation = expectLater(
        bloc.stream,
        emitsInOrder([
          isA<SurveysState>().having(
            (s) => s.status,
            'status',
            SurveysStatus.updating,
          ),
          isA<SurveysState>()
              .having((s) => s.status, 'status', SurveysStatus.failure)
              .having((s) => s.error, 'error', contains('Update failed')),
        ]),
      );
      bloc.add(
        const SurveyUpdateRequested(
          surveyId: 1,
          question: 'Question ?',
          description: 'Description',
          address: 'Adresse',
        ),
      );
      await updateExpectation;
      await bloc.close();
    });

    // ── Delete ────────────────────────────────────────────────────────────

    test(
      'SurveyDeleteRequested emits deleting, deleted, then reloads',
      () async {
        final repo = _FakeSurveyRepository(surveys: [_survey1, _survey2]);
        final bloc = SurveysBloc(repository: repo);

        final loadExpectation = expectLater(
          bloc.stream,
          emitsInOrder([
            isA<SurveysState>().having(
              (s) => s.status,
              'status',
              SurveysStatus.loading,
            ),
            isA<SurveysState>()
                .having((s) => s.status, 'status', SurveysStatus.loaded)
                .having((s) => s.surveys.length, 'count', 2),
          ]),
        );
        bloc.add(const SurveysLoadRequested(citizenTargetSet: true));
        await loadExpectation;

        final deleteExpectation = expectLater(
          bloc.stream,
          emitsInOrder([
            isA<SurveysState>().having(
              (s) => s.status,
              'status',
              SurveysStatus.deleting,
            ),
            isA<SurveysState>().having(
              (s) => s.status,
              'status',
              SurveysStatus.deleted,
            ),
            isA<SurveysState>().having(
              (s) => s.status,
              'status',
              SurveysStatus.loading,
            ),
            isA<SurveysState>().having(
              (s) => s.status,
              'status',
              SurveysStatus.loaded,
            ),
          ]),
        );
        bloc.add(const SurveyDeleteRequested(surveyId: 1));
        await deleteExpectation;
        await bloc.close();
      },
    );

    test('SurveyDeleteRequested emits failure on error', () async {
      final repo = _FakeSurveyRepository(
        shouldThrowOnDelete: true,
        errorMessage: 'Delete failed',
        surveys: [_survey1],
      );
      final bloc = SurveysBloc(repository: repo);

      final loadExpectation = expectLater(
        bloc.stream,
        emitsInOrder([
          isA<SurveysState>().having(
            (s) => s.status,
            'status',
            SurveysStatus.loading,
          ),
          isA<SurveysState>().having(
            (s) => s.status,
            'status',
            SurveysStatus.loaded,
          ),
        ]),
      );
      bloc.add(const SurveysLoadRequested(citizenTargetSet: true));
      await loadExpectation;

      final deleteExpectation = expectLater(
        bloc.stream,
        emitsInOrder([
          isA<SurveysState>().having(
            (s) => s.status,
            'status',
            SurveysStatus.deleting,
          ),
          isA<SurveysState>()
              .having((s) => s.status, 'status', SurveysStatus.failure)
              .having((s) => s.error, 'error', contains('Delete failed')),
        ]),
      );
      bloc.add(const SurveyDeleteRequested(surveyId: 1));
      await deleteExpectation;
      await bloc.close();
    });

    // ── Vote ──────────────────────────────────────────────────────────────

    test('SurveyVoteRequested emits voting, voted, then reloads', () async {
      final repo = _FakeSurveyRepository(surveys: [_survey1]);
      final bloc = SurveysBloc(repository: repo);

      final loadExpectation = expectLater(
        bloc.stream,
        emitsInOrder([
          isA<SurveysState>().having(
            (s) => s.status,
            'status',
            SurveysStatus.loading,
          ),
          isA<SurveysState>().having(
            (s) => s.status,
            'status',
            SurveysStatus.loaded,
          ),
        ]),
      );
      bloc.add(const SurveysLoadRequested(citizenTargetSet: true));
      await loadExpectation;

      final voteExpectation = expectLater(
        bloc.stream,
        emitsInOrder([
          isA<SurveysState>().having(
            (s) => s.status,
            'status',
            SurveysStatus.voting,
          ),
          isA<SurveysState>().having(
            (s) => s.status,
            'status',
            SurveysStatus.voted,
          ),
          isA<SurveysState>().having(
            (s) => s.status,
            'status',
            SurveysStatus.loading,
          ),
          isA<SurveysState>().having(
            (s) => s.status,
            'status',
            SurveysStatus.loaded,
          ),
        ]),
      );
      bloc.add(const SurveyVoteRequested(surveyId: 1, optionId: 1));
      await voteExpectation;
      await bloc.close();
    });

    test('SurveyVoteRequested emits failure on error', () async {
      final repo = _FakeSurveyRepository(
        shouldThrowOnVote: true,
        errorMessage: 'Vote failed',
        surveys: [_survey1],
      );
      final bloc = SurveysBloc(repository: repo);

      final loadExpectation = expectLater(
        bloc.stream,
        emitsInOrder([
          isA<SurveysState>().having(
            (s) => s.status,
            'status',
            SurveysStatus.loading,
          ),
          isA<SurveysState>().having(
            (s) => s.status,
            'status',
            SurveysStatus.loaded,
          ),
        ]),
      );
      bloc.add(const SurveysLoadRequested(citizenTargetSet: true));
      await loadExpectation;

      final voteExpectation = expectLater(
        bloc.stream,
        emitsInOrder([
          isA<SurveysState>().having(
            (s) => s.status,
            'status',
            SurveysStatus.voting,
          ),
          isA<SurveysState>()
              .having((s) => s.status, 'status', SurveysStatus.failure)
              .having((s) => s.error, 'error', contains('Vote failed')),
        ]),
      );
      bloc.add(const SurveyVoteRequested(surveyId: 1, optionId: 1));
      await voteExpectation;
      await bloc.close();
    });
  });
}
