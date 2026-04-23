// ignore_for_file: public_member_api_docs, lines_longer_than_80_chars, prefer_const_constructors

import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:frontend/constants/colors.dart';
import 'package:frontend/constants/texts/texts_home.dart';
import 'package:frontend/constants/texts/texts_news.dart';
import 'package:frontend/design_systems/custom_snack_bar.dart';
import 'package:frontend/features/auth/application/bloc/auth_bloc.dart';
import 'package:frontend/features/news/data/models/news_question.dart';
import 'package:frontend/features/news/data/news_repository.dart';
import 'package:frontend/features/news/data/news_repository_factory.dart';
import 'package:frontend/features/users/data/models/user.dart';
import 'package:frontend/ui/assets.dart';
import 'package:frontend/ui/widgets/breadcrumb.dart';
import 'package:frontend/ui/widgets/page_header.dart';
import 'package:intl/intl.dart';

class NewsPage extends StatefulWidget {
  const NewsPage({super.key, this.newsRepository});

  final NewsRepository? newsRepository;

  @override
  State<NewsPage> createState() => _NewsPageState();
}

class _NewsPageState extends State<NewsPage> {
  static const int _staffQuestionsPerPage = 3;

  late final NewsRepository _newsRepository;
  late Future<List<NewsQuestion>> _questionsFuture;
  final TextEditingController _subjectController = TextEditingController();
  final TextEditingController _messageController = TextEditingController();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  bool _isSubmitting = false;
  _StaffInboxTab? _selectedStaffTab = _StaffInboxTab.pending;
  _CitizenInboxTab? _selectedCitizenTab = _CitizenInboxTab.pending;
  int? _pendingPage = 1;
  int? _historyPage = 1;
  int? _citizenPendingPage = 1;
  int? _citizenHistoryPage = 1;

  final List<_SocialPost> _posts = const [
    _SocialPost(
      network: AppTextsNews.postNetworkInstagram,
      title: AppTextsNews.postTitlePark,
      excerpt: AppTextsNews.postExcerptPark,
      timeLabel: AppTextsNews.postTimeTwoHours,
      accent: AppColors.warning,
      icon: Icons.photo_camera_outlined,
    ),
    _SocialPost(
      network: AppTextsNews.postNetworkFacebook,
      title: AppTextsNews.postTitleMeeting,
      excerpt: AppTextsNews.postExcerptMeeting,
      timeLabel: AppTextsNews.postTimeToday,
      accent: AppColors.info,
      icon: Icons.campaign_outlined,
    ),
    _SocialPost(
      network: AppTextsNews.postNetworkTown,
      title: AppTextsNews.postTitleWorks,
      excerpt: AppTextsNews.postExcerptWorks,
      timeLabel: AppTextsNews.postTimeYesterday,
      accent: AppColors.textDark,
      icon: Icons.construction_outlined,
    ),
  ];

  final List<_CityPhoto> _photos = const [
    _CityPhoto(
      title: AppTextsNews.photoTitleCentralSquare,
      subtitle: AppTextsNews.photoSubtitleCentralSquare,
      assetPath: AppAssets.home_background,
      overlay: AppColors.overlay,
    ),
  ];

  @override
  void initState() {
    super.initState();
    _newsRepository = widget.newsRepository ?? createNewsRepository();
    _questionsFuture = _newsRepository.listQuestions();
  }

  @override
  void dispose() {
    _subjectController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final user = context.select<AuthBloc, User?>((bloc) => bloc.state.user);
    final isStaff = user?.isStaff ?? false;

    return Scaffold(
      backgroundColor: AppColors.page,
      body: RefreshIndicator(
        color: AppColors.primary,
        onRefresh: _refreshQuestions,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1360),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const PageHeader(
                    title: AppTextsHome.newsTitle,
                    description: AppTextsNews.pageDescription,
                    icon: Icons.newspaper,
                    breadcrumbItems: [
                      BreadcrumbItem(label: AppTextsHome.newsTitle),
                    ],
                  ),
                  const SizedBox(height: 20),
                  LayoutBuilder(
                    builder: (context, constraints) {
                      final isStacked = constraints.maxWidth < 1080;
                      if (isStacked) {
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            _buildSocialFeed(),
                            const SizedBox(height: 16),
                            _buildPhotoGallery(),
                            const SizedBox(height: 16),
                            _buildQuestionPanel(isStaff: isStaff),
                            const SizedBox(height: 16),
                            _buildInboxPanel(isStaff: isStaff),
                          ],
                        );
                      }

                      if (!isStaff) {
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(flex: 6, child: _buildSocialFeed()),
                                const SizedBox(width: 16),
                                Expanded(flex: 4, child: _buildPhotoGallery()),
                              ],
                            ),
                            const SizedBox(height: 16),
                            _buildQuestionPanel(isStaff: false),
                            const SizedBox(height: 16),
                            _buildInboxPanel(isStaff: false),
                          ],
                        );
                      }

                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(flex: 6, child: _buildSocialFeed()),
                              const SizedBox(width: 16),
                              Expanded(flex: 4, child: _buildPhotoGallery()),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                flex: 4,
                                child: _buildQuestionPanel(isStaff: isStaff),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                flex: 6,
                                child: _buildInboxPanel(isStaff: isStaff),
                              ),
                            ],
                          ),
                        ],
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSocialFeed() {
    return _SectionCard(
      title: AppTextsNews.socialFeedTitle,
      subtitle: AppTextsNews.socialFeedSubtitle,
      icon: Icons.rss_feed,
      child: Column(
        children: _posts
            .map(
              (post) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _PostCard(post: post),
              ),
            )
            .toList(),
      ),
    );
  }

  Widget _buildPhotoGallery() {
    return _SectionCard(
      title: AppTextsNews.photoGalleryTitle,
      subtitle: AppTextsNews.photoGallerySubtitle,
      icon: Icons.photo_library_outlined,
      child: Column(
        children: _photos
            .map(
              (photo) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _PhotoCard(photo: photo),
              ),
            )
            .toList(),
      ),
    );
  }

  Widget _buildQuestionPanel({required bool isStaff}) {
    return _SectionCard(
      title: AppTextsNews.questionTitle,
      subtitle: AppTextsNews.questionSubtitle,
      icon: Icons.mail_outline,
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextFormField(
              controller: _subjectController,
              decoration: const InputDecoration(
                labelText: AppTextsNews.subjectLabel,
                prefixIcon: Icon(Icons.subject),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return AppTextsNews.subjectRequired;
                }
                return null;
              },
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _messageController,
              minLines: 4,
              maxLines: 6,
              decoration: const InputDecoration(
                labelText: AppTextsNews.questionLabel,
                alignLabelWithHint: true,
                prefixIcon: Icon(Icons.chat_bubble_outline),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return AppTextsNews.questionRequired;
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: _isSubmitting ? null : _submitQuestion,
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.primary,
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              icon: _isSubmitting
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: AppColors.white,
                      ),
                    )
                  : const Icon(Icons.send),
              label: Text(
                _isSubmitting
                    ? AppTextsNews.sending
                    : AppTextsNews.sendToCityHall,
              ),
            ),
            const SizedBox(height: 14),
          ],
        ),
      ),
    );
  }

  Widget _buildInboxPanel({required bool isStaff}) {
    return _SectionCard(
      title: isStaff
          ? AppTextsNews.inboxTitleStaff
          : AppTextsNews.inboxTitleCitizen,
      subtitle: isStaff
          ? AppTextsNews.inboxSubtitleStaff
          : AppTextsNews.inboxSubtitleCitizen,
      icon: Icons.forum_outlined,
      child: FutureBuilder<List<NewsQuestion>>(
        future: _questionsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Padding(
              padding: EdgeInsets.symmetric(vertical: 32),
              child: Center(
                child: CircularProgressIndicator(color: AppColors.primary),
              ),
            );
          }

          if (snapshot.hasError) {
            return Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.errorBackground,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Text(
                snapshot.error.toString(),
                style: const TextStyle(color: AppColors.error),
              ),
            );
          }

          final questions = snapshot.data ?? const <NewsQuestion>[];
          if (isStaff) {
            return _buildStaffInboxContent(questions);
          }
          return _buildCitizenInboxContent(questions);
        },
      ),
    );
  }

  Widget _buildCitizenInboxContent(List<NewsQuestion> questions) {
    final selectedTab = _selectedCitizenTab ?? _CitizenInboxTab.pending;
    final pendingQuestions = questions
        .where((question) => !question.isAnswered)
        .toList();
    final historyQuestions = questions
        .where((question) => question.isAnswered)
        .toList();

    _citizenPendingPage = _normalizedPage(
      _citizenPendingPage ?? 1,
      pendingQuestions.length,
    );
    _citizenHistoryPage = _normalizedPage(
      _citizenHistoryPage ?? 1,
      historyQuestions.length,
    );

    final isPendingTab = selectedTab == _CitizenInboxTab.pending;
    final visibleQuestions = isPendingTab ? pendingQuestions : historyQuestions;
    final currentPage = isPendingTab
        ? (_citizenPendingPage ?? 1)
        : (_citizenHistoryPage ?? 1);
    final totalPages = _pageCountFor(visibleQuestions.length);
    final paginatedQuestions = _pageItems(visibleQuestions, currentPage);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [
            _buildStaffTabButton(
              label: '${AppTextsNews.pendingTab} (${pendingQuestions.length})',
              isSelected: isPendingTab,
              onTap: () {
                setState(() {
                  _selectedCitizenTab = _CitizenInboxTab.pending;
                });
              },
            ),
            _buildStaffTabButton(
              label: '${AppTextsNews.historyTab} (${historyQuestions.length})',
              isSelected: !isPendingTab,
              onTap: () {
                setState(() {
                  _selectedCitizenTab = _CitizenInboxTab.history;
                });
              },
            ),
          ],
        ),
        const SizedBox(height: 16),
        if (paginatedQuestions.isEmpty)
          _buildEmptyInboxMessage(
            isPendingTab
                ? AppTextsNews.emptyPendingInbox
                : AppTextsNews.emptyHistoryInbox,
          )
        else ...[
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: paginatedQuestions
                .map(
                  (question) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: _QuestionCard(
                      question: question,
                      isStaff: false,
                    ),
                  ),
                )
                .toList(),
          ),
          _buildStaffPagination(
            currentPage: currentPage,
            totalPages: totalPages,
            onPrevious: currentPage > 1
                ? () => setState(() {
                    if (isPendingTab) {
                      _citizenPendingPage = (_citizenPendingPage ?? 1) - 1;
                    } else {
                      _citizenHistoryPage = (_citizenHistoryPage ?? 1) - 1;
                    }
                  })
                : null,
            onNext: currentPage < totalPages
                ? () => setState(() {
                    if (isPendingTab) {
                      _citizenPendingPage = (_citizenPendingPage ?? 1) + 1;
                    } else {
                      _citizenHistoryPage = (_citizenHistoryPage ?? 1) + 1;
                    }
                  })
                : null,
          ),
        ],
      ],
    );
  }

  Widget _buildStaffInboxContent(List<NewsQuestion> questions) {
    final selectedTab = _selectedStaffTab ?? _StaffInboxTab.pending;
    final pendingQuestions = questions
        .where((question) => !question.isAnswered)
        .toList();
    final historyQuestions = questions
        .where((question) => question.isAnswered)
        .toList();

    _pendingPage = _normalizedPage(_pendingPage ?? 1, pendingQuestions.length);
    _historyPage = _normalizedPage(_historyPage ?? 1, historyQuestions.length);

    final isPendingTab = selectedTab == _StaffInboxTab.pending;
    final visibleQuestions = isPendingTab ? pendingQuestions : historyQuestions;
    final currentPage = isPendingTab ? (_pendingPage ?? 1) : (_historyPage ?? 1);
    final totalPages = _pageCountFor(visibleQuestions.length);
    final paginatedQuestions = _pageItems(visibleQuestions, currentPage);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [
            _buildStaffTabButton(
              label: '${AppTextsNews.pendingTab} (${pendingQuestions.length})',
              isSelected: isPendingTab,
              onTap: () {
                setState(() {
                  _selectedStaffTab = _StaffInboxTab.pending;
                });
              },
            ),
            _buildStaffTabButton(
              label: '${AppTextsNews.historyTab} (${historyQuestions.length})',
              isSelected: !isPendingTab,
              onTap: () {
                setState(() {
                  _selectedStaffTab = _StaffInboxTab.history;
                });
              },
            ),
          ],
        ),
        const SizedBox(height: 16),
        if (paginatedQuestions.isEmpty)
          _buildEmptyInboxMessage(
            isPendingTab
                ? AppTextsNews.emptyPendingInbox
                : AppTextsNews.emptyHistoryInbox,
          )
        else ...[
          ...paginatedQuestions.map(
            (question) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _QuestionCard(
                question: question,
                isStaff: true,
                onReply: question.isAnswered
                    ? null
                    : () => _openReplyDialog(question),
              ),
            ),
          ),
          _buildStaffPagination(
            currentPage: currentPage,
            totalPages: totalPages,
            onPrevious: currentPage > 1
                ? () => setState(() {
                    if (isPendingTab) {
                      _pendingPage = (_pendingPage ?? 1) - 1;
                    } else {
                      _historyPage = (_historyPage ?? 1) - 1;
                    }
                  })
                : null,
            onNext: currentPage < totalPages
                ? () => setState(() {
                    if (isPendingTab) {
                      _pendingPage = (_pendingPage ?? 1) + 1;
                    } else {
                      _historyPage = (_historyPage ?? 1) + 1;
                    }
                  })
                : null,
          ),
        ],
      ],
    );
  }

  Widget _buildStaffTabButton({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(999),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : AppColors.subtleSurface,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.cardBorder,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? AppColors.white : AppColors.primaryText,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyInboxMessage(String message) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.subtleSurface,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Text(
        message,
        style: const TextStyle(color: AppColors.secondaryText, height: 1.5),
      ),
    );
  }

  Widget _buildStaffPagination({
    required int currentPage,
    required int totalPages,
    required VoidCallback? onPrevious,
    required VoidCallback? onNext,
  }) {
    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Wrap(
        alignment: WrapAlignment.spaceBetween,
        runSpacing: 10,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          Text(
            '${AppTextsNews.pageLabel} $currentPage / $totalPages',
            style: const TextStyle(
              color: AppColors.secondaryText,
              fontWeight: FontWeight.w600,
            ),
          ),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            alignment: WrapAlignment.end,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              OutlinedButton.icon(
                onPressed: onPrevious,
                icon: const Icon(Icons.chevron_left),
                label: const Text(AppTextsNews.previousPage),
              ),
              OutlinedButton.icon(
                onPressed: onNext,
                icon: const Icon(Icons.chevron_right),
                label: const Text(AppTextsNews.nextPage),
              ),
            ],
          ),
        ],
      ),
    );
  }

  int _pageCountFor(int itemCount) {
    return itemCount == 0 ? 1 : (itemCount / _staffQuestionsPerPage).ceil();
  }

  int _normalizedPage(int currentPage, int itemCount) {
    final totalPages = _pageCountFor(itemCount);
    return math.max(1, math.min(currentPage, totalPages));
  }

  List<NewsQuestion> _pageItems(List<NewsQuestion> questions, int currentPage) {
    final start = (currentPage - 1) * _staffQuestionsPerPage;
    final end = math.min(start + _staffQuestionsPerPage, questions.length);
    if (start >= questions.length) {
      return const <NewsQuestion>[];
    }
    return questions.sublist(start, end);
  }

  Future<void> _submitQuestion() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      await _newsRepository.createQuestion(
        subject: _subjectController.text.trim(),
        message: _messageController.text.trim(),
      );
      _subjectController.clear();
      _messageController.clear();
      await _refreshQuestions();
      if (!mounted) return;
      CustomSnackBar.showSuccess(context, AppTextsNews.questionSentSuccess);
    } catch (error) {
      if (!mounted) return;
      CustomSnackBar.showError(context, error.toString());
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  Future<void> _refreshQuestions() async {
    final future = _newsRepository.listQuestions();
    setState(() {
      _questionsFuture = future;
      _pendingPage = 1;
      _historyPage = 1;
      _citizenPendingPage = 1;
      _citizenHistoryPage = 1;
    });
    await future;
  }

  Future<void> _openReplyDialog(NewsQuestion question) async {
    final controller = TextEditingController();
    final formKey = GlobalKey<FormState>();

    final response = await showDialog<String>(
      context: context,
      builder: (context) {
        var isSending = false;

        return StatefulBuilder(
          builder: (context, setModalState) {
            return AlertDialog(
              title: Text(
                '${AppTextsNews.replyDialogTitlePrefix} "${question.citizen.displayName}"',
              ),
              content: Form(
                key: formKey,
                child: TextFormField(
                  controller: controller,
                  minLines: 4,
                  maxLines: 7,
                  decoration: const InputDecoration(
                    labelText: AppTextsNews.replyLabel,
                    alignLabelWithHint: true,
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return AppTextsNews.replyRequired;
                    }
                    return null;
                  },
                ),
              ),
              actions: [
                TextButton(
                  onPressed: isSending
                      ? null
                      : () => Navigator.of(context).pop(),
                  child: const Text(AppTextsNews.cancel),
                ),
                FilledButton(
                  onPressed: isSending
                      ? null
                      : () async {
                          if (!formKey.currentState!.validate()) {
                            return;
                          }
                          setModalState(() {
                            isSending = true;
                          });
                          Navigator.of(context).pop(controller.text.trim());
                        },
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.primary,
                  ),
                  child: const Text(AppTextsNews.send),
                ),
              ],
            );
          },
        );
      },
    );

    if (response == null || response.isEmpty) {
      return;
    }

    try {
      await _newsRepository.replyToQuestion(
        questionId: question.id,
        response: response,
      );
      await _refreshQuestions();
      if (!mounted) return;
      CustomSnackBar.showSuccess(context, AppTextsNews.replySentSuccess);
    } catch (error) {
      if (!mounted) return;
      CustomSnackBar.showError(context, error.toString());
    }
  }
}

enum _StaffInboxTab { pending, history }

enum _CitizenInboxTab { pending, history }

class _SectionCard extends StatelessWidget {
  const _SectionCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.child,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: const [
          BoxShadow(
            color: AppColors.overlay,
            blurRadius: 22,
            offset: Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: AppColors.highlight,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(icon, color: AppColors.primary),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: AppColors.primaryText,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        color: AppColors.secondaryText,
                        height: 1.45,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          child,
        ],
      ),
    );
  }
}

class _PostCard extends StatelessWidget {
  const _PostCard({required this.post});

  final _SocialPost post;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.subtleSurface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: post.accent.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(post.icon, color: post.accent),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Text(
                      post.network,
                      style: TextStyle(
                        color: post.accent,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.white,
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        post.timeLabel,
                        style: const TextStyle(fontSize: 12),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  post.title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: AppColors.primaryText,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  post.excerpt,
                  style: const TextStyle(
                    color: AppColors.secondaryText,
                    height: 1.45,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PhotoCard extends StatelessWidget {
  const _PhotoCard({required this.photo});

  final _CityPhoto photo;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: Stack(
        children: [
          AspectRatio(
            aspectRatio: 16 / 9,
            child: Image.asset(photo.assetPath, fit: BoxFit.cover),
          ),
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    photo.overlay,
                    AppColors.overlay,
                    AppColors.primaryText,
                  ],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
            ),
          ),
          Positioned(
            left: 16,
            right: 16,
            bottom: 16,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  photo.title,
                  style: const TextStyle(
                    color: AppColors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  photo.subtitle,
                  style: const TextStyle(color: AppColors.white, height: 1.35),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _QuestionCard extends StatelessWidget {
  const _QuestionCard({
    required this.question,
    required this.isStaff,
    this.onReply,
  });

  final NewsQuestion question;
  final bool isStaff;
  final VoidCallback? onReply;

  @override
  Widget build(BuildContext context) {
    final formatter = DateFormat('dd/MM/yyyy HH:mm');

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.subtleSurface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: question.isAnswered
              ? AppColors.cardBorder
              : AppColors.secondary,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 10,
            runSpacing: 10,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Text(
                question.subject,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
              _StatusBadge(isAnswered: question.isAnswered),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            '${AppTextsNews.sentOnPrefix} ${formatter.format(question.createdAt.toLocal())} ${AppTextsNews.byPrefix} ${question.citizen.displayName}',
            style: const TextStyle(
              color: AppColors.secondaryText,
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 12),
          Text(question.message, style: const TextStyle(height: 1.45)),
          if (question.isAnswered) ...[
            const SizedBox(height: 14),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.responseBackground,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${AppTextsNews.cityHallReply}${question.answeredBy != null ? ' - ${question.answeredBy!.displayName}' : ''}',
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      color: AppColors.primary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(question.response, style: const TextStyle(height: 1.45)),
                  if (question.answeredAt != null) ...[
                    const SizedBox(height: 8),
                    Text(
                      '${AppTextsNews.sentAtPrefix} ${formatter.format(question.answeredAt!.toLocal())}',
                      style: const TextStyle(
                        color: AppColors.secondaryText,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ] else if (isStaff && onReply != null) ...[
            const SizedBox(height: 14),
            Align(
              alignment: Alignment.centerLeft,
              child: OutlinedButton.icon(
                onPressed: onReply,
                icon: const Icon(Icons.reply),
                label: const Text(AppTextsNews.replyButton),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.isAnswered});

  final bool isAnswered;

  @override
  Widget build(BuildContext context) {
    final color = isAnswered ? AppColors.success : AppColors.secondary;
    final background = isAnswered
        ? AppColors.successBackground
        : AppColors.warningBackground;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        isAnswered ? AppTextsNews.answered : AppTextsNews.pending,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.w700,
          fontSize: 12,
        ),
      ),
    );
  }
}

class _SocialPost {
  const _SocialPost({
    required this.network,
    required this.title,
    required this.excerpt,
    required this.timeLabel,
    required this.accent,
    required this.icon,
  });

  final String network;
  final String title;
  final String excerpt;
  final String timeLabel;
  final Color accent;
  final IconData icon;
}

class _CityPhoto {
  const _CityPhoto({
    required this.title,
    required this.subtitle,
    required this.assetPath,
    required this.overlay,
  });

  final String title;
  final String subtitle;
  final String assetPath;
  final Color overlay;
}
