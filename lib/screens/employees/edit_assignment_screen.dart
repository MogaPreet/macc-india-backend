import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:fluttertoast/fluttertoast.dart';
import '../../providers/employee_provider.dart';
import '../../providers/employee_assignment_provider.dart';
import '../../models/employee_model.dart';
import '../../models/employee_assignment_model.dart';
import '../../models/product_model.dart';
import '../../core/constants/colors.dart';
import '../../core/constants/dimensions.dart';
import '../../core/utils/validators.dart';
import 'assignment_product_picker_screen.dart';

/// Screen for editing an employee assignment
class EditAssignmentScreen extends StatefulWidget {
  final EmployeeAssignmentModel assignment;

  const EditAssignmentScreen({super.key, required this.assignment});

  @override
  State<EditAssignmentScreen> createState() => _EditAssignmentScreenState();
}

class _EditAssignmentScreenState extends State<EditAssignmentScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _customerNameController;
  late TextEditingController _customerPhoneController;
  late TextEditingController _customerEmailController;
  late TextEditingController _remarksController;

  EmployeeModel? _selectedEmployee;
  String? _productId;
  String? _productName;
  late String _status;

  @override
  void initState() {
    super.initState();
    final a = widget.assignment;
    _customerNameController = TextEditingController(text: a.customerName);
    _customerPhoneController = TextEditingController(text: a.customerPhone);
    _customerEmailController =
        TextEditingController(text: a.customerEmail ?? '');
    _remarksController = TextEditingController(text: a.remarks);
    _productId = a.productId;
    _productName = a.productName;
    _status = a.status;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = context.read<EmployeeProvider>();
      provider.fetchEmployees().then((_) {
        if (!mounted) return;
        setState(() {
          _selectedEmployee = provider.getById(a.employeeId);
          _selectedEmployee ??= EmployeeModel(
            id: a.employeeId,
            name: a.employeeName,
            email: '',
            employeeId: '',
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          );
        });
      });
    });
  }

  @override
  void dispose() {
    _customerNameController.dispose();
    _customerPhoneController.dispose();
    _customerEmailController.dispose();
    _remarksController.dispose();
    super.dispose();
  }

  Future<void> _pickProduct() async {
    final product = await Navigator.push<ProductModel>(
      context,
      MaterialPageRoute(
        builder: (_) => AssignmentProductPickerScreen(
          selectedProductId: _productId,
        ),
      ),
    );
    if (product != null) {
      setState(() {
        _productId = product.id;
        _productName = product.name;
      });
    }
  }

  Future<void> _update() async {
    if (!_formKey.currentState!.validate()) return;

    if (_selectedEmployee == null) {
      Fluttertoast.showToast(
        msg: 'Please select an employee',
        backgroundColor: AppColors.errorColor,
      );
      return;
    }
    if (_productId == null || _productName == null) {
      Fluttertoast.showToast(
        msg: 'Please select a product',
        backgroundColor: AppColors.errorColor,
      );
      return;
    }

    final provider = context.read<EmployeeAssignmentProvider>();
    final success = await provider.updateAssignment(
      id: widget.assignment.id,
      employeeId: _selectedEmployee!.id,
      employeeName: _selectedEmployee!.name,
      customerName: _customerNameController.text,
      customerPhone: _customerPhoneController.text,
      customerEmail: _customerEmailController.text,
      productId: _productId!,
      productName: _productName!,
      status: _status,
      remarks: _remarksController.text,
      updatedBy: 'admin',
    );

    if (success) {
      Fluttertoast.showToast(
        msg: 'Assignment updated successfully!',
        backgroundColor: AppColors.successColor,
        textColor: Colors.white,
      );
      if (mounted) Navigator.pop(context);
    } else {
      Fluttertoast.showToast(
        msg: provider.error ?? 'Failed to update assignment',
        backgroundColor: AppColors.errorColor,
        textColor: Colors.white,
      );
    }
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

  @override
  Widget build(BuildContext context) {
    final employeeProvider = context.watch<EmployeeProvider>();
    final employees = employeeProvider.allEmployees;
    final dropdownEmployees = <EmployeeModel>[
      ...employeeProvider.activeEmployees,
    ];
    if (_selectedEmployee != null &&
        !dropdownEmployees.any((e) => e.id == _selectedEmployee!.id)) {
      dropdownEmployees.add(_selectedEmployee!);
    }
    if (dropdownEmployees.isEmpty) {
      dropdownEmployees.addAll(employees);
    }
    final isLoading = context.watch<EmployeeAssignmentProvider>().isLoading;
    final dateFormat = DateFormat('MMM dd, yyyy • hh:mm a');
    final selectedId = dropdownEmployees.any((e) => e.id == _selectedEmployee?.id)
        ? _selectedEmployee?.id
        : null;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Assignment'),
        actions: [
          TextButton.icon(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.close),
            label: const Text('Cancel'),
          ),
          const SizedBox(width: AppDimensions.paddingM),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppDimensions.paddingL),
        child: Center(
          child: Container(
            constraints: const BoxConstraints(
              maxWidth: AppDimensions.maxContentWidth,
            ),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _sectionTitle('Employee'),
                  const SizedBox(height: AppDimensions.paddingM),
                  DropdownButtonFormField<String>(
                    initialValue: selectedId,
                    decoration: const InputDecoration(
                      labelText: 'Assign to *',
                    ),
                    items: dropdownEmployees
                        .map(
                          (e) => DropdownMenuItem(
                            value: e.id,
                            child: Text(
                              e.employeeId.isNotEmpty
                                  ? '${e.name} (${e.employeeId})'
                                  : e.name,
                            ),
                          ),
                        )
                        .toList(),
                    onChanged: (id) {
                      if (id == null) return;
                      setState(() {
                        _selectedEmployee = dropdownEmployees.firstWhere(
                          (e) => e.id == id,
                        );
                      });
                    },
                    validator: (v) =>
                        v == null ? 'Please select an employee' : null,
                  ),
                  const SizedBox(height: AppDimensions.paddingXL),
                  _sectionTitle('Customer'),
                  const SizedBox(height: AppDimensions.paddingM),
                  TextFormField(
                    controller: _customerNameController,
                    decoration: const InputDecoration(
                      labelText: 'Customer Name *',
                    ),
                    validator: (v) =>
                        Validators.required(v, fieldName: 'Customer name'),
                  ),
                  const SizedBox(height: AppDimensions.paddingM),
                  TextFormField(
                    controller: _customerPhoneController,
                    decoration: const InputDecoration(
                      labelText: 'Customer Phone *',
                    ),
                    keyboardType: TextInputType.phone,
                    validator: Validators.phone,
                  ),
                  const SizedBox(height: AppDimensions.paddingM),
                  TextFormField(
                    controller: _customerEmailController,
                    decoration: const InputDecoration(
                      labelText: 'Customer Email (Optional)',
                    ),
                    keyboardType: TextInputType.emailAddress,
                    validator: (v) {
                      if (v == null || v.trim().isEmpty) return null;
                      return Validators.email(v);
                    },
                  ),
                  const SizedBox(height: AppDimensions.paddingXL),
                  _sectionTitle('Product'),
                  const SizedBox(height: AppDimensions.paddingM),
                  InkWell(
                    onTap: _pickProduct,
                    borderRadius:
                        BorderRadius.circular(AppDimensions.radiusM),
                    child: InputDecorator(
                      decoration: const InputDecoration(
                        labelText: 'Product *',
                        suffixIcon: Icon(Icons.search),
                      ),
                      child: Text(
                        _productName ?? 'Tap to select product',
                        style: TextStyle(
                          color: _productName != null
                              ? AppColors.textPrimary
                              : AppColors.textMuted,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: AppDimensions.paddingXL),
                  if (widget.assignment.products.length > 1 ||
                      widget.assignment.referralSource != null ||
                      !widget.assignment.discovery.isEmpty) ...[
                    _sectionTitle('Visit Details'),
                    const SizedBox(height: AppDimensions.paddingM),
                    if (widget.assignment.products.isNotEmpty)
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: widget.assignment.products
                            .map(
                              (p) => Chip(
                                label: Text(p.productName),
                                backgroundColor: AppColors.cardColor,
                              ),
                            )
                            .toList(),
                      ),
                    if (widget.assignment.referralSource != null) ...[
                      const SizedBox(height: AppDimensions.paddingM),
                      Text(
                        'Heard via: ${widget.assignment.referralSource == ReferralSource.other && (widget.assignment.referralOther?.isNotEmpty ?? false) ? widget.assignment.referralOther! : ReferralSource.getDisplayName(widget.assignment.referralSource!)}',
                        style: const TextStyle(color: AppColors.textSecondary),
                      ),
                    ],
                    if (!widget.assignment.discovery.isEmpty) ...[
                      const SizedBox(height: AppDimensions.paddingM),
                      if (widget.assignment.discovery.useCase.isNotEmpty)
                        Text(
                          'Use case: ${widget.assignment.discovery.useCase}',
                          style:
                              const TextStyle(color: AppColors.textSecondary),
                        ),
                      if (widget.assignment.discovery.budgetRange.isNotEmpty)
                        Text(
                          'Budget: ${widget.assignment.discovery.budgetRange}',
                          style:
                              const TextStyle(color: AppColors.textSecondary),
                        ),
                      if (widget
                          .assignment.discovery.understandingNotes.isNotEmpty)
                        Text(
                          'Understands: ${widget.assignment.discovery.understandingNotes}',
                          style:
                              const TextStyle(color: AppColors.textSecondary),
                        ),
                      if (widget.assignment.discovery.needsNotes.isNotEmpty)
                        Text(
                          'Needs: ${widget.assignment.discovery.needsNotes}',
                          style:
                              const TextStyle(color: AppColors.textSecondary),
                        ),
                    ],
                    const SizedBox(height: AppDimensions.paddingXL),
                  ],
                  _sectionTitle('Status & Remarks'),
                  const SizedBox(height: AppDimensions.paddingM),
                  DropdownButtonFormField<String>(
                    initialValue: _status,
                    decoration: const InputDecoration(labelText: 'Status'),
                    items: AssignmentStatus.values
                        .map(
                          (s) => DropdownMenuItem(
                            value: s,
                            child: Text(AssignmentStatus.getDisplayName(s)),
                          ),
                        )
                        .toList(),
                    onChanged: (v) {
                      if (v != null) setState(() => _status = v);
                    },
                  ),
                  const SizedBox(height: AppDimensions.paddingM),
                  TextFormField(
                    controller: _remarksController,
                    decoration: const InputDecoration(
                      labelText: 'Remarks',
                      hintText: 'Update notes — changes are saved to history',
                      alignLabelWithHint: true,
                    ),
                    maxLines: 4,
                  ),
                  if (widget.assignment.remarkHistory.isNotEmpty) ...[
                    const SizedBox(height: AppDimensions.paddingXL),
                    _sectionTitle('Remark History'),
                    const SizedBox(height: AppDimensions.paddingM),
                    ...widget.assignment.remarkHistory.map((entry) {
                      return Card(
                        margin: const EdgeInsets.only(
                          bottom: AppDimensions.paddingS,
                        ),
                        child: ListTile(
                          leading: const Icon(
                            Icons.history,
                            color: AppColors.textMuted,
                          ),
                          title: Text(
                            entry.text,
                            style: const TextStyle(
                              color: AppColors.textPrimary,
                            ),
                          ),
                          subtitle: Text(
                            '${entry.updatedBy} · ${dateFormat.format(entry.updatedAt)}',
                            style: const TextStyle(
                              color: AppColors.textMuted,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      );
                    }),
                  ],
                  const SizedBox(height: AppDimensions.paddingXL),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: isLoading ? null : _update,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          vertical: AppDimensions.paddingM,
                        ),
                        child: isLoading
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Text(
                                'Update Assignment',
                                style: TextStyle(fontSize: 16),
                              ),
                      ),
                    ),
                  ),
                  const SizedBox(height: AppDimensions.paddingM),
                  // Current status badge preview
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: _statusColor(_status).withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: _statusColor(_status).withValues(alpha: 0.5),
                        ),
                      ),
                      child: Text(
                        AssignmentStatus.getDisplayName(_status),
                        style: TextStyle(
                          color: _statusColor(_status),
                          fontWeight: FontWeight.w600,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _sectionTitle(String title) {
    return Text(
      title,
      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.bold,
          ),
    );
  }
}
