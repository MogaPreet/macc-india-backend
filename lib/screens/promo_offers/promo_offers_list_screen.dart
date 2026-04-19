import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:intl/intl.dart';

import '../../providers/promo_offer_provider.dart';
import '../../providers/product_provider.dart';
import '../../models/promo_offer_model.dart';
import '../../models/product_model.dart';
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
      context.read<ProductProvider>().fetchProducts();
    });
  }

  Color _getStatusColor(PromoOfferModel offer) {
    if (!offer.isActive) return Colors.grey;
    if (offer.hasExpired) return Colors.red;
    if (offer.startDate != null &&
        DateTime.now().isBefore(
          DateTime(
            offer.startDate!.year,
            offer.startDate!.month,
            offer.startDate!.day,
          ),
        )) {
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
      body: Consumer2<PromoOfferProvider, ProductProvider>(
        builder: (context, provider, productProvider, _) {
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

          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                padding: const EdgeInsets.all(AppDimensions.paddingL),
                decoration: const BoxDecoration(
                  border: Border(
                    bottom: BorderSide(color: AppColors.dividerColor),
                  ),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Promo offers',
                            style: Theme.of(context)
                                .textTheme
                                .headlineMedium
                                ?.copyWith(
                                  color: AppColors.textPrimary,
                                  fontWeight: FontWeight.bold,
                                ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${provider.offers.length} offers · Hero banners with linked products',
                            style: const TextStyle(
                              color: AppColors.textMuted,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                    ElevatedButton.icon(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const AddPromoOfferScreen(),
                          ),
                        );
                      },
                      icon: const Icon(Icons.add),
                      label: const Text('New promo'),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: provider.offers.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.local_offer_outlined,
                              size: 72,
                              color: AppColors.textMuted,
                            ),
                            const SizedBox(height: AppDimensions.paddingM),
                            Text(
                              'No promo offers yet',
                              style: Theme.of(context).textTheme.titleLarge,
                            ),
                            const SizedBox(height: AppDimensions.paddingS),
                            const Text(
                              'Create a hero banner and attach catalog products.',
                              style: TextStyle(color: AppColors.textSecondary),
                            ),
                            const SizedBox(height: AppDimensions.paddingL),
                            FilledButton.icon(
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) =>
                                        const AddPromoOfferScreen(),
                                  ),
                                );
                              },
                              icon: const Icon(Icons.add),
                              label: const Text('Create promo'),
                            ),
                          ],
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: () async {
                          await provider.fetchOffers();
                          await productProvider.fetchProducts();
                        },
                        child: ListView.builder(
                          padding: const EdgeInsets.all(AppDimensions.paddingL),
                          itemCount: provider.offers.length,
                          itemBuilder: (context, index) {
                            final offer = provider.offers[index];
                            return _buildOfferCard(
                              offer,
                              productProvider,
                            );
                          },
                        ),
                      ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildOfferCard(
    PromoOfferModel offer,
    ProductProvider productProvider,
  ) {
    final dateFormat = DateFormat('MMM dd, yyyy');
    final statusColor = _getStatusColor(offer);

    return Card(
      margin: const EdgeInsets.only(bottom: AppDimensions.paddingL),
      clipBehavior: Clip.antiAlias,
      elevation: 3,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppDimensions.radiusL),
        side: const BorderSide(color: AppColors.borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
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
                Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.transparent,
                        Colors.black.withValues(alpha: 0.75),
                      ],
                    ),
                  ),
                ),
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
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          shadows: [
                            Shadow(
                              color: Colors.black45,
                              blurRadius: 8,
                            ),
                          ],
                        ),
                      ),
                      if (offer.subtitle != null) ...[
                        const SizedBox(height: 4),
                        Text(
                          offer.subtitle!,
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.9),
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
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
          Padding(
            padding: const EdgeInsets.all(AppDimensions.paddingL),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(
                      Icons.calendar_today,
                      size: 14,
                      color: AppColors.textMuted,
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        offer.startDate != null && offer.endDate != null
                            ? '${dateFormat.format(offer.startDate!)} → ${dateFormat.format(offer.endDate!)}'
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
                    ),
                  ],
                ),
                const SizedBox(height: AppDimensions.paddingM),
                Text(
                  'Linked products',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                ),
                const SizedBox(height: AppDimensions.paddingS),
                SizedBox(
                  height: 88,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: offer.productIds.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 10),
                    itemBuilder: (context, i) {
                      final id = offer.productIds[i];
                      final p = productProvider.getProductById(id);
                      return _ProductThumbCard(product: p, productId: id);
                    },
                  ),
                ),
                const SizedBox(height: AppDimensions.paddingL),
                Row(
                  children: [
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

class _ProductThumbCard extends StatelessWidget {
  const _ProductThumbCard({
    required this.product,
    required this.productId,
  });

  final ProductModel? product;
  final String productId;

  @override
  Widget build(BuildContext context) {
    final name = product?.name ?? 'Missing';
    final hasImage = product != null && product!.images.isNotEmpty;

    return Container(
      width: 200,
      decoration: BoxDecoration(
        color: AppColors.surfaceColor,
        borderRadius: BorderRadius.circular(AppDimensions.radiusM),
        border: Border.all(color: AppColors.borderColor),
      ),
      clipBehavior: Clip.antiAlias,
      child: Row(
        children: [
          SizedBox(
            width: 72,
            height: 88,
            child: hasImage
                ? CachedNetworkImage(
                    imageUrl: product!.mainImage,
                    fit: BoxFit.cover,
                    errorWidget: (_, __, ___) => const ColoredBox(
                      color: AppColors.cardColor,
                      child: Icon(Icons.broken_image_outlined),
                    ),
                  )
                : const ColoredBox(
                    color: AppColors.cardColor,
                    child: Icon(Icons.inventory_2_outlined,
                        color: AppColors.textMuted),
                  ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    name,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                    ),
                  ),
                  if (product != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      '₹${product!.price.toStringAsFixed(0)}',
                      style: const TextStyle(
                        color: AppColors.primaryLight,
                        fontWeight: FontWeight.w700,
                        fontSize: 12,
                      ),
                    ),
                  ] else
                    Text(
                      productId,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 10,
                        color: AppColors.warningColor,
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
