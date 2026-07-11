import 'package:flutter/material.dart';
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

/// Screen for creating a new employee assignment
class AddAssignmentScreen extends StatefulWidget {
  final EmployeeModel? preselectedEmployee;

  const AddAssignmentScreen({super.key, this.preselectedEmployee});

  @override
  State<AddAssignmentScreen> createState() => _AddAssignmentScreenState();
}

class _AddAssignmentScreenState extends State<AddAssignmentScreen> {
  final _formKey = GlobalKey<FormState>();
  final _customerNameController = TextEditingController();
  final _customerPhoneController = TextEditingController();
  final _customerEmailController = TextEditingController();
  final _remarksController = TextEditingController();

  EmployeeModel? _selectedEmployee;
  ProductModel? _selectedProduct;
  String _status = AssignmentStatus.pending;

  @override
  void initState() {
    super.initState();
    _selectedEmployee = widget.preselectedEmployee;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<EmployeeProvider>().fetchEmployees();
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
          selectedProductId: _selectedProduct?.id,
        ),
      ),
    );
    if (product != null) {
      setState(() => _selectedProduct = product);
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    if (_selectedEmployee == null) {
      Fluttertoast.showToast(
        msg: 'Please select an employee',
        backgroundColor: AppColors.errorColor,
      );
      return;
    }
    if (_selectedProduct == null) {
      Fluttertoast.showToast(
        msg: 'Please select a product',
        backgroundColor: AppColors.errorColor,
      );
      return;
    }

    final provider = context.read<EmployeeAssignmentProvider>();
    final success = await provider.addAssignment(
      employeeId: _selectedEmployee!.id,
      employeeName: _selectedEmployee!.name,
      customerName: _customerNameController.text,
      customerPhone: _customerPhoneController.text,
      customerEmail: _customerEmailController.text,
      productId: _selectedProduct!.id,
      productName: _selectedProduct!.name,
      status: _status,
      remarks: _remarksController.text,
      createdBy: 'admin',
    );

    if (success) {
      Fluttertoast.showToast(
        msg: 'Assignment created successfully!',
        backgroundColor: AppColors.successColor,
        textColor: Colors.white,
      );
      if (mounted) Navigator.pop(context);
    } else {
      Fluttertoast.showToast(
        msg: provider.error ?? 'Failed to create assignment',
        backgroundColor: AppColors.errorColor,
        textColor: Colors.white,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final employeeProvider = context.watch<EmployeeProvider>();
    final employees = <EmployeeModel>[
      ...employeeProvider.activeEmployees,
    ];
    if (_selectedEmployee != null &&
        !employees.any((e) => e.id == _selectedEmployee!.id)) {
      employees.add(_selectedEmployee!);
    }
    final isLoading = context.watch<EmployeeAssignmentProvider>().isLoading;
    final selectedId =
        employees.any((e) => e.id == _selectedEmployee?.id)
            ? _selectedEmployee?.id
            : null;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Assign Work'),
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
                    items: employees
                        .map(
                          (e) => DropdownMenuItem(
                            value: e.id,
                            child: Text('${e.name} (${e.employeeId})'),
                          ),
                        )
                        .toList(),
                    onChanged: (id) {
                      if (id == null) return;
                      setState(() {
                        _selectedEmployee = employees.firstWhere(
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
                        _selectedProduct?.name ?? 'Tap to select product',
                        style: TextStyle(
                          color: _selectedProduct != null
                              ? AppColors.textPrimary
                              : AppColors.textMuted,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: AppDimensions.paddingXL),
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
                      labelText: 'Remarks (Optional)',
                      hintText: 'Initial notes about this assignment',
                      alignLabelWithHint: true,
                    ),
                    maxLines: 4,
                  ),
                  const SizedBox(height: AppDimensions.paddingXL),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: isLoading ? null : _save,
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
                                'Create Assignment',
                                style: TextStyle(fontSize: 16),
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
