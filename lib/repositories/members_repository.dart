import '../../models/member_model.dart';
import '../../state/gym_data_provider.dart';

class MembersRepository {
  final GymDataProvider _provider;

  MembersRepository(this._provider);

  Future<List<Member>> getMembers(int gymId) async {
    return _provider.activeMembers;
  }

  String getPlanExpiry(int memberId) {
    return _provider.getExpiryDateString(memberId);
  }

  Future<List<Map<String, dynamic>>> getPayments(int gymId) async {
    return _provider.rawPayments;
  }

  Future<List<Map<String, dynamic>>> getAttendance(int gymId) async {
    return _provider.rawAttendance;
  }
}