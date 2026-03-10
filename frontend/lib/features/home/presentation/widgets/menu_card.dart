import 'package:flutter/material.dart';
import 'package:frontend/constants/texts/texts_home.dart';
import 'package:frontend/ui/assets.dart';
import 'package:go_router/go_router.dart';
import 'package:frontend/config/app_routes.dart';
import 'package:frontend/constants/colors.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.page,
      body: Column(
        children: [
          Expanded(
            child: Stack(
              children: [
                // Optional: Background with faded city image
                Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  height: 300,
                  child: Opacity(
                    opacity: 0.15,
                    child: Image.asset(
                      AppAssets.home_background,
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
                // Main content
                SingleChildScrollView(
                  padding: const EdgeInsets.all(32.0),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // --- LEFT COLUMN (Main Content) ---
                      Expanded(
                        flex: 7,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildGreeting(),
                            const SizedBox(height: 24),
                            _buildTopStatsRow(),
                            const SizedBox(height: 24),
                            _buildActionButtons(),
                            const SizedBox(height: 32),
                            _buildCardsGrid(context),
                            const SizedBox(height: 24),
                            _buildBottomStatsBar(),
                          ],
                        ),
                      ),
                      const SizedBox(width: 32),
                      // --- RIGHT COLUMN (Sidebar) ---
                      Expanded(
                        flex: 3,
                        child: Column(
                          children: [
                            _buildRecentActivityPanel(),
                            const SizedBox(height: 24),
                            _buildUsefulInfoPanel(),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================
  // 2. LEFT COLUMN CONTENT
  // ==========================================
  Widget _buildGreeting() {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(AppTextsHome.homeTitle, style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: AppColors.textDark)),
          ],
        ),
        SizedBox(height: 8),
        Text(AppTextsHome.homeSubtitle, style: TextStyle(fontSize: 24, color: AppColors.textGrey)),
      ],
    );
  }

  Widget _buildTopStatsRow() {
    return Row(
      children: [
        _statPill(Icons.circle, Colors.redAccent, '12', AppTextsHome.pendingReports),
        const SizedBox(width: 16),
        _statPill(Icons.circle, AppColors.primary, '3', AppTextsHome.activePolls),
        const SizedBox(width: 16),
        _statPill(Icons.calendar_today, Colors.orangeAccent, '5', AppTextsHome.eventsThisWeek),
      ],
    );
  }

  Widget _statPill(IconData icon, Color color, String number, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.9),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 4, offset: const Offset(0, 2))],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 14),
          const SizedBox(width: 8),
          Text(number, style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 18)),
          const SizedBox(width: 8),
          Text(text, style: const TextStyle(fontWeight: FontWeight.w600, color: AppColors.textDark)),
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    return Row(
      children: [
        ElevatedButton.icon(
          onPressed: () {},
          icon: const Icon(Icons.add, color: Colors.white),
          label: const Text(AppTextsHome.newPoll, style: TextStyle(color: Colors.white)),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
        const SizedBox(width: 16),
        ElevatedButton.icon(
          onPressed: () {},
          icon: const Icon(Icons.add, color: AppColors.primary),
          label: const Text(AppTextsHome.newReport, style: TextStyle(color: AppColors.textDark, fontWeight: FontWeight.bold)),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.white,
            elevation: 1,
            shadowColor: Colors.black12,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
        const SizedBox(width: 16),
        ElevatedButton.icon(
          onPressed: () {},
          icon: const Icon(Icons.add, color: AppColors.primary),
          label: const Text(AppTextsHome.addEvent, style: TextStyle(color: AppColors.textDark, fontWeight: FontWeight.bold)),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.white,
            elevation: 1,
            shadowColor: Colors.black12,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
      ],
    );
  }

  Widget _buildCardsGrid(BuildContext context) {
    return Column(
      children: [
        // Row 1: Large Cards
        SizedBox(
          height: 240,
          child: Row(
            children: [
              Expanded(
                child: MenuCard(
                  icon: Icons.warning_amber_rounded,
                  title: AppTextsHome.reportsTitle,
                  subtitle: AppTextsHome.reportsSubtitle,
                  onTap: () => context.go(AppRoutes.reports),
                ),
              ),
              const SizedBox(width: 24),
              Expanded(
                child: MenuCard(
                  icon: Icons.bar_chart,
                  title: AppTextsHome.pollsTitle,
                  subtitle: AppTextsHome.pollsSubtitle,
                  onTap: () => context.go(AppRoutes.surveys),
                ),
              ),
              const SizedBox(width: 24),
              Expanded(
                child: MenuCard(
                  icon: Icons.calendar_month,
                  title: AppTextsHome.agendaTitle,
                  subtitle: AppTextsHome.agendaSubtitle,
                  onTap: () => context.go(AppRoutes.agenda),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        // Row 2: Small Cards
        SizedBox(
          height: 110,
          child: Row(
            children: [
              Expanded(
                child: MenuCard(
                  style: MenuCardStyle.compact,
                  icon: Icons.article_outlined,
                  title: AppTextsHome.newsTitle,
                  subtitle: AppTextsHome.newsSubtitle,
                  onTap: () => context.go(AppRoutes.news),
                ),
              ),
              const SizedBox(width: 24),
              Expanded(
                child: MenuCard(
                  style: MenuCardStyle.compact,
                  icon: Icons.info_outline,
                  title: AppTextsHome.infoTitle,
                  subtitle: AppTextsHome.infoSubtitle,
                  onTap: () => context.go(AppRoutes.usefulInfo),
                ),
              ),
              const SizedBox(width: 24),
              const Expanded(child: SizedBox()), // Empty for layout
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildBottomStatsBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              const Icon(Icons.people, color: AppColors.primary),
              const SizedBox(width: 12),
              RichText(
                text: const TextSpan(
                  style: TextStyle(color: AppColors.textDark, fontSize: 16),
                  children: [
                    TextSpan(text: AppTextsHome.platformUsagePrefix),
                    TextSpan(text: '1250', style: TextStyle(fontWeight: FontWeight.bold)),
                    TextSpan(text: AppTextsHome.platformUsageSuffix),
                  ],
                ),
              ),
            ],
          ),
          Row(
            children: [
              Icon(Icons.warning_amber, color: Colors.red.shade400, size: 20),
              const SizedBox(width: 8),
              RichText(
                text: const TextSpan(
                  style: TextStyle(color: AppColors.textDark, fontSize: 15),
                  children: [
                    TextSpan(text: '48', style: TextStyle(fontWeight: FontWeight.bold)),
                    TextSpan(text: AppTextsHome.reportsMonthSuffix),
                  ],
                ),
              ),
            ],
          ),
          const Row(
            children: [
              Icon(Icons.pie_chart, color: AppColors.primary, size: 20),
              SizedBox(width: 8),
              Text('${AppTextsHome.pollParticipationPrefix}62 %', style: TextStyle(color: AppColors.textDark, fontSize: 15)),
            ],
          ),
        ],
      ),
    );
  }

  // ==========================================
  // 3. RIGHT COLUMN CONTENT (Sidebar)
  // ==========================================
  Widget _buildRecentActivityPanel() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Row(
                  children: [
                    Icon(Icons.bar_chart, color: AppColors.primary),
                    SizedBox(width: 8),
                    Text(AppTextsHome.recentActivityTitle, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textDark)),
                  ],
                ),
                TextButton(
                  onPressed: () {},
                  child: const Text(AppTextsHome.seeAll, style: TextStyle(color: AppColors.textGrey)),
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: Color(0xFFF0F0F0)),
          _activityItem(Icons.warning, Colors.redAccent, AppTextsHome.newReportActivity, 'Rue Victor Hugo', '20 min'),
          const Divider(height: 1, color: Color(0xFFF0F0F0)),
          _activityItem(Icons.poll, AppColors.primary, AppTextsHome.newVoteActivity, 'Sondage transports', '1 heure'),
          const Divider(height: 1, color: Color(0xFFF0F0F0)),
          _activityItem(Icons.calendar_month, Colors.orangeAccent, AppTextsHome.eventAddedActivity, 'Festival local', '2 heures'),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  Widget _activityItem(IconData icon, Color color, String title, String subtitle, String time) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.textDark, fontSize: 14)),
                const SizedBox(height: 2),
                Text(subtitle, style: const TextStyle(color: AppColors.textGrey, fontSize: 13)),
              ],
            ),
          ),
          Text(time, style: const TextStyle(color: AppColors.textGrey, fontSize: 12)),
        ],
      ),
    );
  }

  Widget _buildUsefulInfoPanel() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.all(20),
            child: Row(
              children: [
                Icon(Icons.info_outline, color: AppColors.primary),
                SizedBox(width: 8),
                Text(AppTextsHome.usefulInfoTitle, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textDark)),
              ],
            ),
          ),
          // Fake map with markers (Placeholder)
          Container(
            height: 160,
            width: double.infinity,
            margin: const EdgeInsets.symmetric(horizontal: 20),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              image: const DecorationImage(
                image: NetworkImage('https://i.stack.imgur.com/HILmr.png'), // Replace with real Map or image
                fit: BoxFit.cover,
              ),
            ),
          ),
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              children: [
                _mapStatItem(Icons.warning_amber, Colors.orange, AppTextsHome.roadDamage, '3'),
                const SizedBox(height: 12),
                _mapStatItem(Icons.delete_outline, Colors.red, AppTextsHome.overflowingBins, '9'),
                const SizedBox(height: 12),
                _mapStatItem(Icons.lightbulb_outline, AppColors.primary, AppTextsHome.faultyLighting, '6'),
                const SizedBox(height: 20),
              ],
            ),
          )
        ],
      ),
    );
  }

  Widget _mapStatItem(IconData icon, Color color, String label, String count) {
    return Row(
      children: [
        Icon(icon, color: color, size: 18),
        const SizedBox(width: 12),
        Expanded(child: Text(label, style: const TextStyle(color: AppColors.textDark))),
        Text(count, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.textDark)),
      ],
    );
  }
}

// ==========================================
// 4. CARDS WIDGET (MenuCard)
// ==========================================
enum MenuCardStyle { large, compact }

class MenuCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final MenuCardStyle style;

  const MenuCard({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.style = MenuCardStyle.large,
  });

  @override
  Widget build(BuildContext context) {
    // Custom asymmetric border radius
    const borderRadius = BorderRadius.only(
      topLeft: Radius.circular(50),
      topRight: Radius.circular(15),
      bottomRight: Radius.circular(50),
      bottomLeft: Radius.circular(30),
    );

    return Container(
      decoration: BoxDecoration(
        color: AppColors.primary, // Base color is now green for the whole card
        borderRadius: borderRadius,
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      child: ClipRRect(
        borderRadius: borderRadius,
        child: Stack(
          children: <Widget>[
            style == MenuCardStyle.large ? _buildLargeCard() : _buildCompactCard(),
            Positioned.fill(
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  splashColor: Colors.white.withOpacity(0.2), // Softer ripple
                  highlightColor: Colors.white.withOpacity(0.1),
                  onTap: onTap,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLargeCard() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(
          flex: 6,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: AppColors.secondary, size: 48),
              const SizedBox(height: 16),
              Text(
                title,
                style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ),
        Expanded(
          flex: 4,
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2), // Transparent white to show green behind
            ),
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Center(
              child: Text(
                subtitle,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.white, fontSize: 14), // Text white for contrast
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCompactCard() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      child: Row(
        children: [
          Icon(icon, color: AppColors.secondary, size: 40),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  title,
                  style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 6),
                Text(
                  subtitle,
                  style: const TextStyle(color: Colors.white70, fontSize: 13),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}