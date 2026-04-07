import 'package:frontend/features/reports/data/models/neighborhood.dart';

/// Repository interface for neighborhoods (quartiers).
abstract class INeighborhoodRepository {
  /// Lists all neighborhoods.
  Future<List<Neighborhood>> listNeighborhoods();

  /// Creates a neighborhood.
  Future<void> createNeighborhood(String name, String postalCode);

  /// Updates a neighborhood and returns the updated entity.
  Future<Neighborhood> updateNeighborhood(int id, String name, String postalCode);

  /// Deletes a neighborhood by id.
  Future<void> deleteNeighborhood(int id);
}

