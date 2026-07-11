import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:fluttertoast/fluttertoast.dart';
import '../../providers/employee_assignment_provider.dart';
import '../../models/employee_model.dart';
import '../../models/employee_assignment_model.dart';
import '../../core/constants/colors.dart';
import '../../core/constants/dimensions.dart';
import 'add_assignment_screen.dart';
import 'edit_assignment_screen.dart';
import 'edit_employee_screen.dart';

/// Detail view of one employee and their assignments
class EmployeeDetailScreen extends StatefulWidget {
  final EmployeeModel employee;

  const EmployeeDetailScreen({super.key, required this.employee});

  @override
  State<EmployeeDetailScreen> createState() => _EmployeeDetailScreenState();
}

class _EmployeeDetailScreenState extends State<EmployeeDetailScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<EmployeeAssignmentProvider>().fetchAssignments();
    });
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
    final employee = widget.employee;
    final dateFormat = DateFormat('MMM dd, yyyy • hh:mm a');

    return Scaffold(
      appBar: AppBar(
        title: Text(employee.name),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            tooltip: 'Edit employee',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => EditEmployeeScreen(employee: employee),
                ),
              );
            },
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) =>
                  AddAssignmentScreen(preselectedEmployee: employee),
            ),
          );
        },
        icon: const Icon(Icons.add),
        label: const Text('Assign Work'),
        backgroundColor: AppColors.primaryColor,
      ),
      body: Consumer<EmployeeAssignmentProvider>(
        builder: (context, provider, _) {
          final assignments =
              provider.assignmentsForEmployee(employee.id);

          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                margin: const EdgeInsets.all(AppDimensions.paddingL),
                padding: const EdgeInsets.all(AppDimensions.paddingL),
                decoration: BoxDecoration(
                  color: AppColors.surfaceColor,
                  borderRadius:
                      BorderRadius.circular(AppDimensions.radiusL),
                  border: Border.all(color: AppColors.borderColor),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        CircleAvatar(
                          radius: 28,
                          backgroundColor:
                              AppColors.primaryColor.withValues(alpha: 0.2),
                          child: Text(
                            employee.name.isNotEmpty
                                ? employee.name[0].toUpperCase()
                                : '?',
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: AppColors.primaryColor,
                            ),
                          ),
                        ),
                        const SizedBox(width: AppDimensions.paddingM),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                employee.name,
                                style: const TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                              Text(
                                employee.employeeId,
                                style: const TextStyle(
                                  color: AppColors.textMuted,
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
                            color: employee.isActive
                                ? AppColors.successColor
                                : AppColors.textMuted,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            employee.isActive ? 'Active' : 'Inactive',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppDimensions.paddingM),
                    _infoRow(Icons.email_outlined, employee.email),
                    if (employee.phone != null && employee.phone!.isNotEmpty)
                      _infoRow(Icons.phone_outlined, employee.phone!),
                    const SizedBox(height: AppDimensions.paddingS),
                    Text(
                      '${assignments.length} assignment${assignments.length == 1 ? '' : 's'}',
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppDimensions.paddingL,
                ),
                child: Text(
                  'Progress',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ),
              const SizedBox(height: AppDimensions.paddingM),
              Expanded(
                child: provider.isLoading && provider.allAssignments.isEmpty
                    ? const Center(child: CircularProgressIndicator())
                    : assignments.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.assignment_outlined,
                                  size: 64,
                                  color: AppColors.textMuted,
                                ),
                                const SizedBox(
                                  height: AppDimensions.paddingM,
                                ),
                                Text(
                                  'No assignments yet',
                                  style:
                                      Theme.of(context).textTheme.titleLarge,
                                ),
                                const SizedBox(
                                  height: AppDimensions.paddingS,
                                ),
                                const Text(
                                  'Assign customer work to track progress',
                                  style: TextStyle(
                                    color: AppColors.textMuted,
                                  ),
                                ),
                              ],
                            ),
                          )
                        : ListView.builder(
                            padding: const EdgeInsets.fromLTRB(
                              AppDimensions.paddingL,
                              0,
                              AppDimensions.paddingL,
                              80,
                            ),
                            itemCount: assignments.length,
                            itemBuilder: (context, index) {
                              final a = assignments[index];
                              final color = _statusColor(a.status);
                              return Card(
                                margin: const EdgeInsets.only(
                                  bottom: AppDimensions.paddingM,
                                ),
                                child: InkWell(
                                  onTap: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) =>
                                            EditAssignmentScreen(
                                          assignment: a,
                                        ),
                                      ),
                                    );
                                  },
                                  borderRadius: BorderRadius.circular(
                                    AppDimensions.radiusM,
                                  ),
                                  child: Padding(
                                    padding: const EdgeInsets.all(
                                      AppDimensions.paddingL,
                                    ),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            Expanded(
                                              child: Text(
                                                a.customerName,
                                                style: const TextStyle(
                                                  fontSize: 16,
                                                  fontWeight: FontWeight.w600,
                                                  color:
                                                      AppColors.textPrimary,
                                                ),
                                              ),
                                            ),
                                            Container(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                horizontal: 10,
                                                vertical: 4,
                                              ),
                                              decoration: BoxDecoration(
                                                color: color.withValues(
                                                  alpha: 0.15,
                                                ),
                                                borderRadius:
                                                    BorderRadius.circular(20),
                                                border: Border.all(
                                                  color: color.withValues(
                                                    alpha: 0.5,
                                                  ),
                                                ),
                                              ),
                                              child: Text(
                                                AssignmentStatus
                                                    .getDisplayName(a.status),
                                                style: TextStyle(
                                                  color: color,
                                                  fontWeight: FontWeight.w600,
                                                  fontSize: 11,
                                                ),
                                              ),
                                            ),
                                            IconButton(
                                              icon: const Icon(
                                                Icons.delete_outline,
                                                color: AppColors.errorColor,
                                              ),
                                              onPressed: () =>
                                                  _deleteAssignment(a),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          a.productDisplayNames.isEmpty
                                              ? 'No products'
                                              : a.productDisplayNames.join(', '),
                                          style: const TextStyle(
                                            color: AppColors.textSecondary,
                                          ),
                                        ),
                                        Text(
                                          a.customerPhone,
                                          style: const TextStyle(
                                            color: AppColors.textMuted,
                                            fontSize: 13,
                                          ),
                                        ),
                                        if (a.referralSource != null &&
                                            a.referralSource!.isNotEmpty) ...[
                                          const SizedBox(height: 4),
                                          Text(
                                            'Via ${a.referralSource == ReferralSource.other && (a.referralOther?.isNotEmpty ?? false) ? a.referralOther! : ReferralSource.getDisplayName(a.referralSource!)}',
                                            style: const TextStyle(
                                              color: AppColors.textMuted,
                                              fontSize: 12,
                                            ),
                                          ),
                                        ],
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
                                        const SizedBox(height: 8),
                                        Text(
                                          'Updated ${dateFormat.format(a.updatedAt)}',
                                          style: const TextStyle(
                                            color: AppColors.textMuted,
                                            fontSize: 11,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _infoRow(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          Icon(icon, size: 16, color: AppColors.textMuted),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(color: AppColors.textSecondary),
            ),
          ),
        ],
      ),
    );
  }
}
