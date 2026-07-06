import 'package:flutter/material.dart';
import '../models/transaction_model.dart';
import '../models/category_model.dart';
import '../models/account_model.dart';
import '../utils/app_theme.dart';
import '../utils/formatters.dart';
import '../utils/emoji_to_icon.dart';

class TransactionTile extends StatelessWidget {
  final TransactionModel transaction;
  final CategoryModel? category;
  final AccountModel? account;
  final AccountModel? relatedAccount;
  final VoidCallback? onTap;
  final VoidCallback? onDelete;

  const TransactionTile({
    super.key,
    required this.transaction,
    this.category,
    this.account,
    this.relatedAccount,
    this.onTap,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final isIncome = transaction.type == 'income';
    final isTransfer = transaction.type == 'transfer';
    final color = Color(category?.color ?? 0xFF6C63FF);
    final amountColor = isTransfer
        ? AppTheme.primaryColor
        : isIncome
        ? AppTheme.incomeColor
        : AppTheme.expenseColor;
    final amountPrefix = isTransfer ? '' : (isIncome ? '+' : '-');
    final categoryLabel = transaction.hasSplits
        ? 'Split ${transaction.splits.length}'
        : category?.name ?? 'Unknown';
    final hasExtras =
        !isTransfer &&
        (transaction.paymentMethod != null ||
            transaction.tags.isNotEmpty ||
            transaction.receiptPath != null ||
            transaction.trackingStatus != TransactionTrackingStatus.normal);

    return Dismissible(
      key: Key(transaction.id),
      direction: onDelete != null
          ? DismissDirection.endToStart
          : DismissDirection.none,
      confirmDismiss: (_) async {
        return await showDialog<bool>(
          context: context,
          builder: (_) => AlertDialog(
            backgroundColor: AppTheme.cardColor,
            title: const Text(
              'Delete Transaction',
              style: TextStyle(color: Colors.white),
            ),
            content: const Text(
              'Are you sure you want to delete this transaction?',
              style: TextStyle(color: Colors.white70),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(context, true),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.expenseColor,
                ),
                child: const Text('Delete'),
              ),
            ],
          ),
        );
      },
      onDismissed: (_) => onDelete?.call(),
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        margin: const EdgeInsets.only(bottom: 8),
        decoration: BoxDecoration(
          color: AppTheme.expenseColor.withAlpha(51),
          borderRadius: BorderRadius.circular(14),
        ),
        child: const Icon(Icons.delete_rounded, color: AppTheme.expenseColor),
      ),
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: AppTheme.cardColor,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: Colors.white.withAlpha(13)),
          ),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: color.withAlpha(38),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(
                  child: Icon(
                    EmojiToIcon.getIcon(category?.icon ?? 'cash'),
                    color: color,
                    size: 20,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      transaction.title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 3),
                    Row(
                      children: [
                        Text(
                          Formatters.relativeDate(transaction.date),
                          style: const TextStyle(
                            color: Colors.white38,
                            fontSize: 11,
                          ),
                        ),
                        const Text(
                          ' · ',
                          style: TextStyle(color: Colors.white38, fontSize: 11),
                        ),
                        Flexible(
                          child: Text(
                            categoryLabel,
                            style: const TextStyle(
                              color: Colors.white38,
                              fontSize: 11,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (account != null) ...[
                          const Text(
                            ' · ',
                            style: TextStyle(
                              color: Colors.white38,
                              fontSize: 11,
                            ),
                          ),
                          Icon(
                            EmojiToIcon.getIcon(account!.icon),
                            color: Colors.white38,
                            size: 12,
                          ),
                          const SizedBox(width: 2),
                          Flexible(
                            child: Text(
                              isTransfer && relatedAccount != null
                                  ? '${account!.name} → ${relatedAccount!.name}'
                                  : account!.name,
                              style: const TextStyle(
                                color: Colors.white38,
                                fontSize: 11,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ],
                    ),
                    if (hasExtras) ...[
                      const SizedBox(height: 6),
                      Wrap(
                        spacing: 6,
                        runSpacing: 4,
                        children: [
                          if (transaction.paymentMethod != null)
                            _MetaChip(
                              icon: Icons.account_balance_wallet_rounded,
                              label: TransactionPaymentMethod.label(
                                transaction.paymentMethod,
                              ),
                            ),
                          if (transaction.trackingStatus !=
                              TransactionTrackingStatus.normal)
                            _MetaChip(
                              icon:
                                  transaction.trackingStatus ==
                                      TransactionTrackingStatus.refund
                                  ? Icons.replay_rounded
                                  : Icons.assignment_return_rounded,
                              label: TransactionTrackingStatus.label(
                                transaction.trackingStatus,
                              ),
                            ),
                          if (transaction.receiptPath != null)
                            const _MetaChip(
                              icon: Icons.receipt_long_rounded,
                              label: 'Receipt',
                            ),
                          ...transaction.tags
                              .take(2)
                              .map(
                                (tag) => _MetaChip(
                                  icon: Icons.sell_rounded,
                                  label: tag,
                                ),
                              ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '$amountPrefix${Formatters.currency(transaction.amount)}',
                style: TextStyle(
                  color: amountColor,
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MetaChip extends StatelessWidget {
  final IconData icon;
  final String label;

  const _MetaChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: Colors.white.withAlpha(15),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 11, color: Colors.white38),
          const SizedBox(width: 3),
          Text(
            label,
            style: const TextStyle(color: Colors.white54, fontSize: 10),
          ),
        ],
      ),
    );
  }
}
