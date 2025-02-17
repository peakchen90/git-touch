import 'package:fimber/fimber.dart';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:git_touch/models/notification.dart';
import 'package:git_touch/models/theme.dart';
import '../utils/utils.dart';
import '../screens/issue.dart';
import 'package:git_touch/models/auth.dart';
import 'package:provider/provider.dart';
import 'link.dart';

class NotificationItem extends StatefulWidget {
  final NotificationPayload payload;
  final Function markAsRead;

  NotificationItem({
    Key key,
    @required this.payload,
    @required this.markAsRead,
  }) : super(key: key);

  @override
  _NotificationItemState createState() => _NotificationItemState();
}

class _NotificationItemState extends State<NotificationItem> {
  NotificationPayload get payload => widget.payload;
  bool loading = false;

  Widget _buildIcon(IconData data, [Color color = Colors.black54]) {
    return Icon(data, color: color, size: 20);
  }

  Widget _buildIconData() {
    switch (payload.type) {
      case 'Issue':
        switch (payload.state) {
          case 'OPEN':
            return _buildIcon(Octicons.issue_opened, GithubPalette.open);
          case 'CLOSED':
            return _buildIcon(Octicons.issue_closed, GithubPalette.closed);
          default:
            return _buildIcon(Octicons.person);
        }
        break;
      case 'PullRequest':
        switch (payload.state) {
          case 'OPEN':
            return _buildIcon(Octicons.git_pull_request, GithubPalette.open);
          case 'CLOSED':
            return _buildIcon(Octicons.git_pull_request, GithubPalette.closed);
          case 'MERGED':
            return _buildIcon(Octicons.git_merge, GithubPalette.merged);
          default:
            return _buildIcon(Octicons.person);
        }
        break;
      // color: Color.fromRGBO(0x6f, 0x42, 0xc1, 1),
      case 'Release':
        return _buildIcon(Octicons.tag);
      case 'Commit':
        return _buildIcon(Octicons.git_commit);
      default:
        Fimber.d('Unhandled notification type: ${payload.type}');
        return _buildIcon(Octicons.octoface);
    }
  }

  Widget _buildCheckIcon() {
    return Icon(
      payload.unread ? Octicons.check : Octicons.primitive_dot,
      color: loading ? Colors.black12 : Colors.black45,
      size: 24,
    );
  }

  void _markAsRead() async {
    if (payload.unread && !loading) {
      setState(() {
        loading = true;
      });
      try {
        await Provider.of<AuthModel>(context)
            .patchWithCredentials('/notifications/threads/' + payload.id);
        widget.markAsRead();
      } finally {
        if (mounted) {
          setState(() {
            loading = false;
          });
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Link(
      onTap: () {
        _markAsRead();

        switch (payload.type) {
          case 'Issue':
          case 'PullRequest':
            final resource = payload.type == 'PullRequest' ? 'pulls' : 'issues';
            Provider.of<ThemeModel>(context).push(context,
                '/${payload.owner}/${payload.name}/$resource/${payload.number}');
            break;
          case 'Release':
            launchUrl(
                'https://github.com/${payload.owner}/${payload.name}/releases/tag/${payload.title}');
            break;
          case 'Commit':
            // TODO:
            // onTap = () {
            // launch('urlString');
            // };
            break;
        }
      },
      child: Opacity(
        opacity: payload.unread ? 1 : 0.5,
        child: Container(
          padding: EdgeInsets.all(8),
          child: Row(
            children: <Widget>[
              Container(
                padding: EdgeInsets.only(right: 8),
                child: _buildIconData(),
              ),
              Expanded(
                child: Text(
                  payload.title,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 15),
                ),
              ),
              Link(child: _buildCheckIcon(), onTap: _markAsRead),
            ],
          ),
        ),
      ),
    );
  }
}
