import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../repositories/auth_repository.dart';
import '../repositories/dashboard_repository.dart';
import '../models/member_model.dart';
import '../models/plan_model.dart';
import '../models/gym_model.dart';

class GymDataProvider extends ChangeNotifier {
  final AuthRepository _authRepo = AuthRepository();
  final DashboardRepository _dashboardRepo = DashboardRepository();
  final _secureStorage = const FlutterSecureStorage();

  // Active Session State Parameters
  String? _token;
  int? _selectedGymId;
  String? ownerName;
  
  // Expose the raw session token safely for authorization header assemblies
  String? get token => _token;
  int get selectedGymId => _selectedGymId ?? 1;
  bool isLoading = false;
  bool isCheckingSession = true;

  // Getter to explicitly confirm safe runtime authentication state
  bool get isAuthenticated => _token != null && _selectedGymId != null;

  // Active Data Arrays consumed globally across Tab UI views
  List<Gym> clientGyms = [];
  List<Member> activeMembers = [];
  List<Plan> activePlans = [];
  List<Map<String, dynamic>> activeStaff = [];
  List<Map<String, dynamic>> rawExpenses = [];
  List<Map<String, dynamic>> rawPayments = [];
  List<Map<String, dynamic>> rawAttendance = [];

  // REAL-TIME FINANCIAL TRACKING CRITICAL VARIABLES
  double _lifetimePaymentsRevenue = 0.0;
  double _lifetimeExpensesOverhead = 0.0;

  // REAL-TIME B2B SAAS SUBSCRIPTION STATE PARAMETERS
  String saasPlanName = 'Trial';
  String saasExpiryDate = '';
  int saasDaysRemaining = 0;
  int saasMaxMembers = 0;
  int saasMaxBranches = 0;
  int saasMaxStaff = 0; 

  // 🚀 FIXED: Added localized persistent sorting state mapping properties
  String? _memberSortCriteria;
  String? get memberSortCriteria => _memberSortCriteria;

  // ROLE & PERMISSION MANAGEMENT PROPERTIES
  String userRole = 'OWNER'; 
  Map<String, dynamic> staffPermissions = {};
  bool isUnlinkedStaff = false; // Displays the "Not added by owner yet" layout block screen if true

  /// Universal check checking explicit feature flags or owner overrides
  bool hasPermission(String key) {
    if (userRole == 'OWNER') return true;
    return staffPermissions[key] == true;
  }

  // 🚀 FIXED: Added updates interceptor to handle criteria modifications from components
  void updateMemberSortCriteria(String targetCriteria) {
    _memberSortCriteria = targetCriteria;
    notifyListeners();
  }

  /// 1. Silent Storage Check called on App Launch Boot
  Future<bool> trySilentAutoLogin() async {
    isCheckingSession = true;
    notifyListeners();
    try {
      final savedToken = await _secureStorage.read(key: "auth_token");
      final savedGymId = await _secureStorage.read(key: "selected_gym_id");
      final savedOwnerName = await _secureStorage.read(key: "owner_name");
      final savedRole = await _secureStorage.read(key: "user_role") ?? "OWNER";

      if (savedToken != null && savedGymId != null) {
        _token = savedToken;
        _selectedGymId = int.tryParse(savedGymId);
        ownerName = savedOwnerName;
        userRole = savedRole;
        
        notifyListeners();
        await reloadCurrentGymData();
        return true; 
      }
    } catch (e) {
      debugPrint("Storage error structural failure: $e");
    } finally {
      isCheckingSession = false;
      notifyListeners();
    }
    return false;
  }

  /// 2. Handles manual login verification form data inputs
  Future<bool> loginWorkspace(String email, String password) async {
    isLoading = true;
    notifyListeners();
    try {
      final data = await _authRepo.loginWithEmail(email, password);
      
      _token = data['token'];
      userRole = data['role'] ?? 'OWNER';
      ownerName = data['owner_name'];

      final rawGymId = data['primary_gym_id'];
      if (rawGymId == null && userRole == 'STAFF') {
        isUnlinkedStaff = true;
        _selectedGymId = -1; // Block active routing paths
      } else {
        isUnlinkedStaff = false;
        _selectedGymId = int.parse(rawGymId.toString());
      }

      await _secureStorage.write(key: "auth_token", value: _token);
      await _secureStorage.write(key: "selected_gym_id", value: _selectedGymId.toString());
      await _secureStorage.write(key: "owner_name", value: ownerName);
      await _secureStorage.write(key: "user_role", value: userRole);

      isCheckingSession = false;
      notifyListeners();

      if (!isUnlinkedStaff) {
        await reloadCurrentGymData();
      }
      return true;
    } catch (e) {
      debugPrint("Login failure token intercept: $e");
      _token = null;
      _selectedGymId = null;
      return false;
    } finally {
      isLoading = false;
      isCheckingSession = false;
      notifyListeners();
    }
  }

  /// SIGNUP GATEWAY WITH INTEGRATED MULTI-ROLE DETECTIONS
  Future<bool> registerNewWorkspace({
    required bool isStaff,
    required String gymName,
    required String ownerName,
    required String phone,
    required String email,
    required String password,
  }) async {
    isLoading = true;
    notifyListeners();
    try {
      final data = await _authRepo.executeSignup(
        isStaff: isStaff,
        gymName: gymName,
        ownerName: ownerName,
        phone: phone,
        email: email,
        password: password,
      );

      _token = data['token'];
      userRole = data['role'] ?? 'OWNER';
      this.ownerName = data['owner_name'];

      final rawGymId = data['primary_gym_id'];
      if (rawGymId == null && userRole == 'STAFF') {
        isUnlinkedStaff = true;
        _selectedGymId = -1;
      } else {
        isUnlinkedStaff = false;
        _selectedGymId = int.parse(rawGymId.toString());
      }

      await _secureStorage.write(key: "auth_token", value: _token);
      await _secureStorage.write(key: "selected_gym_id", value: _selectedGymId.toString());
      await _secureStorage.write(key: "owner_name", value: this.ownerName);
      await _secureStorage.write(key: "user_role", value: userRole);

      isCheckingSession = false;
      notifyListeners();

      if (!isUnlinkedStaff) {
        await reloadCurrentGymData();
      }
      return true;
    } catch (e) {
      debugPrint("Workspace validation initialization crash: $e");
      return false;
    } finally {
      isLoading = false;
      isCheckingSession = false;
      notifyListeners();
    }
  }

  /// 3. Executes composite dashboard synchronization and switches data context smoothly across branches
  Future<void> changeBranch(int branchId) async {
    if (userRole == 'STAFF') return; // Enforce explicit staff blockades
    _selectedGymId = branchId;
    await _secureStorage.write(key: "selected_gym_id", value: branchId.toString());
    notifyListeners();
    await reloadCurrentGymData();
  }

  Future<void> reloadCurrentGymData() async {
    if (_selectedGymId == null || isUnlinkedStaff) return;
    isLoading = true;
    notifyListeners();

    try {
      final payload = await _dashboardRepo.fetchCompleteBranchSync(_selectedGymId!);

      ownerName = payload['owner_name'] ?? ownerName;
      userRole = payload['user_role'] ?? 'OWNER';
      staffPermissions = Map<String, dynamic>.from(payload['permissions'] ?? {});
      
      _secureStorage.write(key: "owner_email", value: payload['owner_email'] ?? "");
      _secureStorage.write(key: "owner_phone", value: payload['owner_phone'] ?? "");

      final List<dynamic> memberRows = payload['members'] ?? [];
      activeMembers = memberRows.map((m) => Member.fromJson(m)).toList();

      final List<dynamic> planRows = payload['plans'] ?? [];
      activePlans = planRows.map((p) => Plan.fromJson(p)).toList();

      activeStaff = List<Map<String, dynamic>>.from(payload['staff'] ?? []);
      rawExpenses = List<Map<String, dynamic>>.from(payload['expenses'] ?? []);
      rawPayments = List<Map<String, dynamic>>.from(payload['payments'] ?? []);
      rawAttendance = List<Map<String, dynamic>>.from(payload['attendance'] ?? []);
      
      final List<dynamic> gymRows = payload['gyms'] ?? [];
      clientGyms = gymRows.map((g) => Gym.fromJson(g)).toList();

      _lifetimePaymentsRevenue = double.tryParse(payload['total_payments_revenue'].toString()) ?? 0.0;
      _lifetimeExpensesOverhead = double.tryParse(payload['total_expenses_overhead'].toString()) ?? 0.0;

      saasPlanName = payload['saas_plan_name'] ?? 'Trial';
      saasExpiryDate = payload['saas_expiry_date'] ?? '';
      saasDaysRemaining = int.tryParse(payload['saas_days_remaining'].toString()) ?? 0;
      saasMaxMembers = int.tryParse(payload['saas_max_members'].toString()) ?? 50;
      saasMaxBranches = int.tryParse(payload['saas_max_branches'].toString()) ?? 1;
      saasMaxStaff = int.tryParse(payload['saas_max_staff'].toString()) ?? 3; 

    } catch (e) {
      debugPrint("Sync Error execution failure: $e");
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  /// 4. Adds a member and transfers files onto server database engines
  Future<bool> registerNewMember(Member member) async {
    if (!hasPermission('manage_members')) return false;
    try {
      await _dashboardRepo.uploadNewMember(selectedGymId, member);
      await reloadCurrentGymData();
      return true;
    } catch (e) {
      debugPrint("Failed to write structural client node entry: $e");
      return false;
    }
  }
  
  /// Transmits a check-in event with optimistic UI rendering acceleration
  Future<bool> markAttendance(int memberId) async {
    if (!hasPermission('mark_attendance')) return false;
    final String todayIsoStr = DateTime.now().toIso8601String();
    
    final temporaryRecord = {
      'id': -1,
      'gym_id': selectedGymId,
      'member_id': memberId,
      'attendance_date': todayIsoStr
    };
    
    rawAttendance.add(temporaryRecord);
    notifyListeners(); 

    try {
      final responsePayload = await _dashboardRepo.logMemberAttendance(selectedGymId, memberId);
      final realAttendanceId = responsePayload['attendance_id'];

      final indexToUpdate = rawAttendance.indexWhere((r) => r['id'] == -1 && r['member_id'] == memberId);
      if (indexToUpdate != -1) {
        rawAttendance[indexToUpdate] = {
          'id': realAttendanceId,
          'gym_id': selectedGymId,
          'member_id': memberId,
          'attendance_date': todayIsoStr
        };
      }
      
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint("Attendance state pipeline failed: $e");
      rawAttendance.removeWhere((record) => record['id'] == -1 && record['member_id'] == memberId);
      notifyListeners();
      return false;
    }
  }

  /// Checks local memory cache to verify if check-in is complete for today
  bool isMemberCheckedInToday(int memberId) {
    if (rawAttendance.isEmpty) return false;
    final String todayStr = DateTime.now().toIso8601String().substring(0, 10);

    return rawAttendance.any((record) {
      final String recordDateStr = record['attendance_date'] != null 
          ? record['attendance_date'].toString().substring(0, 10)
          : '';
          
      return int.tryParse(record['member_id'].toString()) == memberId && 
             recordDateStr == todayStr;
    });
  }

  /// 5. Clears active hardware encryption files on user Logout
  Future<void> clearActiveWorkspaceSession() async {
    await _secureStorage.deleteAll();
    _token = null;
    _selectedGymId = null;
    ownerName = null;
    clientGyms.clear();
    activeMembers.clear();
    activePlans.clear();
    activeStaff.clear();
    rawExpenses.clear();
    rawPayments.clear();
    rawAttendance.clear();
    
    saasPlanName = 'Trial';
    saasExpiryDate = '';
    saasDaysRemaining = 0;
    saasMaxMembers = 0;
    saasMaxBranches = 0;
    saasMaxStaff = 0; 
    _memberSortCriteria = null; // 🚀 FIXED: Cleans out persistent criteria memory layout on logout

    userRole = 'OWNER';
    isUnlinkedStaff = false;
    staffPermissions.clear();
    
    notifyListeners();
  }

  /// Provisions a new gym franchise node under the active owner profile session
  Future<bool> deployNewFranchiseBranch(String branchName) async {
    if (userRole != 'OWNER') return false;
    try {
      final response = await _dashboardRepo.uploadNewBranch(branchName);
      if (response['success'] == true) {
        final int newBranchId = int.parse(response['gym']['id'].toString());
        await changeBranch(newBranchId);
        return true;
      }
      return false;
    } catch (e) {
      debugPrint("Branch mapping state machine fault: $e");
      return false;
    }
  }

  /// Re-enabled the network runtime call hook to save plan catalogs cleanly onto Supabase tables
  Future<bool> addNewPlan(Plan plan) async {
    if (!hasPermission('manage_plans')) return false;
    try {
      final bool serverSaved = await _dashboardRepo.uploadNewPlan(selectedGymId, plan);
      if (serverSaved) {
        await reloadCurrentGymData(); 
        return true;
      }
      return false;
    } catch (e) {
      debugPrint("Failed to register new plan matrix configuration: $e");
      return false;
    }
  }

  /// Pre-registers staff with permission mapping vectors
  Future<bool> registerStaffMember({
    required String name,
    required String phone,
    required String role,
    required double salary,
    required Map<String, bool> permissions,
  }) async {
    try {
      final response = await _dashboardRepo.uploadNewStaff(selectedGymId, {
        'name': name,
        'phone': phone,
        'role': role,
        'salary': salary,
        'permissions': permissions,
      });
      if (response['success'] == true) {
        await reloadCurrentGymData();
        return true;
      }
      return false;
    } catch (e) {
      debugPrint("Staff allocation pipeline failed: $e");
      return false;
    }
  }

  /// Dynamic Plan Expiration Engine
  String getExpiryDateString(int memberId) {
    try {
      final member = activeMembers.firstWhere((m) => m.id == memberId);
      final catalogPlanMatch = activePlans.firstWhere(
        (p) => p.name.toLowerCase() == (member.membershipNumber ?? '').toLowerCase(),
        orElse: () => const Plan(id: -1, gymId: 0, name: "", price: 0, durationValue: 0, durationType: ""),
      );

      int daysToAdd = 30;
      if (catalogPlanMatch.id != -1) {
        final int value = catalogPlanMatch.durationValue;
        switch (catalogPlanMatch.durationType.toLowerCase()) {
          case 'days': daysToAdd = value; break;
          case 'weeks': daysToAdd = value * 7; break;
          case 'months': daysToAdd = value * 30; break;
          case 'years': daysToAdd = value * 365; break;
        }
      }

      return member.joinedDate.add(Duration(days: daysToAdd)).toIso8601String().substring(0, 10);
    } catch (_) {}
    return "N/A";
  }

  // ACCURATE CALCULATIONS ROOTED IN TRUE LIFETIME DATABASE METRICS
  double calculateTotalExpenses() {
    if (!hasPermission('view_finance')) return 0.0;
    double salaryTotal = activeStaff.fold(0.0, (sum, item) => sum + (double.tryParse(item['salary'].toString()) ?? 0.0));
    return _lifetimeExpensesOverhead + salaryTotal;
  }

  double calculateTotalPayments() => hasPermission('view_finance') ? _lifetimePaymentsRevenue : 0.0;
  double calculateTotalDues() => hasPermission('view_finance') ? activeMembers.fold(0.0, (sum, item) => sum + item.dueAmount) : 0.0;
}