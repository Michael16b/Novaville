import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

class SocialNetworkActions extends StatelessWidget {
  final String? instagram;
  final String? facebook;
  final String? x;

  const SocialNetworkActions({
    super.key,
    this.instagram,
    this.facebook,
    this.x,
  });

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if ((instagram ?? "").isNotEmpty)
          Row(
            children: [
              const FaIcon(FontAwesomeIcons.instagram, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Instagram : $instagram',
                  style: textTheme.bodyMedium,
                ),
              ),
            ],
          ),

        if ((facebook ?? "").isNotEmpty) ...[
          const SizedBox(height: 8),
          Row(
            children: [
              const FaIcon(FontAwesomeIcons.facebook, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Facebook : $facebook',
                  style: textTheme.bodyMedium,
                ),
              ),
            ],
          ),
        ],

        if ((x ?? "").isNotEmpty) ...[
          const SizedBox(height: 8),
          Row(
            children: [
              const FaIcon(FontAwesomeIcons.xTwitter, size: 20),
              const SizedBox(width: 8),
              Expanded(child: Text('X : $x', style: textTheme.bodyMedium)),
            ],
          ),
        ],
      ],
    );
  }
}
