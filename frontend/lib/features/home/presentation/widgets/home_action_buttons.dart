import 'package:flutter/material.dart';
import 'package:frontend/constants/colors.dart';
import 'package:frontend/constants/texts/texts_home.dart';

class HomeActionButtons extends StatelessWidget {
  const HomeActionButtons({super.key});

  @override
  Widget build(BuildContext context) {
    final primaryButtonStyle = ElevatedButton.styleFrom(
      backgroundColor: AppColors.primary,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    );

    final secondaryButtonStyle = ElevatedButton.styleFrom(
      backgroundColor: Colors.white,
      elevation: 1,
      shadowColor: Colors.black12,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ).copyWith(
      overlayColor: MaterialStateProperty.resolveWith<Color?>(
            (Set<MaterialState> states) {
          if (states.contains(MaterialState.pressed)) {
            return AppColors.primary.withOpacity(0.12);
          }
          return null;
        },
      ),
    );

    return Row(
      children: [
        ElevatedButton.icon(
          onPressed: () {},
          icon: const Icon(Icons.add, color: Colors.white),
          label: const Text(AppTextsHome.newPoll, style: TextStyle(color: Colors.white)),
          style: primaryButtonStyle,
        ),
        const SizedBox(width: 16),
        ElevatedButton.icon(
          onPressed: () {},
          icon: const Icon(Icons.add, color: AppColors.primary),
          label: const Text(AppTextsHome.newReport, style: TextStyle(color: AppColors.textDark, fontWeight: FontWeight.bold)),
          style: secondaryButtonStyle,
        ),
        const SizedBox(width: 16),
        ElevatedButton.icon(
          onPressed: () {},
          icon: const Icon(Icons.add, color: AppColors.primary),
          label: const Text(AppTextsHome.addEvent, style: TextStyle(color: AppColors.textDark, fontWeight: FontWeight.bold)),
          style: secondaryButtonStyle,
        ),
      ],
    );
  }
}