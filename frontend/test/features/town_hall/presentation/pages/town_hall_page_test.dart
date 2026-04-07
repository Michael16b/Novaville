import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/constants/texts/texts_town_hall.dart';
import 'package:frontend/features/neighborhood/data/neighborhood_repository.dart';
import 'package:frontend/features/reports/data/models/neighborhood.dart';
import 'package:frontend/features/town_hall/presentation/pages/town_hall_page.dart';

class FakeNeighborhoodRepository implements INeighborhoodRepository {
  FakeNeighborhoodRepository({this.items = const []});

  final List<Neighborhood> items;

  @override
  Future<void> createNeighborhood(String name, String postalCode) async {}

  @override
  Future<void> deleteNeighborhood(int id) async {}

  @override
  Future<List<Neighborhood>> listNeighborhoods() async => items;

  @override
  Future<Neighborhood> updateNeighborhood(
    int id,
    String name,
    String postalCode,
  ) async {
    return Neighborhood(id: id, name: name, postalCode: postalCode);
  }
}

void main() {
  Widget buildTestWidget(INeighborhoodRepository repository) {
    return MaterialApp(home: TownHallPage(neighborhoodRepository: repository));
  }

  testWidgets("affiche le header et l'état vide", (tester) async {
    final repository = FakeNeighborhoodRepository();

    await tester.pumpWidget(buildTestWidget(repository));
    await tester.pumpAndSettle();

    expect(find.text(TownHallTexts.title), findsAtLeastNWidgets(1));
    expect(find.text(TownHallTexts.noNeighborhoods), findsOneWidget);
    expect(find.byType(FloatingActionButton), findsOneWidget);
  });

  testWidgets('affiche les quartiers retournes par le repository', (
    tester,
  ) async {
    final repository = FakeNeighborhoodRepository(
      items: const [Neighborhood(id: 1, name: 'Centre', postalCode: '75001')],
    );

    await tester.pumpWidget(buildTestWidget(repository));
    await tester.pumpAndSettle();

    expect(find.text('Centre'), findsOneWidget);
    expect(find.text('CP: 75001'), findsOneWidget);
  });

  testWidgets('filtre les quartiers par nom', (tester) async {
    final repository = FakeNeighborhoodRepository(
      items: const [
        Neighborhood(id: 1, name: 'Centre', postalCode: '75001'),
        Neighborhood(id: 2, name: 'Nord', postalCode: '75002'),
      ],
    );

    await tester.pumpWidget(buildTestWidget(repository));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField).first, 'Nord');
    await tester.pumpAndSettle();

    expect(find.text('Nord'), findsAtLeastNWidgets(1));
    expect(find.text('Centre'), findsNothing);
  });

  testWidgets('filtre les quartiers par code postal', (tester) async {
    final repository = FakeNeighborhoodRepository(
      items: const [
        Neighborhood(id: 1, name: 'Centre', postalCode: '75001'),
        Neighborhood(id: 2, name: 'Nord', postalCode: '75002'),
      ],
    );

    await tester.pumpWidget(buildTestWidget(repository));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField).first, '75002');
    await tester.pumpAndSettle();

    expect(find.text('Nord'), findsAtLeastNWidgets(1));
    expect(find.text('Centre'), findsNothing);
  });

  testWidgets('affiche la page suivante quand il y a plus de 20 quartiers', (
    tester,
  ) async {
    final items = List.generate(
      21,
      (index) => Neighborhood(
        id: index + 1,
        name: 'Quartier ${index + 1}',
        postalCode: '${75000 + index + 1}',
      ),
    );
    final repository = FakeNeighborhoodRepository(items: items);

    await tester.pumpWidget(buildTestWidget(repository));
    await tester.pumpAndSettle();

    expect(find.text('Quartier 21'), findsNothing);

    await tester.tap(find.byTooltip(TownHallTexts.nextPage));
    await tester.pumpAndSettle();

    expect(find.text('Quartier 21'), findsOneWidget);
  });
}
