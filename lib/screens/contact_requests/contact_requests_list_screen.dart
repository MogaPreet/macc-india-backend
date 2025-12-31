import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:intl/intl.dart';
import '../../providers/contact_request_provider.dart';
import '../../models/contact_request_model.dart';
import '../../core/constants/colors.dart';
import '../../core/constants/dimensions.dart';

/// Screen for managing contact requests (website contact form submissions)
class ContactRequestsListScreen extends StatefulWidget {
  const ContactRequestsListScreen({super.key});

  @override
  State<ContactRequestsListScreen> createState() =>
      _ContactRequestsListScreenState();
}

class _ContactRequestsListScreenState extends State<ContactRequestsListScreen> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ContactRequestProvider>().fetchRequests();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case ContactRequestStatus.pending:
        return Colors.orange;
      case ContactRequestStatus.read:
        return Colors.blue;
      case ContactRequestStatus.replied:
        return Colors.purple;
      case ContactRequestStatus.resolved:
        return AppColors.successColor;
      default:
        return AppColors.textMuted;
    }
  }

  IconData _getSubjectIcon(String subject) {
    switch (subject) {
      case ContactSubject.general:
        return Icons.help_outline;
      case ContactSubject.product:
        return Icons.laptop;
      case ContactSubject.support:
        return Icons.support_agent;
      case ContactSubject.warranty:
        return Icons.verified_user;
      case ContactSubject.bulk:
        return Icons.inventory;
      case ContactSubject.other:
        return Icons.more_horiz;
      default:
        return Icons.mail_outline;
    }
  }

  void _showMessageDetail(ContactRequestModel request) {
    final statusColor = _getStatusColor(request.status);
    final dateFormat = DateFormat('MMM dd, yyyy • hh:mm a');

    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppDimensions.radiusL),
        ),
        child: Container(
          constraints: const BoxConstraints(maxWidth: 600),
          padding: const EdgeInsets.all(AppDimensions.paddingXL),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  Icon(
                    _getSubjectIcon(request.subject),
                    color: AppColors.primaryColor,
                    size: 28,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          request.name,
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          ContactSubject.getDisplayName(request.subject),
                          style: TextStyle(
                            color: AppColors.textMuted,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: statusColor.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      ContactRequestStatus.getDisplayName(request.status),
                      style: TextStyle(
                        color: statusColor,
                        fontWeight: FontWeight.w600,
                        fontSize: 12,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),

              const Divider(height: 32),

              // Contact Info
              Wrap(
                spacing: 24,
                runSpacing: 12,
                children: [
                  _buildInfoChip(Icons.email, request.email),
                  if (request.phone != null && request.phone!.isNotEmpty)
                    _buildInfoChip(Icons.phone, request.phone!),
                  _buildInfoChip(
                    Icons.access_time,
                    dateFormat.format(request.createdAt),
                  ),
                ],
              ),

              const SizedBox(height: 24),

              // Message
              const Text(
                'Message',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 8),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(AppDimensions.paddingL),
                decoration: BoxDecoration(
                  color: AppColors.surfaceColor,
                  borderRadius: BorderRadius.circular(AppDimensions.radiusM),
                  border: Border.all(color: AppColors.borderColor),
                ),
                child: SelectableText(
                  request.message,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 15,
                    height: 1.6,
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // Actions
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  // Status Dropdown
                  SizedBox(
                    width: 180,
                    child: DropdownButtonFormField<String>(
                      initialValue: request.status,
                      decoration: InputDecoration(
                        labelText: 'Update Status',
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(
                            AppDimensions.radiusS,
                          ),
                        ),
                      ),
                      items: ContactRequestStatus.values.map((status) {
                        return DropdownMenuItem(
                          value: status,
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: 8,
                                height: 8,
                                decoration: BoxDecoration(
                                  color: _getStatusColor(status),
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(ContactRequestStatus.getDisplayName(status)),
                            ],
                          ),
                        );
                      }).toList(),
                      onChanged: (newStatus) {
                        if (newStatus != null && newStatus != request.status) {
                          _updateStatus(request, newStatus);
                          Navigator.pop(context);
                        }
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  TextButton.icon(
                    onPressed: () {
                      Navigator.pop(context);
                      _deleteRequest(request);
                    },
                    icon: const Icon(Icons.delete_outline),
                    label: const Text('Delete'),
                    style: TextButton.styleFrom(
                      foregroundColor: AppColors.errorColor,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoChip(IconData icon, String text) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: AppColors.textMuted),
        const SizedBox(width: 6),
        Text(
          text,
          style: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
        ),
      ],
    );
  }

  Future<void> _deleteRequest(ContactRequestModel request) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Request'),
        content: Text(
          'Are you sure you want to delete the request from "${request.name}"?',
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
      final provider = context.read<ContactRequestProvider>();
      final success = await provider.deleteRequest(request.id);

      if (success) {
        Fluttertoast.showToast(
          msg: 'Request deleted successfully',
          backgroundColor: AppColors.successColor,
        );
      } else {
        Fluttertoast.showToast(
          msg: provider.error ?? 'Failed to delete request',
          backgroundColor: AppColors.errorColor,
        );
      }
    }
  }

  void _updateStatus(ContactRequestModel request, String newStatus) async {
    final provider = context.read<ContactRequestProvider>();
    final success = await provider.updateRequestStatus(request.id, newStatus);

    if (success) {
      Fluttertoast.showToast(
        msg:
            'Status updated to ${ContactRequestStatus.getDisplayName(newStatus)}',
        backgroundColor: AppColors.successColor,
      );
    } else {
      Fluttertoast.showToast(
        msg: provider.error ?? 'Failed to update status',
        backgroundColor: AppColors.errorColor,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Contact Requests'),
        automaticallyImplyLeading: false,
      ),
      body: Consumer<ContactRequestProvider>(
        builder: (context, provider, child) {
          return Column(
            children: [
              // Filters
              Container(
                padding: const EdgeInsets.all(AppDimensions.paddingL),
                decoration: const BoxDecoration(
                  border: Border(
                    bottom: BorderSide(color: AppColors.dividerColor),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Status Filter Chips
                    const Text(
                      'Status',
                      style: TextStyle(
                        color: AppColors.textMuted,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          _buildStatusChip(provider, 'all', 'All'),
                          const SizedBox(width: 8),
                          _buildStatusChip(
                            provider,
                            ContactRequestStatus.pending,
                            'Pending',
                          ),
                          const SizedBox(width: 8),
                          _buildStatusChip(
                            provider,
                            ContactRequestStatus.read,
                            'Read',
                          ),
                          const SizedBox(width: 8),
                          _buildStatusChip(
                            provider,
                            ContactRequestStatus.replied,
                            'Replied',
                          ),
                          const SizedBox(width: 8),
                          _buildStatusChip(
                            provider,
                            ContactRequestStatus.resolved,
                            'Resolved',
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Subject Filter + Search Row
                    Row(
                      children: [
                        // Subject Dropdown
                        SizedBox(
                          width: 200,
                          child: DropdownButtonFormField<String>(
                            initialValue: provider.subjectFilter,
                            decoration: InputDecoration(
                              labelText: 'Subject Type',
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 8,
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(
                                  AppDimensions.radiusM,
                                ),
                              ),
                            ),
                            items: [
                              const DropdownMenuItem(
                                value: 'all',
                                child: Text('All Subjects'),
                              ),
                              ...ContactSubject.values.map((subject) {
                                return DropdownMenuItem(
                                  value: subject,
                                  child: Text(
                                    ContactSubject.getDisplayName(subject),
                                  ),
                                );
                              }),
                            ],
                            onChanged: (value) {
                              if (value != null) {
                                provider.setSubjectFilter(value);
                              }
                            },
                          ),
                        ),

                        const SizedBox(width: 16),

                        // Search Bar
                        Expanded(
                          child: TextField(
                            controller: _searchController,
                            decoration: InputDecoration(
                              hintText: 'Search by name or email...',
                              prefixIcon: const Icon(Icons.search),
                              suffixIcon: _searchController.text.isNotEmpty
                                  ? IconButton(
                                      icon: const Icon(Icons.clear),
                                      onPressed: () {
                                        _searchController.clear();
                                        provider.setSearchQuery('');
                                      },
                                    )
                                  : null,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(
                                  AppDimensions.radiusM,
                                ),
                              ),
                            ),
                            onChanged: (value) {
                              provider.setSearchQuery(value);
                            },
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Content
              Expanded(child: _buildContent(provider)),
            ],
          );
        },
      ),
    );
  }

  Widget _buildStatusChip(
    ContactRequestProvider provider,
    String status,
    String label,
  ) {
    final isSelected = provider.statusFilter == status;
    final color = status == 'all'
        ? AppColors.primaryColor
        : _getStatusColor(status);
    final count = provider.getCountByStatus(status);

    return FilterChip(
      label: Text('$label ($count)'),
      selected: isSelected,
      onSelected: (selected) {
        provider.setStatusFilter(status);
      },
      selectedColor: color.withValues(alpha: 0.2),
      checkmarkColor: color,
      labelStyle: TextStyle(
        color: isSelected ? color : AppColors.textSecondary,
        fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
      ),
      side: BorderSide(color: isSelected ? color : AppColors.borderColor),
    );
  }

  Widget _buildContent(ContactRequestProvider provider) {
    if (provider.isLoading && provider.allRequests.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (provider.error != null && provider.allRequests.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64, color: AppColors.errorColor),
            const SizedBox(height: AppDimensions.paddingM),
            Text(
              'Error loading requests',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: AppDimensions.paddingS),
            Text(provider.error!),
            const SizedBox(height: AppDimensions.paddingL),
            ElevatedButton.icon(
              onPressed: () => provider.fetchRequests(),
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (provider.allRequests.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.mail_outline, size: 64, color: AppColors.textMuted),
            const SizedBox(height: AppDimensions.paddingM),
            Text(
              'No contact requests yet',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: AppDimensions.paddingS),
            Text(
              'Contact form submissions will appear here',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
        ),
      );
    }

    if (provider.requests.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search_off, size: 64, color: AppColors.textMuted),
            const SizedBox(height: AppDimensions.paddingM),
            Text(
              'No matching requests',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: AppDimensions.paddingS),
            Text(
              'Try adjusting your filters or search query',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () => provider.fetchRequests(),
      child: ListView.builder(
        padding: const EdgeInsets.all(AppDimensions.paddingL),
        itemCount: provider.requests.length,
        itemBuilder: (context, index) {
          final request = provider.requests[index];
          return _buildRequestCard(request);
        },
      ),
    );
  }

  Widget _buildRequestCard(ContactRequestModel request) {
    final dateFormat = DateFormat('MMM dd, yyyy');
    final statusColor = _getStatusColor(request.status);

    return Card(
      margin: const EdgeInsets.only(bottom: AppDimensions.paddingM),
      child: InkWell(
        onTap: () => _showMessageDetail(request),
        borderRadius: BorderRadius.circular(AppDimensions.radiusM),
        child: Padding(
          padding: const EdgeInsets.all(AppDimensions.paddingL),
          child: Row(
            children: [
              // Subject Icon
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.primaryColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  _getSubjectIcon(request.subject),
                  color: AppColors.primaryColor,
                  size: 24,
                ),
              ),

              const SizedBox(width: 16),

              // Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            request.name,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ),
                        Text(
                          dateFormat.format(request.createdAt),
                          style: const TextStyle(
                            color: AppColors.textMuted,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      request.email,
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.surfaceColor,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            ContactSubject.getDisplayName(request.subject),
                            style: const TextStyle(
                              color: AppColors.textMuted,
                              fontSize: 11,
                            ),
                          ),
                        ),
                        const Spacer(),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: statusColor.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            ContactRequestStatus.getDisplayName(request.status),
                            style: TextStyle(
                              color: statusColor,
                              fontWeight: FontWeight.w600,
                              fontSize: 11,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      request.message,
                      style: const TextStyle(
                        color: AppColors.textMuted,
                        fontSize: 13,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),

              const SizedBox(width: 8),

              // Arrow
              const Icon(Icons.chevron_right, color: AppColors.textMuted),
            ],
          ),
        ),
      ),
    );
  }
}
