import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:intl/intl.dart';
import '../../providers/product_request_provider.dart';
import '../../models/product_request_model.dart';
import '../../core/constants/colors.dart';
import '../../core/constants/dimensions.dart';

/// Screen for managing product requests (user inquiries)
class ProductRequestsListScreen extends StatefulWidget {
  const ProductRequestsListScreen({super.key});

  @override
  State<ProductRequestsListScreen> createState() =>
      _ProductRequestsListScreenState();
}

class _ProductRequestsListScreenState extends State<ProductRequestsListScreen> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ProductRequestProvider>().fetchRequests();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case RequestStatus.pending:
        return Colors.orange;
      case RequestStatus.contacted:
        return Colors.blue;
      case RequestStatus.completed:
        return AppColors.successColor;
      case RequestStatus.cancelled:
        return Colors.grey;
      default:
        return AppColors.textMuted;
    }
  }

  Future<void> _deleteRequest(ProductRequestModel request) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Request'),
        content: Text(
          'Are you sure you want to delete the request from "${request.customerName}"?',
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
      final provider = context.read<ProductRequestProvider>();
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

  void _updateStatus(ProductRequestModel request, String newStatus) async {
    final provider = context.read<ProductRequestProvider>();
    final success = await provider.updateRequestStatus(request.id, newStatus);

    if (success) {
      Fluttertoast.showToast(
        msg: 'Status updated to ${RequestStatus.getDisplayName(newStatus)}',
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
        title: const Text('Product Requests'),
        automaticallyImplyLeading: false,
      ),
      body: Consumer<ProductRequestProvider>(
        builder: (context, provider, child) {
          return Column(
            children: [
              // Status Filter Tabs & Search
              Container(
                padding: const EdgeInsets.all(AppDimensions.paddingL),
                decoration: const BoxDecoration(
                  border: Border(
                    bottom: BorderSide(color: AppColors.dividerColor),
                  ),
                ),
                child: Column(
                  children: [
                    // Status Filter Chips
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          _buildFilterChip(
                            provider,
                            'all',
                            'All',
                            AppColors.primaryColor,
                          ),
                          const SizedBox(width: 8),
                          _buildFilterChip(
                            provider,
                            RequestStatus.pending,
                            'Pending',
                            Colors.orange,
                          ),
                          const SizedBox(width: 8),
                          _buildFilterChip(
                            provider,
                            RequestStatus.contacted,
                            'Contacted',
                            Colors.blue,
                          ),
                          const SizedBox(width: 8),
                          _buildFilterChip(
                            provider,
                            RequestStatus.completed,
                            'Completed',
                            AppColors.successColor,
                          ),
                          const SizedBox(width: 8),
                          _buildFilterChip(
                            provider,
                            RequestStatus.cancelled,
                            'Cancelled',
                            Colors.grey,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: AppDimensions.paddingM),

                    // Search Bar
                    TextField(
                      controller: _searchController,
                      decoration: InputDecoration(
                        hintText:
                            'Search by customer name, phone, or product...',
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

  Widget _buildFilterChip(
    ProductRequestProvider provider,
    String status,
    String label,
    Color color,
  ) {
    final isSelected = provider.statusFilter == status;
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

  Widget _buildContent(ProductRequestProvider provider) {
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
            Icon(Icons.inbox_outlined, size: 64, color: AppColors.textMuted),
            const SizedBox(height: AppDimensions.paddingM),
            Text(
              'No product requests yet',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: AppDimensions.paddingS),
            Text(
              'Requests from your website will appear here',
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

  Widget _buildRequestCard(ProductRequestModel request) {
    final dateFormat = DateFormat('MMM dd, yyyy • hh:mm a');
    final statusColor = _getStatusColor(request.status);

    return Card(
      margin: const EdgeInsets.only(bottom: AppDimensions.paddingM),
      child: Padding(
        padding: const EdgeInsets.all(AppDimensions.paddingL),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Row
            Row(
              children: [
                // Customer Info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        request.customerName,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(
                            Icons.phone,
                            size: 14,
                            color: AppColors.textMuted,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            request.customerPhone,
                            style: const TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // Status Badge
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: statusColor.withValues(alpha: 0.5),
                    ),
                  ),
                  child: Text(
                    RequestStatus.getDisplayName(request.status),
                    style: TextStyle(
                      color: statusColor,
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),

            const Divider(height: 24),

            // Product Info
            Row(
              children: [
                const Icon(
                  Icons.laptop,
                  size: 16,
                  color: AppColors.primaryColor,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    request.productName,
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                TextButton.icon(
                  onPressed: () {
                    // TODO: Navigate to product details
                    Fluttertoast.showToast(
                      msg: 'Product: ${request.productSlug}',
                      backgroundColor: AppColors.primaryColor,
                    );
                  },
                  icon: const Icon(Icons.open_in_new, size: 14),
                  label: const Text('View Product'),
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 8),

            // Date
            Row(
              children: [
                const Icon(
                  Icons.access_time,
                  size: 14,
                  color: AppColors.textMuted,
                ),
                const SizedBox(width: 4),
                Text(
                  dateFormat.format(request.createdAt),
                  style: const TextStyle(
                    color: AppColors.textMuted,
                    fontSize: 12,
                  ),
                ),
              ],
            ),

            const Divider(height: 24),

            // Actions Row
            Row(
              children: [
                // Status Dropdown
                Expanded(
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
                    items: RequestStatus.values.map((status) {
                      return DropdownMenuItem(
                        value: status,
                        child: Row(
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
                            Text(RequestStatus.getDisplayName(status)),
                          ],
                        ),
                      );
                    }).toList(),
                    onChanged: (newStatus) {
                      if (newStatus != null && newStatus != request.status) {
                        _updateStatus(request, newStatus);
                      }
                    },
                  ),
                ),

                const SizedBox(width: AppDimensions.paddingM),

                // Quick Actions
                IconButton(
                  onPressed: () {
                    // Copy phone number
                    Fluttertoast.showToast(
                      msg: 'Phone: ${request.customerPhone}',
                      backgroundColor: AppColors.primaryColor,
                    );
                  },
                  icon: const Icon(Icons.phone),
                  color: AppColors.primaryColor,
                  tooltip: 'Call Customer',
                ),
                IconButton(
                  onPressed: () => _deleteRequest(request),
                  icon: const Icon(Icons.delete_outline),
                  color: AppColors.errorColor,
                  tooltip: 'Delete Request',
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
