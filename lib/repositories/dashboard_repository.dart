import 'package:dio/dio.dart';
import '../core/network/api_client.dart';
import '../models/member_model.dart';
import '../models/plan_model.dart';

class DashboardRepository {
  final ApiClient _client = ApiClient();

  /// Single-call Master Synchronization Endpoint
  Future<Map<String, dynamic>> fetchCompleteBranchSync(int gymId) async {
    try {
      // 🚀 FIXED: Added /v1 back explicitly to target domain routing layer
      final response = await _client.dio.get('/v1/gyms/$gymId/sync');
      return response.data as Map<String, dynamic>;
    } catch (e) {
      throw Exception("Failed to sync workspace engine records: $e");
    }
  }
  
  /// Sends attendance logging event up to cloud database server
  Future<Map<String, dynamic>> logMemberAttendance(int gymId, int memberId) async {
    try {
      // 🚀 FIXED: Added /v1 prefix configuration mapping layer
      final response = await _client.dio.post('/v1/gyms/$gymId/attendance', data: {
        'memberId': memberId,
      });
      return response.data as Map<String, dynamic>; 
    } catch (e) {
      throw Exception("Failed to transmit attendance record: $e");
    }
  }

  /// Sends a new member portfolio up to your cloud server database
  Future<void> uploadNewMember(int gymId, Member member) async {
    try {
      final Map<String, dynamic> camelCasePayload = {
        'membershipNumber': member.membershipNumber,
        'name': member.name,
        'phone': member.phone,
        'gender': member.gender,
        'email': member.email,
        'photoUrl': member.photoUrl,
        'address': member.address,
        'dob': member.dob?.toIso8601String().substring(0, 10),
        'joinedDate': member.joinedDate.toIso8601String(),
        'dueAmount': member.dueAmount,
        'status': member.status,
      };

      // 🚀 FIXED: Added /v1 prefix configuration mapping layer
      await _client.dio.post('/v1/gyms/$gymId/members', data: camelCasePayload);
    } catch (e) {
      throw Exception("Failed to upload new member session node: $e");
    }
  }

  /// Deploys a new downstream branch infrastructure map block
  Future<Map<String, dynamic>> uploadNewBranch(String branchName) async {
    try {
      // 🚀 FIXED: Added /v1 prefix configuration mapping layer
      final response = await _client.dio.post('/v1/gyms/branch', data: {
        'name': branchName,
      });
      return response.data as Map<String, dynamic>;
    } catch (e) {
      throw Exception("Failed to request backend branch allocation: $e");
    }
  }

  /// Transmits a freshly initialized plan package payload to the database
  Future<bool> uploadNewPlan(int gymId, Plan plan) async {
    try {
      // 🚀 FIXED: Added /v1 prefix configuration mapping layer
      final response = await _client.dio.post('/v1/gyms/$gymId/plans', data: {
        'name': plan.name,
        'price': plan.price,
        'durationValue': plan.durationValue,
        'durationType': plan.durationType,
      });
      return response.statusCode == 201;
    } catch (e) {
      throw Exception("Network execution failure while deploying plan catalog: $e");
    }
  }

  /// Transmits pre-registered staff metrics with custom permission matrices to backend servers
  Future<Map<String, dynamic>> uploadNewStaff(int gymId, Map<String, dynamic> staffPayload) async {
    try {
      // 🚀 FIXED: Retained clean single /v1 path context configuration mapping layer
      final response = await _client.dio.post('/v1/gyms/$gymId/staff', data: staffPayload);
      return response.data as Map<String, dynamic>;
    } catch (e) {
      throw Exception("Failed to register new staff workspace configuration: $e");
    }
  }
}