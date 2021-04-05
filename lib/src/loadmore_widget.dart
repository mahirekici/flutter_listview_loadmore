import 'dart:async';

import 'package:flutter/material.dart';

import 'gesture_dedector.dart';

/// return true is refresh success
///
/// return false or null is fail
typedef Future<bool> FutureCallBack();

class LoadMore extends StatefulWidget {
  static DelegateBuilder<LoadMoreDelegate> buildDelegate =
      () => DefaultLoadMoreDelegate();
  static DelegateBuilder<LoadMoreTextBuilder> buildTextBuilder =
      () => DefaultLoadMoreTextBuilder.chinese;

  /// Only support [ListView],[SliverList]
  final Widget child;

  /// return true is refresh success
  ///
  /// return false or null is fail
  final FutureCallBack onLoadMore;

  /// if [isFinish] is true, then loadMoreWidget status is [LoadMoreStatus.nomore].
  final bool isFinish;

  /// see [LoadMoreDelegate]
  final LoadMoreDelegate delegate;

  /// see [LoadMoreTextBuilder]
  final LoadMoreTextBuilder textBuilder;

  /// when [whenEmptyLoad] is true, and when listView children length is 0,or the itemCount is 0,not build loadMoreWidget
  final bool whenEmptyLoad;

  const LoadMore({
    Key key,
    this.child,
    this.onLoadMore,
    this.textBuilder,
    this.isFinish = false,
    this.delegate,
    this.whenEmptyLoad = true,
  }) : super(key: key);

  @override
  _LoadMoreState createState() => _LoadMoreState();
}

class _LoadMoreState extends State<LoadMore> {
  Widget get child => widget.child;

  LoadMoreDelegate get loadMoreDelegate =>
      widget.delegate ?? LoadMore.buildDelegate();

  var _controller = ScrollController();

  LoadMoreStatus status = LoadMoreStatus.idle;

  var pressing = false;
  Timer timer;

  @override
  void initState() {
    super.initState();

    startTimer();
  }

  @override
  void dispose() {
    timer.cancel();
    timer = null;
    super.dispose();
  }

  startTimer() {
    timer = Timer.periodic(const Duration(milliseconds: 40), (timer) {
      var newIndex = 0.0;
      if (pressing) {
        newIndex = _controller.offset;
        timer.cancel();
      } else {
        newIndex = _controller.offset + 10;
      }
      _controller.animateTo(newIndex,
          curve: Curves.easeIn, duration: Duration(milliseconds: 100));
    });
  }

  stopTimer() {
    timer.cancel();
    timer = null;
    pressing = false;
  }

  resumeStarter() {
    stopTimer();
    startTimer();
  }

  startResumeCallBack(bool click) {
    setState(() {
      pressing = click;
    });
  }

  onResumeCallBack() {
    setState(() {
      pressing = true;
    });
    resumeStarter();
  }

  @override
  Widget build(BuildContext context) {
    return _buildListView(child as ListView);
  }

  /// if call the method, then the future is not null
  /// so, return a listview and  item count + 1
  Widget _buildListView(ListView listView) {
    SliverChildBuilderDelegate delegate =
        listView.childrenDelegate as SliverChildBuilderDelegate;

    var viewCount = delegate.estimatedChildCount ?? 0 + 1;

    IndexedWidgetBuilder builder = (context, index) {
      if (index == viewCount - 1) {
        return _buildLoadMoreView();
        // yeni item ekler misal 4
        //main'den load fonksiyonunu tetikler
      }
      return delegate.builder(context, index);
    };

    return CustomGestureDedector(
      clickCallBack: startResumeCallBack,
      onResumeCallBack: onResumeCallBack,
      child: NotificationListener(
        onNotification: (notificationInfo) {
          if (notificationInfo is ScrollEndNotification) {
            if (pressing == true) {
              Future.delayed(Duration(milliseconds: 4000))
                  .then((value) => resumeStarter());
            }

            debugPrint("ScrollEndNotification $pressing");
          }
          return true;
        },
        child: ListView.builder(
          itemBuilder: builder,
          addAutomaticKeepAlives: delegate.addAutomaticKeepAlives,
          addRepaintBoundaries: delegate.addRepaintBoundaries,
          addSemanticIndexes: delegate.addSemanticIndexes,
          dragStartBehavior: listView.dragStartBehavior,
          semanticChildCount: listView.semanticChildCount,
          itemCount: viewCount,
          cacheExtent: listView.cacheExtent,
          controller: _controller,
          itemExtent: listView.itemExtent,
          key: listView.key,
          padding: listView.padding,
          physics: listView.physics,
          primary: listView.primary,
          reverse: listView.reverse,
          scrollDirection: listView.scrollDirection,
          shrinkWrap: listView.shrinkWrap,
        ),
      ),
    );
  }

  Widget _buildLoadMoreView() {
    if (widget.isFinish == true) {
      this.status = LoadMoreStatus.nomore;
    } else {
      if (this.status == LoadMoreStatus.nomore) {
        this.status = LoadMoreStatus.idle;
      }
    }
    return NotificationListener<_RetryNotify>(
      child: NotificationListener<_BuildNotify>(
        child: DefaultLoadMoreView(
          status: status,
          delegate: loadMoreDelegate,
          textBuilder: widget.textBuilder ?? LoadMore.buildTextBuilder(),
        ),
        onNotification: _onLoadMoreBuild,
      ),
      onNotification: _onRetry,
    );
  }

  bool _onLoadMoreBuild(_BuildNotify notification) {
    //判断状态，触发对应的操作
    if (status == LoadMoreStatus.loading) {
      return false;
    }
    if (status == LoadMoreStatus.nomore) {
      return false;
    }
    if (status == LoadMoreStatus.fail) {
      return false;
    }
    if (status == LoadMoreStatus.idle) {
      // 切换状态为加载中，并且触发回调
      loadMore();
    }
    return false;
  }

  void _updateStatus(LoadMoreStatus status) {
    if (mounted) setState(() => this.status = status);
  }

  bool _onRetry(_RetryNotify notification) {
    loadMore();
    return false;
  }

  void loadMore() {
    _updateStatus(LoadMoreStatus.loading);
    widget.onLoadMore().then((v) {
      if (v == true) {
        // 成功，切换状态为空闲
        _updateStatus(LoadMoreStatus.idle);
      } else {
        // 失败，切换状态为失败
        _updateStatus(LoadMoreStatus.fail);
      }
    });
  }
}

enum LoadMoreStatus {
  /// 空闲中，表示当前等待加载
  ///
  /// wait for loading
  idle,

  /// 刷新中，不应该继续加载，等待future返回
  ///
  /// the view is loading
  loading,

  /// 刷新失败，刷新失败，这时需要点击才能刷新
  ///
  /// loading fail, need tap view to loading
  fail,

  /// 没有更多，没有更多数据了，这个状态不触发任何条件
  ///
  /// not have more data
  nomore,
}

class DefaultLoadMoreView extends StatefulWidget {
  final LoadMoreStatus status;
  final LoadMoreDelegate delegate;
  final LoadMoreTextBuilder textBuilder;
  const DefaultLoadMoreView({
    Key key,
    this.status = LoadMoreStatus.idle,
    this.delegate,
    this.textBuilder,
  }) : super(key: key);

  @override
  DefaultLoadMoreViewState createState() => DefaultLoadMoreViewState();
}

const _defaultLoadMoreHeight = 80.0;
const _loadmoreIndicatorSize = 33.0;
const _loadMoreDelay = 16;

class DefaultLoadMoreViewState extends State<DefaultLoadMoreView> {
  LoadMoreDelegate get delegate => widget.delegate;

  @override
  Widget build(BuildContext context) {
    notify();

    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onTap: () {
        if (widget.status == LoadMoreStatus.fail ||
            widget.status == LoadMoreStatus.idle) {
          _RetryNotify().dispatch(context);
        }
      },
      child: Container(
        height: delegate.widgetHeight(widget.status),
        alignment: Alignment.center,
        child: delegate.buildChild(
          widget.status,
          builder: widget.textBuilder,
        ),
      ),
    );
  }

  void notify() async {
    var delay = max(delegate.loadMoreDelay(), Duration(milliseconds: 16));
    await Future.delayed(delay);
    if (widget.status == LoadMoreStatus.idle) {
      _BuildNotify().dispatch(context);
    }
  }

  Duration max(Duration duration, Duration duration2) {
    if (duration > duration2) {
      return duration;
    }
    return duration2;
  }
}

class _BuildNotify extends Notification {}

class _RetryNotify extends Notification {}

typedef T DelegateBuilder<T>();

/// loadmore widget properties
abstract class LoadMoreDelegate {
  static DelegateBuilder<LoadMoreDelegate> buildWidget =
      () => DefaultLoadMoreDelegate();

  const LoadMoreDelegate();

  /// the loadmore widget height
  double widgetHeight(LoadMoreStatus status) => _defaultLoadMoreHeight;

  /// build loadmore delay
  Duration loadMoreDelay() => Duration(milliseconds: _loadMoreDelay);

  Widget buildChild(LoadMoreStatus status,
      {LoadMoreTextBuilder builder = DefaultLoadMoreTextBuilder.chinese});
}

class DefaultLoadMoreDelegate extends LoadMoreDelegate {
  const DefaultLoadMoreDelegate();

  @override
  Widget buildChild(LoadMoreStatus status,
      {LoadMoreTextBuilder builder = DefaultLoadMoreTextBuilder.chinese}) {
    String text = builder(status);
    if (status == LoadMoreStatus.fail) {
      return Container(
        child: Text(text),
      );
    }
    if (status == LoadMoreStatus.idle) {
      return Text(text);
    }
    if (status == LoadMoreStatus.loading) {
      return Container(
        alignment: Alignment.center,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            SizedBox(
              width: _loadmoreIndicatorSize,
              height: _loadmoreIndicatorSize,
              child: CircularProgressIndicator(
                backgroundColor: Colors.blue,
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Text(text),
            ),
          ],
        ),
      );
    }
    if (status == LoadMoreStatus.nomore) {
      return Text(text);
    }

    return Text(text);
  }
}

typedef String LoadMoreTextBuilder(LoadMoreStatus status);

String _buildChineseText(LoadMoreStatus status) {
  String text;
  switch (status) {
    case LoadMoreStatus.fail:
      text = "加载失败，请点击重试";
      break;
    case LoadMoreStatus.idle:
      text = "等待加载更多";
      break;
    case LoadMoreStatus.loading:
      text = "加载中，请稍候...";
      break;
    case LoadMoreStatus.nomore:
      text = "到底了，别扯了";
      break;
    default:
      text = "";
  }
  return text;
}

String _buildEnglishText(LoadMoreStatus status) {
  String text;
  switch (status) {
    case LoadMoreStatus.fail:
      text = "load fail, tap to retry";
      break;
    case LoadMoreStatus.idle:
      text = "wait for loading";
      break;
    case LoadMoreStatus.loading:
      text = "loading, wait for moment ...";
      break;
    case LoadMoreStatus.nomore:
      text = "no more data";
      break;
    default:
      text = "";
  }
  return text;
}

class DefaultLoadMoreTextBuilder {
  static const LoadMoreTextBuilder chinese = _buildChineseText;

  static const LoadMoreTextBuilder english = _buildEnglishText;
}
