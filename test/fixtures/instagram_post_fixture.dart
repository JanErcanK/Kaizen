import 'dart:convert';

// Minimal synthetic version of the public embed structure observed for the
// user's nine-image post; no third-party images, cookies or signed URLs.
const instagramPostId = 'De3BL_pCByI';
const instagramPostUrl =
    'https://www.instagram.com/p/$instagramPostId/?img_index=6';

String instagramPostPage({String id = instagramPostId}) =>
    '<meta property="og:url" content="https://www.instagram.com/p/$id/">';

String instagramEmbed({
  String id = instagramPostId,
  bool blocked = false,
  int count = 9,
  int? videoSlide,
  bool includeVideoUrl = true,
}) =>
    '<script>${jsonEncode({
      'contextJSON': jsonEncode({
        'context': {'shortcode': id, 'copyright_blocked': blocked},
        'gql_data': {
          'shortcode_media': {
            '__typename': 'GraphSidecar',
            'shortcode': id,
            'is_video': false,
            'display_url': 'https://s.cdninstagram.com/cover.jpg',
            'edge_sidecar_to_children': {
              'edges': [
                for (var i = 1; i <= count; i++) {
                    'node': {'shortcode': 'slide_$i', 'is_video': i == videoSlide, 'display_url': 'https://s.cdninstagram.com/slide_$i.jpg', if (i == videoSlide && includeVideoUrl) 'video_url': 'https://s.cdninstagram.com/slide_$i.mp4'},
                  },
              ],
            },
          },
        },
      }),
    })}</script>';
