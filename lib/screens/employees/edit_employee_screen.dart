import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fluttertoast/fluttertoast.dart';
import '../../providers/employee_provider.dart';
import '../../providers/employee_assignment_provider.dart';
import '../../models/employee_model.dart';
import '../../core/constants/colors.dart';
import '../../core/constants/dimensions.dart';
import '../../core/utils/validators.dart';

/// Screen for editing an existing employee
class EditEmployeeScreen extends StatefulWidget {
  final EmployeeModel employee;

  const EditEmployeeScreen({super.key, required this.employee});

  @override
  State<EditEmployeeScreen> createState() => _EditEmployeeScreenState();
}

class _EditEmployeeScreenState extends State<EditEmployeeScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _emailController;
  late TextEditingController _employeeIdController;
  late TextEditingController _phoneController;
  late bool _isActive;
  bool _sendingReset = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.employee.name);
    _emailController = TextEditingController(text: widget.employee.email);
    _employeeIdController =
        TextEditingController(text: widget.employee.employeeId);
    _phoneController =
        TextEditingController(text: widget.employee.phone ?? '');
    _isActive = widget.employee.isActive;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _employeeIdController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _update() async {
    if (!_formKey.currentState!.validate()) return;

    final provider = context.read<EmployeeProvider>();
    final name = _nameController.text.trim();
    final success = await provider.updateEmployee(
      id: widget.employee.id,
      name: name,
      email: _emailController.text,
      employeeId: _employeeIdController.text,
      phone: _phoneController.text,
      isActive: _isActive,
    );

    if (success) {
      if (name != widget.employee.name && mounted) {
        await context
            .read<EmployeeAssignmentProvider>()
            .syncEmployeeName(widget.employee.id, name);
      }
      Fluttertoast.showToast(
        msg: 'Employee updated successfully!',
        backgroundColor: AppColors.successColor,
        textColor: Colors.white,
      );
      if (mounted) Navigator.pop(context);
    } else {
      Fluttertoast.showToast(
        msg: provider.error ?? 'Failed to update employee',
        backgroundColor: AppColors.errorColor,
        textColor: Colors.white,
      );
    }
  }

  Future<void> _sendPasswordReset() async {
    setState(() => _sendingReset = true);
    final provider = context.read<EmployeeProvider>();
    final success = await provider.sendPasswordReset(_emailController.text);
    setState(() => _sendingReset = false);

    Fluttertoast.showToast(
      msg: success
          ? 'Password reset email sent'
          : (provider.error ?? 'Failed to send reset email'),
      backgroundColor:
          success ? AppColors.successColor : AppColors.errorColor,
      textColor: Colors.white,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Employee'),
        actions: [
          TextButton.icon(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.close),
            label: const Text('Cancel'),
          ),
          const SizedBox(width: AppDimensions.paddingM),
        ],
      ),
      body: Consumer<EmployeeProvider>(
        builder: (context, provider, child) {
          return SingleChildScrollView(
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
                      Text(
                        'Employee Information',
                        style: Theme.of(context).textTheme.headlineSmall
                            ?.copyWith(
                              color: AppColors.textPrimary,
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                      const SizedBox(height: AppDimensions.paddingM),
                      TextFormField(
                        controller: _nameController,
                        decoration: const InputDecoration(
                          labelText: 'Full Name *',
                        ),
                        validator: (v) =>
                            Validators.required(v, fieldName: 'Name'),
                      ),
                      const SizedBox(height: AppDimensions.paddingM),
                      TextFormField(
                        controller: _emailController,
                        decoration: const InputDecoration(
                          labelText: 'Email *',
                          helperText: 'Login email for the employee portal',
                        ),
                        keyboardType: TextInputType.emailAddress,
                        validator: Validators.email,
                      ),
                      const SizedBox(height: AppDimensions.paddingM),
                      TextFormField(
                        controller: _employeeIdController,
                        decoration: const InputDecoration(
                          labelText: 'Employee ID *',
                        ),
                        validator: (v) =>
                            Validators.required(v, fieldName: 'Employee ID'),
                      ),
                      const SizedBox(height: AppDimensions.paddingM),
                      TextFormField(
                        controller: _phoneController,
                        decoration: const InputDecoration(
                          labelText: 'Phone (Optional)',
                        ),
                        keyboardType: TextInputType.phone,
                      ),
                      const SizedBox(height: AppDimensions.paddingM),
                      SwitchListTile(
                        title: const Text('Active'),
                        subtitle: Text(
                          _isActive
                              ? 'Can log in and be assigned work'
                              : 'Cannot log in to employee portal',
                          style: TextStyle(
                            color: _isActive
                                ? AppColors.successColor
                                : AppColors.textMuted,
                            fontSize: 12,
                          ),
                        ),
                        value: _isActive,
                        onChanged: (v) => setState(() => _isActive = v),
                        activeTrackColor: AppColors.successColor,
                      ),
                      const SizedBox(height: AppDimensions.paddingXL),
                      Text(
                        'Portal Access',
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(
                              color: AppColors.textPrimary,
                              fontWeight: FontWeight.w600,
                            ),
                      ),
                      const SizedBox(height: AppDimensions.paddingS),
                      if (widget.employee.authUid != null)
                        const Text(
                          'Auth account linked. Use reset email to re-issue access.',
                          style: TextStyle(
                            color: AppColors.textMuted,
                            fontSize: 13,
                          ),
                        )
                      else
                        const Text(
                          'No Auth account linked yet. Create a new employee to set a password.',
                          style: TextStyle(
                            color: AppColors.warningColor,
                            fontSize: 13,
                          ),
                        ),
                      const SizedBox(height: AppDimensions.paddingM),
                      OutlinedButton.icon(
                        onPressed: _sendingReset ? null : _sendPasswordReset,
                        icon: _sendingReset
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : const Icon(Icons.mail_outline),
                        label: const Text('Send password reset email'),
                      ),
                      const SizedBox(height: AppDimensions.paddingXL),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: provider.isLoading ? null : _update,
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              vertical: AppDimensions.paddingM,
                            ),
                            child: provider.isLoading
                                ? const SizedBox(
                                    height: 20,
                                    width: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  )
                                : const Text(
                                    'Update Employee',
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
          );
        },
      ),
    );
  }
}
