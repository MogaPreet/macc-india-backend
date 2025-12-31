import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:intl/intl.dart';
import '../../providers/promo_offer_provider.dart';
import '../../models/promo_offer_model.dart';
import '../../core/constants/colors.dart';
import '../../core/constants/dimensions.dart';
import 'add_promo_offer_screen.dart';
import 'edit_promo_offer_screen.dart';

/// Screen for managing promo offers
class PromoOffersListScreen extends StatefulWidget {
  const PromoOffersListScreen({super.key});

  @override
  State<PromoOffersListScreen> createState() => _PromoOffersListScreenState();
}

class _PromoOffersListScreenState extends State<PromoOffersListScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<PromoOfferProvider>().fetchOffers();
    });
  }

  Color _getStatusColor(PromoOfferModel offer) {
    if (!offer.isActive) return Colors.grey;
    if (offer.hasExpired) return Colors.red;
    if (offer.startDate != null && DateTime.now().isBefore(offer.startDate!)) {
      return Colors.orange;
    }
    return AppColors.successColor;
  }

  Future<void> _deleteOffer(PromoOfferModel offer) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Promo Offer'),
        content: Text('Are you sure you want to delete "${offer.title}"?'),
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
      final provider = context.read<PromoOfferProvider>();
      final success = await provider.deleteOffer(
        offer.id,
        offer.backgroundImage,
      );

      if (success) {
        Fluttertoast.showToast(
          msg: 'Promo offer deleted successfully',
          backgroundColor: AppColors.successColor,
        );
      } else {
        Fluttertoast.showToast(
          msg: provider.error ?? 'Failed to delete offer',
          backgroundColor: AppColors.errorColor,
        );
      }
    }
  }

  Future<void> _toggleActive(PromoOfferModel offer) async {
    final provider = context.read<PromoOfferProvider>();

    // Show warning if activating
    if (!offer.isActive) {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Activate Offer'),
          content: const Text(
            'Activating this offer will deactivate any other active offers. Continue?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Activate'),
            ),
          ],
        ),
      );
      if (confirmed != true) return;
    }

    final success = await provider.toggleOfferActive(offer.id, !offer.isActive);

    if (success) {
      Fluttertoast.showToast(
        msg: offer.isActive ? 'Offer deactivated' : 'Offer activated',
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
        title: const Text('Promo Offers'),
        automaticallyImplyLeading: false,
      ),
      body: Consumer<PromoOfferProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading && provider.offers.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }

          if (provider.error != null && provider.offers.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.error_outline,
                    size: 64,
                    color: AppColors.errorColor,
                  ),
                  const SizedBox(height: AppDimensions.paddingM),
                  Text(
                    'Error loading offers',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: AppDimensions.paddingS),
                  Text(provider.error!),
                  const SizedBox(height: AppDimensions.paddingL),
                  ElevatedButton.icon(
                    onPressed: () => provider.fetchOffers(),
                    icon: const Icon(Icons.refresh),
                    label: const Text('Retry'),
                  ),
                ],
              ),
            );
          }

          if (provider.offers.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.local_offer_outlined,
                    size: 64,
                    color: AppColors.textMuted,
                  ),
                  const SizedBox(height: AppDimensions.paddingM),
                  Text(
                    'No promo offers yet',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: AppDimensions.paddingS),
                  Text(
                    'Create your first promotional offer',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: () => provider.fetchOffers(),
            child: ListView.builder(
              padding: const EdgeInsets.all(AppDimensions.paddingL),
              itemCount: provider.offers.length,
              itemBuilder: (context, index) {
                final offer = provider.offers[index];
                return _buildOfferCard(offer);
              },
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const AddPromoOfferScreen(),
            ),
          );
        },
        icon: const Icon(Icons.add),
        label: const Text('Add Offer'),
        backgroundColor: AppColors.primaryColor,
      ),
    );
  }

  Widget _buildOfferCard(PromoOfferModel offer) {
    final dateFormat = DateFormat('MMM dd, yyyy');
    final statusColor = _getStatusColor(offer);

    return Card(
      margin: const EdgeInsets.only(bottom: AppDimensions.paddingL),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Background Image
          AspectRatio(
            aspectRatio: 16 / 9,
            child: Stack(
              fit: StackFit.expand,
              children: [
                CachedNetworkImage(
                  imageUrl: offer.backgroundImage,
                  fit: BoxFit.cover,
                  placeholder: (context, url) => Container(
                    color: AppColors.surfaceColor,
                    child: const Center(child: CircularProgressIndicator()),
                  ),
                  errorWidget: (context, url, error) => Container(
                    color: AppColors.surfaceColor,
                    child: const Icon(
                      Icons.broken_image,
                      size: 48,
                      color: AppColors.textMuted,
                    ),
                  ),
                ),
                // Gradient overlay
                Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.transparent,
                        Colors.black.withValues(alpha: 0.7),
                      ],
                    ),
                  ),
                ),
                // Title overlay
                Positioned(
                  bottom: 16,
                  left: 16,
                  right: 16,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        offer.title,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (offer.subtitle != null) ...[
                        const SizedBox(height: 4),
                        Text(
                          offer.subtitle!,
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.8),
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                // Status Badge
                Positioned(
                  top: 12,
                  right: 12,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: statusColor,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      offer.statusText,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Info & Actions
          Padding(
            padding: const EdgeInsets.all(AppDimensions.paddingL),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Date Range
                Row(
                  children: [
                    const Icon(
                      Icons.calendar_today,
                      size: 14,
                      color: AppColors.textMuted,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      offer.startDate != null && offer.endDate != null
                          ? '${dateFormat.format(offer.startDate!)} - ${dateFormat.format(offer.endDate!)}'
                          : offer.startDate != null
                          ? 'From ${dateFormat.format(offer.startDate!)}'
                          : offer.endDate != null
                          ? 'Until ${dateFormat.format(offer.endDate!)}'
                          : 'No date limit',
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 13,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      '${offer.productIds.length} products',
                      style: TextStyle(
                        color: AppColors.textMuted,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: AppDimensions.paddingL),

                // Actions
                Row(
                  children: [
                    // Active Toggle
                    Expanded(
                      child: SwitchListTile(
                        title: const Text(
                          'Active',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        value: offer.isActive,
                        onChanged: (_) => _toggleActive(offer),
                        activeTrackColor: AppColors.successColor,
                        contentPadding: EdgeInsets.zero,
                      ),
                    ),
                    IconButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) =>
                                EditPromoOfferScreen(offer: offer),
                          ),
                        );
                      },
                      icon: const Icon(Icons.edit_outlined),
                      color: AppColors.primaryColor,
                      tooltip: 'Edit',
                    ),
                    IconButton(
                      onPressed: () => _deleteOffer(offer),
                      icon: const Icon(Icons.delete_outline),
                      color: AppColors.errorColor,
                      tooltip: 'Delete',
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
