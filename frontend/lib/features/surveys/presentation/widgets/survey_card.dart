import 'package:flutter/material.dart';
import 'package:frontend/constants/colors.dart';
import 'package:frontend/constants/texts/texts_general.dart';
import 'package:frontend/constants/texts/texts_surveys.dart';
import 'package:frontend/features/surveys/data/models/survey.dart';

/// Card displaying one survey and direct vote actions.
class SurveyCard extends StatelessWidget {
  /// Creates a [SurveyCard].
  const SurveyCard({
    required this.survey,
    required this.isAuthenticated,
    required this.isStaff,
    required this.canVote,
    required this.onVote,
    this.onEdit,
    this.onDelete,
    super.key,
  });

  /// Survey to render.
  final Survey survey;

  /// Whether the current user is authenticated.
  final bool isAuthenticated;

  /// Whether the current user has staff privileges.
  final bool isStaff;

  /// Whether the current user can answer this survey.
  final bool canVote;

  /// Callback called when user taps one option.
  final ValueChanged<int> onVote;

  /// Optional edit callback for staff.
  final ValueChanged<Survey>? onEdit;

  /// Optional delete callback for staff.
  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context) {
    final totalVotes = survey.totalVotes;
    final canManage = isStaff;
    final dateStr = _formatDate(survey.createdAt);

    return Card(
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.08),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.16),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.how_to_vote,
                    size: 20,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    survey.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.calendar_today_outlined,
                        size: 12,
                        color: AppColors.secondaryText,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        dateStr,
                        style: const TextStyle(
                          fontSize: 11,
                          color: AppColors.secondaryText,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (survey.description.trim().isNotEmpty)
                    Text(
                      survey.description,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(
                        context,
                      ).textTheme.bodyMedium?.copyWith(height: 1.35),
                    ),
                  const SizedBox(height: 10),
                  _InfoRow(
                    icon: Icons.location_on_outlined,
                    text: survey.address,
                  ),
                  const SizedBox(height: 6),
                  _InfoRow(
                    icon: Icons.groups_2_outlined,
                    text:
                        '${SurveysTexts.targetedAudience}: ${survey.citizenTarget?.label ?? SurveysTexts.targetAll}',
                  ),
                  const SizedBox(height: 10),
                  ...survey.options.map((option) {
                    final isSelected =
                        survey.currentUserVoteOptionId == option.id;
                    final percentage = totalVotes == 0
                        ? 0
                        : ((option.voteCount * 100) / totalVotes).round();
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: FilledButton.tonal(
                        onPressed: isAuthenticated && canVote
                            ? () => onVote(option.id)
                            : null,
                        style: FilledButton.styleFrom(
                          backgroundColor: isSelected
                              ? AppColors.secondary
                              : null,
                          foregroundColor: isSelected
                              ? AppColors.primaryText
                              : null,
                          side: BorderSide(
                            color: isSelected
                                ? AppColors.primary
                                : Colors.transparent,
                          ),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                option.text,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text('$percentage%'),
                          ],
                        ),
                      ),
                    );
                  }),
                  const Spacer(),
                  Text(
                    '${survey.totalVotes} ${SurveysTexts.totalVotes}',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.secondaryText,
                    ),
                  ),
                  if (!isAuthenticated) ...[
                    const SizedBox(height: 8),
                    Text(
                      SurveysTexts.loginRequiredToVote,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.error,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
          if (canManage)
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 0, 8, 8),
              child: Row(
                children: [
                  Expanded(
                    child: _ActionButton(
                      icon: Icons.edit_outlined,
                      label: AppTextsGeneral.edit,
                      color: AppColors.primary,
                      onTap: onEdit != null ? () => onEdit!(survey) : null,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: _ActionButton(
                      icon: Icons.delete_outline_rounded,
                      label: AppTextsGeneral.delete,
                      color: AppColors.error,
                      onTap: onDelete,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/'
        '${date.month.toString().padLeft(2, '0')}/'
        '${date.year}';
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 16, color: AppColors.secondaryText),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: AppColors.primaryText),
          ),
        ),
      ],
    );
  }
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.icon,
    required this.label,
    required this.color,
    this.onTap,
  });

  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final effectiveColor = onTap != null ? color : AppColors.disabled;
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 16, color: effectiveColor),
              const SizedBox(width: 4),
              Flexible(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: effectiveColor,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
