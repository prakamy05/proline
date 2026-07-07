import '../../models/gym_model.dart';
import '../../models/plan_model.dart';
import '../../state/gym_data_provider.dart';

class GymRepository {
  final GymDataProvider _provider;

  GymRepository(this._provider);

  Future<List<Gym>> getGymsForOwner(int ownerId) async {
    return _provider.clientGyms;
  }

  Future<List<Map<String, dynamic>>> getStaff(int gymId) async {
    return _provider.activeStaff;
  }

  Future<List<Plan>> getPlans(int gymId) async {
    return _provider.activePlans;
  }

  Future<List<Map<String, dynamic>>> getExpenses(int gymId) async {
    return _provider.rawExpenses;
  }
}