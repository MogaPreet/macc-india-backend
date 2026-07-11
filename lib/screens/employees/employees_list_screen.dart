import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:fluttertoast/fluttertoast.dart';
import '../../providers/employee_provider.dart';
import '../../providers/employee_assignment_provider.dart';
import '../../models/employee_model.dart';
import '../../models/employee_assignment_model.dart';
import '../../core/constants/colors.dart';
import '../../core/constants/dimensions.dart';
import 'add_employee_screen.dart';
import 'edit_employee_screen.dart';
import 'employee_detail_screen.dart';
import 'add_assignment_screen.dart';
import 'edit_assignment_screen.dart';

/// Employees module with tabs: Employees | Progress
class EmployeesListScreen extends StatefulWidget {
  const EmployeesListScreen({super.key});

  @override
  State<EmployeesListScreen> createState() => _EmployeesListScreenState();
}

class _EmployeesListScreenState extends State<EmployeesListScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _employeeSearchController = TextEditingController();
  final _progressSearchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<EmployeeProvider>().fetchEmployees();
      context.read<EmployeeAssignmentProvider>().fetchAssignments();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _employeeSearchController.dispose();
    _progressSearchController.dispose();
    super.dispose();
  }

  Color _statusColor(String status) {
    switch (status) {
      case AssignmentStatus.pending:
        return Colors.orange;
      case AssignmentStatus.inProgress:
        return AppColors.infoColor;
      case AssignmentStatus.contacted:
        return Colors.blue;
      case AssignmentStatus.completed:
        return AppColors.successColor;
      case AssignmentStatus.cancelled:
        return Colors.grey;
      default:
        return AppColors.textMuted;
    }
  }

  Future<void> _deleteEmployee(EmployeeModel employee) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Employee'),
        content: Text(
          'Are you sure you want to delete "${employee.name}"? Their assignments will remain.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.errorColor,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      final provider = context.read<EmployeeProvider>();
      final success = await provider.deleteEmployee(employee.id);
      Fluttertoast.showToast(
        msg: success
            ? 'Employee deleted'
            : (provider.error ?? 'Failed to delete'),
        backgroundColor:
            success ? AppColors.successColor : AppColors.errorColor,
      );
    }
  }

  Future<void> _toggleActive(EmployeeModel employee) async {
    final provider = context.read<EmployeeProvider>();
    final success = await provider.toggleEmployeeActive(
      employee.id,
      !employee.isActive,
    );
    if (success) {
      Fluttertoast.showToast(
        msg: employee.isActive ? 'Employee deactivated' : 'Employee activated',
        backgroundColor: AppColors.successColor,
      );
    }
  }

  Future<void> _deleteAssignment(EmployeeAssignmentModel assignment) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Assignment'),
        content: Text(
          'Delete assignment for "${assignment.customerName}"?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.errorColor,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      final provider = context.read<EmployeeAssignmentProvider>();
      final success = await provider.deleteAssignment(assignment.id);
      Fluttertoast.showToast(
        msg: success
            ? 'Assignment deleted'
            : (provider.error ?? 'Failed to delete'),
        backgroundColor:
            success ? AppColors.successColor : AppColors.errorColor,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Employee Management'),
        automaticallyImplyLeading: false,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppColors.primaryColor,
          labelColor: AppColors.primaryColor,
          unselectedLabelColor: AppColors.textMuted,
          tabs: const [
            Tab(text: 'Employees', icon: Icon(Icons.badge_outlined, size: 20)),
            Tab(
              text: 'Progress',
              icon: Icon(Icons.assignment_outlined, size: 20),
            ),
          ],
        ),
      ),
      floatingActionButton: AnimatedBuilder(
        animation: _tabController,
        builder: (context, _) {
          final isEmployees = _tabController.index == 0;
          return FloatingActionButton.extended(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => isEmployees
                      ? const AddEmployeeScreen()
                      : const AddAssignmentScreen(),
                ),
              );
            },
            icon: const Icon(Icons.add),
            label: Text(isEmployees ? 'Add Employee' : 'Assign Work'),
            backgroundColor: AppColors.primaryColor,
          );
        },
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildEmployeesTab(),
          _buildProgressTab(),
        ],
      ),
    );
  }

  Widget _buildEmployeesTab() {
    return Consumer<EmployeeProvider>(
      builder: (context, provider, _) {
        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(AppDimensions.paddingL),
              child: Column(
                children: [
                  TextField(
                    controller: _employeeSearchController,
                    onChanged: provider.setSearchQuery,
                    decoration: InputDecoration(
                      hintText: 'Search by name, email, or ID…',
                      prefixIcon: const Icon(Icons.search),
                      filled: true,
                      fillColor: AppColors.surfaceColor,
                      border: OutlineInputBorder(
                        borderRadius:
                            BorderRadius.circular(AppDimensions.radiusL),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                  const SizedBox(height: AppDimensions.paddingM),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        _activeFilterChip(provider, 'all', 'All'),
                        const SizedBox(width: 8),
                        _activeFilterChip(provider, 'active', 'Active'),
                        const SizedBox(width: 8),
                        _activeFilterChip(provider, 'inactive', 'Inactive'),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Expanded(child: _buildEmployeesContent(provider)),
          ],
        );
      },
    );
  }

  Widget _activeFilterChip(
    EmployeeProvider provider,
    String value,
    String label,
  ) {
    final selected = provider.activeFilter == value;
    return FilterChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) => provider.setActiveFilter(value),
      selectedColor: AppColors.primaryColor.withValues(alpha: 0.2),
      checkmarkColor: AppColors.primaryColor,
      labelStyle: TextStyle(
        color: selected ? AppColors.primaryColor : AppColors.textSecondary,
        fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
      ),
      side: BorderSide(
        color: selected ? AppColors.primaryColor : AppColors.borderColor,
      ),
    );
  }

  Widget _buildEmployeesContent(EmployeeProvider provider) {
    if (provider.isLoading && provider.allEmployees.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (provider.error != null && provider.allEmployees.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline,
                size: 64, color: AppColors.errorColor),
            const SizedBox(height: AppDimensions.paddingM),
            Text(provider.error!),
            const SizedBox(height: AppDimensions.paddingL),
            ElevatedButton.icon(
              onPressed: provider.fetchEmployees,
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (provider.allEmployees.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.badge_outlined, size: 64, color: AppColors.textMuted),
            const SizedBox(height: AppDimensions.paddingM),
            Text(
              'No employees yet',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: AppDimensions.paddingS),
            const Text(
              'Add your first employee to get started',
              style: TextStyle(color: AppColors.textMuted),
            ),
          ],
        ),
      );
    }

    if (provider.employees.isEmpty) {
      return const Center(
        child: Text(
          'No matching employees',
          style: TextStyle(color: AppColors.textMuted),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: provider.fetchEmployees,
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(
          AppDimensions.paddingL,
          0,
          AppDimensions.paddingL,
          80,
        ),
        itemCount: provider.employees.length,
        itemBuilder: (context, index) {
          return _buildEmployeeCard(provider.employees[index]);
        },
      ),
    );
  }

  Widget _buildEmployeeCard(EmployeeModel employee) {
    final assignmentCount = context
        .watch<EmployeeAssignmentProvider>()
        .assignmentsForEmployee(employee.id)
        .length;

    return Card(
      margin: const EdgeInsets.only(bottom: AppDimensions.paddingM),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => EmployeeDetailScreen(employee: employee),
            ),
          );
        },
        borderRadius: BorderRadius.circular(AppDimensions.radiusM),
        child: Padding(
          padding: const EdgeInsets.all(AppDimensions.paddingL),
          child: Row(
            children: [
              CircleAvatar(
                radius: 24,
                backgroundColor:
                    AppColors.primaryColor.withValues(alpha: 0.2),
                child: Text(
                  employee.name.isNotEmpty
                      ? employee.name[0].toUpperCase()
                      : '?',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: AppColors.primaryColor,
                    fontSize: 18,
                  ),
                ),
              ),
              const SizedBox(width: AppDimensions.paddingM),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            employee.name,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ),
                        GestureDetector(
                          onTap: () => _toggleActive(employee),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: employee.isActive
                                  ? AppColors.successColor
                                  : AppColors.textMuted,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              employee.isActive ? 'Active' : 'Inactive',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${employee.employeeId} · ${employee.email}',
                      style: const TextStyle(
                        color: AppColors.textMuted,
                        fontSize: 13,
                      ),
                    ),
                    Text(
                      '$assignmentCount assignment${assignmentCount == 1 ? '' : 's'}',
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.edit_outlined),
                color: AppColors.textSecondary,
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => EditEmployeeScreen(employee: employee),
                    ),
                  );
                },
              ),
              IconButton(
                icon: const Icon(Icons.delete_outline),
                color: AppColors.errorColor,
                onPressed: () => _deleteEmployee(employee),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProgressTab() {
    return Consumer2<EmployeeAssignmentProvider, EmployeeProvider>(
      builder: (context, assignmentProvider, employeeProvider, _) {
        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(AppDimensions.paddingL),
              child: Column(
                children: [
                  TextField(
                    controller: _progressSearchController,
                    onChanged: assignmentProvider.setSearchQuery,
                    decoration: InputDecoration(
                      hintText: 'Search customer, product, employee…',
                      prefixIcon: const Icon(Icons.search),
                      filled: true,
                      fillColor: AppColors.surfaceColor,
                      border: OutlineInputBorder(
                        borderRadius:
                            BorderRadius.circular(AppDimensions.radiusL),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                  const SizedBox(height: AppDimensions.paddingM),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        _statusChip(assignmentProvider, 'all', 'All',
                            AppColors.primaryColor),
                        const SizedBox(width: 8),
                        _statusChip(
                          assignmentProvider,
                          AssignmentStatus.pending,
                          'Pending',
                          Colors.orange,
                        ),
                        const SizedBox(width: 8),
                        _statusChip(
                          assignmentProvider,
                          AssignmentStatus.inProgress,
                          'In Progress',
                          AppColors.infoColor,
                        ),
                        const SizedBox(width: 8),
                        _statusChip(
                          assignmentProvider,
                          AssignmentStatus.contacted,
                          'Contacted',
                          Colors.blue,
                        ),
                        const SizedBox(width: 8),
                        _statusChip(
                          assignmentProvider,
                          AssignmentStatus.completed,
                          'Completed',
                          AppColors.successColor,
                        ),
                        const SizedBox(width: 8),
                        _statusChip(
                          assignmentProvider,
                          AssignmentStatus.cancelled,
                          'Cancelled',
                          Colors.grey,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppDimensions.paddingM),
                  DropdownButtonFormField<String>(
                    initialValue: assignmentProvider.employeeFilter,
                    decoration: const InputDecoration(
                      labelText: 'Filter by employee',
                      isDense: true,
                    ),
                    items: [
                      const DropdownMenuItem(
                        value: 'all',
                        child: Text('All employees'),
                      ),
                      ...employeeProvider.allEmployees.map(
                        (e) => DropdownMenuItem(
                          value: e.id,
                          child: Text(e.name),
                        ),
                      ),
                    ],
                    onChanged: (v) {
                      if (v != null) {
                        assignmentProvider.setEmployeeFilter(v);
                      }
                    },
                  ),
                ],
              ),
            ),
            Expanded(child: _buildProgressContent(assignmentProvider)),
          ],
        );
      },
    );
  }

  Widget _statusChip(
    EmployeeAssignmentProvider provider,
    String status,
    String label,
    Color color,
  ) {
    final selected = provider.statusFilter == status;
    final count = provider.getCountByStatus(status);
    return FilterChip(
      label: Text('$label ($count)'),
      selected: selected,
      onSelected: (_) => provider.setStatusFilter(status),
      selectedColor: color.withValues(alpha: 0.2),
      checkmarkColor: color,
      labelStyle: TextStyle(
        color: selected ? color : AppColors.textSecondary,
        fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
      ),
      side: BorderSide(color: selected ? color : AppColors.borderColor),
    );
  }

  Widget _buildProgressContent(EmployeeAssignmentProvider provider) {
    final dateFormat = DateFormat('MMM dd, yyyy • hh:mm a');

    if (provider.isLoading && provider.allAssignments.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (provider.allAssignments.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.assignment_outlined,
                size: 64, color: AppColors.textMuted),
            const SizedBox(height: AppDimensions.paddingM),
            Text(
              'No assignments yet',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: AppDimensions.paddingS),
            const Text(
              'Assign work to employees to track progress here',
              style: TextStyle(color: AppColors.textMuted),
            ),
          ],
        ),
      );
    }

    if (provider.assignments.isEmpty) {
      return const Center(
        child: Text(
          'No matching assignments',
          style: TextStyle(color: AppColors.textMuted),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: provider.fetchAssignments,
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(
          AppDimensions.paddingL,
          0,
          AppDimensions.paddingL,
          80,
        ),
        itemCount: provider.assignments.length,
        itemBuilder: (context, index) {
          final a = provider.assignments[index];
          final color = _statusColor(a.status);
          return Card(
            margin: const EdgeInsets.only(bottom: AppDimensions.paddingM),
            child: InkWell(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => EditAssignmentScreen(assignment: a),
                  ),
                );
              },
              borderRadius: BorderRadius.circular(AppDimensions.radiusM),
              child: Padding(
                padding: const EdgeInsets.all(AppDimensions.paddingL),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                a.customerName,
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                              Text(
                                a.customerPhone,
                                style: const TextStyle(
                                  color: AppColors.textMuted,
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: color.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: color.withValues(alpha: 0.5),
                            ),
                          ),
                          child: Text(
                            AssignmentStatus.getDisplayName(a.status),
                            style: TextStyle(
                              color: color,
                              fontWeight: FontWeight.w600,
                              fontSize: 11,
                            ),
                          ),
                        ),
                        PopupMenuButton<String>(
                          onSelected: (value) async {
                            if (value == 'delete') {
                              await _deleteAssignment(a);
                            } else {
                              await provider.updateStatus(a.id, value);
                            }
                          },
                          itemBuilder: (context) => [
                            ...AssignmentStatus.values.map(
                              (s) => PopupMenuItem(
                                value: s,
                                child: Text(
                                  AssignmentStatus.getDisplayName(s),
                                ),
                              ),
                            ),
                            const PopupMenuDivider(),
                            const PopupMenuItem(
                              value: 'delete',
                              child: Text(
                                'Delete',
                                style: TextStyle(color: AppColors.errorColor),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const Divider(height: 20),
                    Row(
                      children: [
                        const Icon(Icons.inventory_2_outlined,
                            size: 14, color: AppColors.textMuted),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            a.productDisplayNames.isEmpty
                                ? 'No products'
                                : a.productDisplayNames.join(', '),
                            style: const TextStyle(
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ),
                      ],
                    ),
                    if (a.referralSource != null &&
                        a.referralSource!.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          const Icon(Icons.campaign_outlined,
                              size: 14, color: AppColors.textMuted),
                          const SizedBox(width: 6),
                          Text(
                            a.referralSource == ReferralSource.other &&
                                    (a.referralOther?.isNotEmpty ?? false)
                                ? a.referralOther!
                                : ReferralSource.getDisplayName(
                                    a.referralSource!,
                                  ),
                            style: const TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ],
                    if (!a.discovery.isEmpty) ...[
                      const SizedBox(height: 6),
                      Text(
                        [
                          if (a.discovery.useCase.isNotEmpty)
                            'Use: ${a.discovery.useCase}',
                          if (a.discovery.needsNotes.isNotEmpty)
                            'Needs: ${a.discovery.needsNotes}',
                        ].join(' · '),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: AppColors.textMuted,
                          fontSize: 12,
                        ),
                      ),
                    ],
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        const Icon(Icons.person_outline,
                            size: 14, color: AppColors.textMuted),
                        const SizedBox(width: 6),
                        Text(
                          a.employeeName,
                          style: const TextStyle(
                            color: AppColors.textSecondary,
                          ),
                        ),
                        if (a.createdBy == 'employee') ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.infoColor.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Text(
                              'Visit',
                              style: TextStyle(
                                color: AppColors.infoColor,
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                        const Spacer(),
                        Text(
                          dateFormat.format(a.updatedAt),
                          style: const TextStyle(
                            color: AppColors.textMuted,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                    if (a.remarks.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Text(
                        a.remarks,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: AppColors.textMuted,
                          fontSize: 13,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
